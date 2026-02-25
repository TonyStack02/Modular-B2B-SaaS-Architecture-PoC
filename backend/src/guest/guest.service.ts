// backend/src/guest/guest.service.ts

import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
//import dei DTO
import { CreateBookingDto } from './dto/create-booking.dto';
import { CreateOrderDto } from './dto/create-order.dto';

@Injectable()
export class GuestService {
  constructor(private prisma: PrismaService) {}

  // 1. Dammi tutte le informazioni del Ristorante (Menu incluso)
  async getRestaurantMenu(tenantId: string) {
    const tenant = await this.prisma.tenant.findUnique({
      where: { id: tenantId },
      include: {
        categories: {
          include: {
            products: true, // Includi i prodotti dentro le categorie
          },
        },
      },
    });

    if (!tenant) throw new NotFoundException('Ristorante non trovato');
    return tenant;
  }

  // 2. Dammi la lista dei Tavoli/Ombrelloni
  async getRestaurantResources(tenantId: string) {
    return this.prisma.area.findMany({
      where: { tenantId: tenantId },
      include: {
        resources: true, // Includi i tavoli dentro le aree
      },
    });
  }

  //3. Funzione per creare una prenotazione
  async createBooking(dto : CreateBookingDto){
    // Usiamo prisma per creare un nuovo record nella tabella 'booking'
    return this.prisma.booking.create({
      data: {
        dateTime: new Date(dto.dateTime), // Convertiamo la stringa in un oggetto Date di JS
        guests: dto.guests,
        tenantId: dto.tenantId,
        resourceId: dto.resourceId, // Può essere null se non specificato (opzionale nello schema)
        // Nota: Nel tuo schema User è opzionale per i Booking, quindi per ora non lo colleghiamo
      },
    });
  }


  //4. Funzione complessa per creare un ordine
  async createOrder(dto : CreateOrderDto){
    //Passaggio da Pro: Recuperiamo i prezzi aggiornati dei prodotti dal DB.
    // Non vogliamo che un utente cattivo ci mandi un ordine con prezzo 0!
    const productIds = dto.items.map(item => item.productId);
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds } }
    });

  // Creiamo l'ordine e gli elementi dell'ordine (OrderItem) in un'unica operazione (Transazione)
    return this.prisma.order.create({
      data: {
        tenantId: dto.tenantId,
        resourceId: dto.resourceId,
        status: 'OPEN', // L'ordine nasce aperto
        items: {
          // 'create' dentro 'items' dice a Prisma di creare automaticamente i record nella tabella OrderItem
          create: dto.items.map(item => {
            // Cerchiamo il prezzo originale nel database per il prodotto corrente
            const product = products.find(p => p.id === item.productId);
            if (!product) throw new NotFoundException(`Prodotto ${item.productId} non trovato`);

            return {
              productId: item.productId,
              quantity: item.quantity,
              unitPrice: product.price, // Salviamo il prezzo storico come previsto dallo schema
            };
          }),
        },
      },
      // Chiediamo a Prisma di restituirci l'ordine includendo anche i dettagli appena creati
      include: { items: true }
    });
  }
}