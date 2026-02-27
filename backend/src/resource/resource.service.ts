// backend/src/resource/resource.service.ts

import { Injectable, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma.service'; // Per parlare con il DB
import { CreateResourceDto } from './dto/create-resource.dto';

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
}