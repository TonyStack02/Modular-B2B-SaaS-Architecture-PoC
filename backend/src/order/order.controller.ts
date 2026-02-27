// backend/src/order/order.controller.ts

import { Controller, Get, Patch, Param, Body, UseGuards, Request } from '@nestjs/common';
import { OrderService } from './order.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';

@Controller('order')
@UseGuards(JwtAuthGuard) // Protezione totale: serve il token!
export class OrderController {
  constructor(private readonly orderService: OrderService) {}

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