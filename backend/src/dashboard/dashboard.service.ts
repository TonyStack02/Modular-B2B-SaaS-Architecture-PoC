// backend/src/dashboard/dashboard.service.ts

import { Injectable } from '@nestjs/common';
import { OrderService } from '../order/order.service';

@Injectable()
export class DashboardService {
  // Iniettiamo i manager dei vari reparti (per ora solo OrderService)
  constructor(private readonly orderService: OrderService) {}

  async getHomeStats(tenantId: string) {
    // 🔥 PRO TIP: Usiamo Promise.all per lanciare le due query CONTEMPORANEAMENTE.
    // Invece di aspettare che finisca una per iniziare l'altra, le spariamo insieme. Tempo dimezzato!
    const [activeOrders, todayIncome] = await Promise.all([
      this.orderService.countActiveOrders(tenantId),
      this.orderService.getTodayIncome(tenantId),
    ]);

    // Impacchettiamo e spediamo al Frontend!
    return {
      activeOrders,
      todayIncome,
    };
  }
}