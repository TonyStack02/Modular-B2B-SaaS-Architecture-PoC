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
  async createOrder(dto: CreateOrderDto) {
    // Recuperiamo i prezzi aggiornati dei prodotti dal DB.
    const productIds = dto.items.map(item => item.productId);
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds } }
    });

    let calculatedTotal = 0;

    // Prepariamo la lista dei prodotti e calcoliamo il totale strada facendo
    const orderItemsData = dto.items.map(item => {
      const product = products.find(p => p.id === item.productId);
      if (!product) throw new NotFoundException(`Prodotto ${item.productId} non trovato`);

      // Aggiungiamo al totale: (prezzo della pizza * quantità)
      calculatedTotal += Number(product.price) * item.quantity;

      return {
        productId: item.productId,
        quantity: item.quantity,
        unitPrice: product.price, 
      };
    });

    // Creiamo l'ordine passando finalmente il TOTALE calcolato!
    const order = await this.prisma.order.create({
      data: {
        tenantId: dto.tenantId,
        resourceId: dto.resourceId,
        customerId: dto.customerId,
        status: 'OPEN',
        totalAmount: calculatedTotal, // <--- 💸 ECCO I SOLDI VERI!
        items: {
          create: orderItemsData, // Usiamo la lista che abbiamo preparato sopra
        },
      },
      include: { items: true }
    });

    // MAGIA: Inviamo la notifica in tempo reale all'Owner!
    this.orderGateway.sendNewOrderNotification(order.tenantId, order);
    
    return order;
  }
}