// backend/src/stripe/stripe.module.ts

import { Module } from '@nestjs/common';
import { StripeService } from './stripe.service';
import { StripeController } from './stripe.controller';
import { OrderModule } from 'src/order/order.module';
import { OrderService } from 'src/order/order.service';
import { PrismaService } from 'src/prisma.service';

@Module({
  imports: [OrderModule],
  providers: [StripeService,  OrderService, PrismaService],
  // Esportiamo lo StripeService così altri moduli (come Order) possono usarlo
  exports: [StripeService],
  controllers: [StripeController],
})
export class StripeModule {}
