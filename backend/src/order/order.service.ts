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

  // 2. Aggiorna lo stato di un ordine (es: Mario segna come "Servito" o "Pagato")
  async updateStatus(id: string, dto: UpdateOrderStatusDto, tenantId: string) {
    // 1. Troviamo l'ordine e INCLUDIAMO LE PIZZE E BIRRE (items)
    const order = await this.prisma.order.findFirst({
      where: { id: id, tenantId: tenantId },
      include: { items: true } // <-- FONDAMENTALE PER CONTARE I SOLDI!
    });

    if (!order) {
      throw new NotFoundException('Ordine non trovato o non appartenente al tuo ristorante');
    }

    // Partiamo dal totale che c'è già
    let finalTotal: number = Number(order.totalAmount);

    // 2. MAGIA: Se il cameriere lo sta segnando come PAGATO, chiudiamo il conto!
    if (dto.status === 'PAID') {
      // Facciamo la somma matematica sicura di tutto quello che ha mangiato
      finalTotal = order.items.reduce((somma, item) => {
        return somma + (Number(item.unitPrice) * item.quantity);
      }, 0);
      
      console.log(`🧾 Chiusura conto per ordine ${id} - Totale calcolato: €${finalTotal}`);
    }

    // 3. Salviamo nel database il nuovo stato E l'incasso definitivo
    return this.prisma.order.update({
      where: { id: id },
      data: { 
        status: dto.status,
        totalAmount: finalTotal // <-- I SOLDI VENGONO STAMPATI QUI!
      }
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
      _sum: { totalAmount: true },
      where: {
        tenantId: tenantId,
        status: 'PAID',
        createdAt: { gte: startOfToday, lte: endOfToday }
      }
    });

    // 🚨 RADAR: Stampiamo cosa esce davvero dal database!
    console.log("💰 INCASSO GREZZO DA PRISMA:", result._sum.totalAmount);

    // Forziamo brutalmente l'oggetto Prisma a diventare un numero normale JavaScript
    return result._sum.totalAmount ? Number(result._sum.totalAmount) : 0;
  }

  async markAsPaid(orderId: string) {
    console.log(`🛠️ Aggiorno ordine ${orderId} come PAGATO nel database...`);

    return this.prisma.order.update({
      where: {id: orderId},
      data: {status: 'PAID'}
    });
  }

}