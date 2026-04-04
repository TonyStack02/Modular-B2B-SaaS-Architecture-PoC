// backend/src/customer/customer.service.ts

import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { CreateCustomerDto } from './dto/create-customer.dto';

@Injectable()
export class CustomerService {
  constructor(private prisma: PrismaService) {}

  // 1. Crea un nuovo cliente in rubrica
  async create(dto: CreateCustomerDto, tenantId: string) {
    return await this.prisma.customer.create({
      data: {
        ...dto,
        tenantId: tenantId,
      },
    });
  }

  // 2. SCARICA TUTTI I CLIENTI CON STATISTICHE INCLUSE! 🚀
  async findAll(tenantId: string) {
    const customers = await this.prisma.customer.findMany({
      where: { tenantId: tenantId },
      include: {
        // Chiediamo a Prisma di contare in automatico ordini e prenotazioni
        _count: {
          select: { bookings: true, orders: true }
        },
        // Ci portiamo dietro i totali di tutti gli scontrini per sommarli
        orders: {
          select: { totalAmount: true }
        }
      },
      orderBy: { createdAt: 'desc' } // I più recenti in alto
    });

    // Mappiamo i dati grezzi in una lista pulita per Flutter
    return customers.map(customer => {
      // 💸 La Magia: Sommiamo il totale speso in tutti gli scontrini di questo cliente
      const totalSpent = customer.orders.reduce((sum, order) => {
        return sum + Number(order.totalAmount || 0);
      }, 0);

      // Ritorniamo un oggetto perfetto per la nostra App
      return {
        id: customer.id,
        firstName: customer.firstName,
        lastName: customer.lastName,
        phone: customer.phone,
        email: customer.email,
        notes: customer.notes,
        totalBookings: customer._count.bookings, // Quante volte ha prenotato
        totalOrders: customer._count.orders,     // Quanti ordini ha fatto
        totalSpent: totalSpent,                  // Quanti soldi ci ha portato in totale!
      };
    });
  }

  // 3. Elimina un cliente dalla rubrica
  async remove(id: string, tenantId: string) {
    return await this.prisma.customer.delete({
      where: { id: id, tenantId: tenantId },
    });
  }
}