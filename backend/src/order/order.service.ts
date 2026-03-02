// backend/src/order/order.service.ts

import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { SrvRecord } from 'dns';

@Injectable()
export class OrderService {
  constructor(private prisma: PrismaService) {}

  // 1. Recupera tutti gli ordini del ristorante (Tenant)
  async findAll(tenantId: string) {
    return this.prisma.order.findMany({
      where: { tenantId: tenantId },
      include: {
        resource: true, // Vediamo a che tavolo sono
        items: {
          include: { product: true } // Vediamo cosa hanno ordinato (pizza, birra, ecc.)
        }
      },
      orderBy: { createdAt: 'desc' } // I più recenti in alto
    });
  }

  // 2. Aggiorna lo stato di un ordine (es: Mario segna come "Servito")
  async updateStatus(id: string, dto: UpdateOrderStatusDto, tenantId: string) {
    // Verifichiamo prima che l'ordine esista e appartenga al ristorante corretto
    const order = await this.prisma.order.findFirst({
      where: { id: id, tenantId: tenantId }
    });

    if (!order) {
      throw new NotFoundException('Ordine non trovato o non appartenente al tuo ristorante');
    }

    return this.prisma.order.update({
      where: { id: id },
      data: { status: dto.status }
    });
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
      _sum: { totalAmount: true }, // Sostituisci totalAmount se nel tuo DB si chiama diversamente!
      where: {
        tenantId: tenantId,
        status: 'PAID',
        createdAt: { gte: startOfToday, lte: endOfToday }
      }
    });

    return result._sum.totalAmount || 0;
  }

  async markAsPaid(orderId: string) {
    console.log(`🛠️ Aggiorno ordine ${orderId} come PAGATO nel database...`);

    return this.prisma.order.update({
      where: {id: orderId},
      data: {status: 'PAID'}
    });
  }

}