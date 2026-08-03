// backend/src/checklist/checklist.module.ts

import { Module } from '@nestjs/common';
import { ChecklistService } from './checklist.service';
import { ChecklistController } from './checklist.controller';
import { ChecklistGateway } from './checklist.gateway';
import { PrismaService } from '../prisma.service';

@Module({
  imports: [], // Importiamo PrismaModule per poter usare il database nel service
  controllers: [ChecklistController],
  providers: [ChecklistService, ChecklistGateway, PrismaService],
})
export class ChecklistModule {}