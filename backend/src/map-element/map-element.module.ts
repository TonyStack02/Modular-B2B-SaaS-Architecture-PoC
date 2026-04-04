// backend/src/map-element/map-element.module.ts

import { Module } from '@nestjs/common';
import { MapElementService } from './map-element.service';
import { MapElementController } from './map-element.controller';

// 1. IMPORTIAMO IL SINGOLO SERVIZIO DI PRISMA (controlla che il percorso sia giusto!)
import { PrismaService } from '../prisma.service'; 

@Module({
  // Non ci serve l'array 'imports' se non abbiamo un PrismaModule

  controllers: [MapElementController],
  
  // 2. AGGIUNGIAMO PRISMASERVICE AI PROVIDERS!
  // Inserendolo qui, stiamo dicendo a NestJS: 
  // "Ehi, quando il MapElementService ti chiede il database, usa questo PrismaService!"
  providers: [MapElementService, PrismaService], 
})
export class MapElementModule {}