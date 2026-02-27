// backend/src/area/area.service.ts

import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service'; 
import { CreateAreaDto } from './dto/create-area.dto';

@Injectable()
export class AreaService {
    // Iniettiamo Prisma nel costruttore per poterlo usare in tutta la classe
    constructor (private prisma: PrismaService) {}

    // Metodo per creare una nuova area (es. "Terrazza")
    async createArea(dto: CreateAreaDto, tenantId: string) {
        return this.prisma.area.create({
            data: {
                name: dto.name,
                // Colleghiamo l'area al ristorante corrente usando il tenantId
                // preso dal badge JWT
                tenantId: tenantId,
            }
        });
    }

    // Metodo per recuperare tutte le aree di UN SOLO ristorante
    async findAll (tenantId: string){
        return this.prisma.area.findMany({
            where: {
                tenantId: tenantId,
            },
        });
    }


}