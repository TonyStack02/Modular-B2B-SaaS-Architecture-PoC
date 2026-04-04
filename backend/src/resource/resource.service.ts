// backend/src/resource/resource.service.ts

import { Injectable, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma.service'; // Per parlare con il DB
import { CreateResourceDto } from './dto/create-resource.dto';
import { UpdateResourceDto } from './dto/update-resource.dto';

@Injectable()
export class ResourceService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateResourceDto, tenantId: string) {
    // 1. Controllo di sicurezza: l'Area selezionata appartiene a questo ristorante?
    const area = await this.prisma.area.findUnique({
      where: { id: dto.areaId },
    });

    if (!area || area.tenantId !== tenantId) {
      throw new ForbiddenException('Non puoi aggiungere risorse a un area che non ti appartiene');
    }

    // 2. Creazione della risorsa (Tavolo/Ombrellone)
    return this.prisma.resource.create({
      data: {
        name: dto.name,
        areaId: dto.areaId,
        tenantId: tenantId, // Colleghiamo sempre al ristorante per sicurezza
      },
    });
  }

  // Recupera tutti i tavoli del ristorante, divisi per area
  async findAll(tenantId: string) {
    return this.prisma.resource.findMany({
      where: { tenantId: tenantId },
      include: {
        area: true, // Vediamo anche il nome dell'area di appartenenza
      },
    });
  }

  // 📍 SALVA LE NUOVE COORDINATE NEL DATABASE
  async update(id: string, dto: UpdateResourceDto) {
    return await this.prisma.resource.update({
      // 1. Trova il tavolo con questo ID esatto
      where: { id: id },
      // 2. Aggiorna i dati con quelli arrivati da Flutter
      data: {
        // Se nel DTO c'è la positionX, aggiornala. Altrimenti ignora.
        ...(dto.positionX !== undefined && { positionX: dto.positionX }),
        ...(dto.positionY !== undefined && { positionY: dto.positionY }),
        ...(dto.name !== undefined && { name: dto.name }),
      },
    });
  }
}