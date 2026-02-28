// backend/src/guest/guest.module.ts

import { Module } from '@nestjs/common';
import { GuestService } from './guest.service';
import { GuestController } from './guest.controller';
import { OrderModule } from '../order/order.module';
import { PrismaService } from '../prisma.service';

@Module({
  imports: [OrderModule], //Per usare il Gateway degli ordini
  controllers: [GuestController],
  providers: [
    GuestService, 
    PrismaService 
  ], 
})
export class GuestModule {}