// backend/src/area/area.module.ts

import { Module } from '@nestjs/common';
import { AreaService } from './area.service';
import { AreaController } from './area.controller';
import { PrismaService } from '../prisma.service'; 

@Module({
  controllers: [AreaController],
  // Aggiungiamo PrismaService tra i providers per poterlo iniettare nel Service
  providers: [AreaService, PrismaService], 
})

export class AreaModule {}