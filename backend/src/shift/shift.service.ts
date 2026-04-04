// backend/src/shift/shift.service.ts

import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { CreateShiftDto } from './dto/create-shift.dto';

@Injectable()
export class ShiftService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateShiftDto, tenantId: string) {
    return await this.prisma.shift.create({
      data: {
        ...dto,
        tenantId: tenantId,
      },
      // 🧙‍♂️ MAGIA AGGIUNTA: Chiediamo a Prisma di restituirci i dati del dipendente!
      include: {
        employee: {
          select: {
            firstName: true,
            lastName: true,
            hourlyWage: true,
            jobRole: true,
          }
        }
      }
    });
  }

  // Prendi tutti i turni di un periodo (es. di questa settimana)
  async findAll(tenantId: string, start?: string, end?: string) {
    return await this.prisma.shift.findMany({
      where: {
        tenantId: tenantId,
        // Se passiamo delle date, filtriamo i turni (utile per il calendario)
        ...(start && end ? {
          startTime: { gte: new Date(start) },
          endTime: { lte: new Date(end) },
        } : {}),
      },
      // 🧙‍♂️ MAGIA: Includiamo i dati del dipendente per avere lo stipendio orario!
      include: {
        employee: {
          select: {
            firstName: true,
            lastName: true,
            hourlyWage: true,
            jobRole: true,
          }
        }
      },
      orderBy: { startTime: 'asc' },
    });
  }

  async remove(id: string, tenantId: string) {
    return await this.prisma.shift.delete({
      where: { id: id, tenantId: tenantId },
    });
  }
}