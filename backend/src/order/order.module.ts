// backend/src/order/order.module.ts

import { Module } from '@nestjs/common';
import { OrderService } from './order.service';
import { OrderController } from './order.controller';
import { PrismaService } from '../prisma.service'; // Necessario per le query al database

@Module({
  // Il controller gestisce le rotte API (la "bocca")
  controllers: [OrderController],
  // I providers sono i servizi che contengono la logica (il "cervello")
  // Inseriamo anche PrismaService perché OrderService lo usa nel costruttore
  providers: [OrderService, PrismaService],
})
export class OrderModule {}