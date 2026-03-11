// backend/src/order/order.controller.ts

import { Controller, Get, Patch, Param, Body, UseGuards, Request } from '@nestjs/common';
import { OrderService } from './order.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';

@Controller('order')
@UseGuards(JwtAuthGuard) // Protezione totale: serve il token!
export class OrderController {
  constructor(private readonly orderService: OrderService) {}

  // 📊 LA PORTA PER LA DASHBOARD FLUTTER
  @Get('stats')
  async getDashboardStats(@Request() req) {
    const tenantId = req.user.tenantId;
    
    // Chiamiamo i due metodi del service in parallelo per non perdere tempo
    const [income, activeOrders] = await Promise.all([
      this.orderService.getTodayIncome(tenantId),
      this.orderService.countActiveOrders(tenantId)
    ]);

    // Restituiamo ESATTAMENTE la forma JSON che il tuo DashboardStatsModel in Flutter si aspetta
    return {
      todayIncome: income,
      activeOrders: activeOrders
    };
  }

  // Mario vede la lista ordini: GET /order
  @Get()
  findAll(@Request() req) {
    return this.orderService.findAll(req.user.tenantId);
  }

  // Mario cambia stato: PATCH /order/:id/status
  @Patch(':id/status')
  updateStatus(
    @Param('id') id: string,
    @Body() dto: UpdateOrderStatusDto,
    @Request() req
  ) {
    return this.orderService.updateStatus(id, dto, req.user.tenantId);
  }
}