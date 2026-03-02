// backend/src/dashboard/dashboard.module.ts

import { Module } from '@nestjs/common';
import { DashboardService } from './dashboard.service';
import { DashboardController } from './dashboard.controller';
import { OrderModule } from '../order/order.module'; // Importiamo l'isola degli ordini

@Module({
  imports: [OrderModule], // 🚨 Cabliamo i due moduli insieme!
  controllers: [DashboardController],
  providers: [DashboardService],
})
export class DashboardModule {}