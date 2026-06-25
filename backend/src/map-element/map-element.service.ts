// backend/src/map-element/map-element.service.ts

import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service'; 
import { CreateMapElementDto } from './dto/create-map-element.dto';
import { UpdateMapElementDto } from './dto/update-map-element.dto';


@Injectable()
export class MapElementService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateMapElementDto, tenantId: string) {
    return await this.prisma.mapElement.create({
      data: {
        ...dto,
        tenantId: tenantId,
      },
    });
  }

  async findAll(tenantId: string) {
    return await this.prisma.mapElement.findMany({
      where: { tenantId: tenantId },
    });
  }

  async update(id: string, dto: UpdateMapElementDto) {
    return await this.prisma.mapElement.update({
      where: { id: id },
      data: dto,
    });
  }

  // 💥 Elimina definitivamente un elemento dal database
  async remove(id: string) {
    return await this.prisma.mapElement.delete({
      where: { id: id },
    });
  }
}