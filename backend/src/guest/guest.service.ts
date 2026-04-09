// backend/src/guest/guest.service.ts

import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { OrderGateway } from 'src/order/order.gateway';
import { CreateBookingDto } from './dto/create-booking.dto';
import { CreateOrderDto } from './dto/create-order.dto';

@Injectable()
export class GuestService {
  constructor(private prisma: PrismaService, private orderGateway: OrderGateway) {}

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
    return this.prisma.booking.create({
      data: {
        dateTime: new Date(dto.dateTime), 
        guests: dto.guests,
        tenantId: dto.tenantId,
        resourceId: dto.resourceId, 
      },
    });
  }

  //4. Funzione complessa per creare un ordine
  async createOrder(dto: CreateOrderDto) {
    // 1. Estraiamo solo gli ID dei prodotti per fare una singola chiamata al database veloce
    const productIds = dto.items.map(item => item.productId);
    
    // 2. Chiediamo al database i prezzi veri (così nessuno può manometterli da Flutter)
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds } }
    });

    let calculatedTotal = 0;

    // 3. Prepariamo i dati esatti come li vuole Prisma per la tabella OrderItem
    const orderItemsData = dto.items.map(item => {
      // Troviamo il prodotto corrispondente nel database
      const product = products.find(p => p.id === item.productId);
      if (!product) throw new NotFoundException(`Prodotto ${item.productId} non trovato`);

      // Calcoliamo quanti soldi aggiungere al totale
      calculatedTotal += Number(product.price) * item.quantity;

      // 📝 Creiamo la riga per lo scontrino
      return {
        productId: item.productId,
        quantity: item.quantity,
        unitPrice: product.price, // Salviamo il prezzo "storico" al momento dell'ordine
        notes: item.notes, // <--- MAGIA: Trasferiamo le note da Flutter direttamente al Database!
      };
    });

    // 4. Creiamo l'ordine finale nel database con tutti i pezzi uniti
    const order = await this.prisma.order.create({
      data: {
        tenantId: dto.tenantId,
        resourceId: dto.resourceId,
        customerId: dto.customerId,
        status: 'OPEN',
        totalAmount: calculatedTotal, // Il totale che abbiamo appena calcolato
        items: {
          create: orderItemsData, // Passiamo la lista di oggetti creata al passaggio 3
        },
      },
      include: { items: true } // Diciamo a Prisma di restituirci anche gli items appena creati
    });

    // 5. Il megafono: svegliamo la cassa in tempo reale per far diventare rosso il tavolo
    this.orderGateway.sendNewOrderNotification(order.tenantId, order);
    
    return order;
  }
}