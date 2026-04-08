// backend/src/order/order.service.ts

import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
// 📡 1. IMPORTIAMO L'ANTENNA (Assicurati che il percorso e il nome del file siano giusti)
import { OrderGateway } from './order.gateway'; 

@Injectable()
export class OrderService {
  // 📡 2. INIETTIAMO IL GATEWAY NEL COSTRUTTORE
  constructor(
    private prisma: PrismaService, 
    private orderGateway: OrderGateway 
  ) {}

  // 1. Recupera tutti gli ordini del ristorante (Tenant)
  async findAll(tenantId: string) {
    return this.prisma.order.findMany({
      where: { tenantId: tenantId },
      include: {
        resource: true, 
        items: {
          include: { product: true } 
        }
      },
      orderBy: { createdAt: 'desc' } 
    });
  }

  // 2. Aggiorna lo stato di un ordine
  async updateStatus(id: string, dto: UpdateOrderStatusDto, tenantId: string) {
    const order = await this.prisma.order.findFirst({
      where: { id: id, tenantId: tenantId },
      include: { items: true } 
    });

    if (!order) {
      throw new NotFoundException('Ordine non trovato o non appartenente al tuo ristorante');
    }

    let finalTotal: number = Number(order.totalAmount);
    let finalCustomerId: string | null = order.customerId;

    // MAGIA: Calcoliamo il totale e associamo il cliente se ce lo passano
    if (dto.status === 'PAID') {
      finalTotal = order.items.reduce((somma, item) => {
        return somma + (Number(item.unitPrice) * item.quantity);
      }, 0);
      
      if (dto.customerId) {
         finalCustomerId = dto.customerId;
         console.log(`💎 Associato cliente VIP ${dto.customerId} all'ordine ${id}`);
      }
    }

    // 3. Salviamo l'ordine aggiornato
    const updatedOrder = await this.prisma.order.update({
      where: { id: id },
      data: { 
        status: dto.status,
        totalAmount: finalTotal,
        customerId: finalCustomerId 
      }
    });

    // 4. AGGIORNAMENTO CRM
    if (dto.status === 'PAID' && finalCustomerId) {
      await this.prisma.customer.update({
        where: { id: finalCustomerId },
        data: {
          totalOrders: { increment: 1 }, 
          totalSpent: { increment: finalTotal } 
        }
      });
      console.log(`📈 Statistiche aggiornate per il cliente ${finalCustomerId}! +€${finalTotal}`);
    }

    // 📣 5. IL MEGAFONO: Urliamo a tutto il ristorante che l'ordine è cambiato!
    // Usiamo il tenantId come "Stanza" (Room) così i tablet della Pizzeria A non vedono gli ordini della Pizzeria B.
    this.orderGateway.sendOrderUpdate(tenantId, updatedOrder);

    return updatedOrder;
  }

  // Calcola quanti ordini sono ancora aperti oggi
  async countActiveOrders(tenantId: string) {
    return this.prisma.order.count({
      where: {
        tenantId: tenantId,
        status: { notIn: ['PAID', 'CANCELLED'] } 
      }
    });
  }

  // Calcola l'incasso di oggi
  async getTodayIncome(tenantId: string) {
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);
    const endOfToday = new Date();
    endOfToday.setHours(23, 59, 59, 999);

    const result = await this.prisma.order.aggregate({
      _sum: { totalAmount: true },
      where: {
        tenantId: tenantId,
        status: 'PAID',
        createdAt: { gte: startOfToday, lte: endOfToday }
      }
    });

    return result._sum.totalAmount ? Number(result._sum.totalAmount) : 0;
  }

  // Vecchio metodo per chiusura rapida
  async markAsPaid(orderId: string) {
    console.log(`🛠️ Aggiorno ordine ${orderId} come PAGATO nel database...`);

    const updatedOrder = await this.prisma.order.update({
      where: {id: orderId},
      data: {status: 'PAID'}
    });

    // 📣 MEGAFONO ANCHE QUI per sicurezza, nel caso lo usassi ancora
    this.orderGateway.sendOrderUpdate(updatedOrder.tenantId, updatedOrder);

    return updatedOrder;
  }
}