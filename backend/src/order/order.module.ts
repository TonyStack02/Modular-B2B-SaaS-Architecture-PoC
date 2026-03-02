// backend/src/order/order.module.ts

import { Module } from '@nestjs/common';
import { OrderService } from './order.service';
import { OrderController } from './order.controller';
import { OrderGateway } from './order.gateway';
import { PrismaService } from '../prisma.service'; 

@Module({
  controllers: [OrderController],
  providers: [OrderService, PrismaService, OrderGateway],
  exports: [OrderGateway, OrderService], // Lo esportiamo per poterlo usare in altri moduli (es. Guest)
})
export class OrderModule {}