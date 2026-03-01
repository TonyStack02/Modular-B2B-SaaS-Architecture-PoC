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

  async markAsPaid(orderId: string) {
    console.log(`🛠️ Aggiorno ordine ${orderId} come PAGATO nel database...`);

    return this.prisma.order.update({
      where: {id: orderId},
      data: {status: 'PAID'}
    });
  }

}