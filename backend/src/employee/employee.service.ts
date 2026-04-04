// backend/src/employee/employee.service.ts

import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service'; 
import { CreateEmployeeDto } from './dto/create-employee.dto';
import { UpdateEmployeeDto } from './dto/update-employee.dto';

@Injectable()
export class EmployeeService {
  constructor(private prisma: PrismaService) {}

  // Crea un nuovo dipendente
  async create(dto: CreateEmployeeDto, tenantId: string) {
    return await this.prisma.employee.create({
      data: {
        ...dto,
        tenantId: tenantId,
      },
    });
  }

  // Trova tutti i dipendenti di questo specifico ristorante
  async findAll(tenantId: string) {
    return await this.prisma.employee.findMany({
      where: { tenantId: tenantId },
      orderBy: { firstName: 'asc' }, // Li ordiniamo in ordine alfabetico per comodità
    });
  }

  // Dettaglio di un singolo dipendente
  async findOne(id: string, tenantId: string) {
    return await this.prisma.employee.findFirst({
      where: { id: id, tenantId: tenantId },
    });
  }

  // Aggiorna la scheda (es. cambio stipendio o rinnovo contratto)
  async update(id: string, dto: UpdateEmployeeDto, tenantId: string) {
    return await this.prisma.employee.update({
      // Usiamo tenantId anche qui per sicurezza, così nessuno può modificare dipendenti di altri locali
      where: { id: id, tenantId: tenantId },
      data: dto,
    });
  }

  // Licenzia/Elimina (In futuro potremmo solo cambiare lo stato in TERMINATED invece di eliminarlo, ma per ora facciamo delete)
  async remove(id: string, tenantId: string) {
    return await this.prisma.employee.delete({
      where: { id: id, tenantId: tenantId },
    });
  }
}