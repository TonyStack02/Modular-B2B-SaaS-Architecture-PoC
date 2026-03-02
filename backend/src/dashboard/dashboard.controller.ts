// backend/src/dashboard/dashboard.controller.ts

import { Controller, Get, UseGuards, Request } from '@nestjs/common';
import { DashboardService } from './dashboard.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('dashboard')
@UseGuards(JwtAuthGuard)
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  @Get('stats')
  getHomeStats(@Request() req) {
    return this.dashboardService.getHomeStats(req.user.tenantId);
  }
}