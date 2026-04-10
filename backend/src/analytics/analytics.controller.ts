// backend/src/analytics/analytics.controller.ts

import { Controller, Get, Query, BadRequestException } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';

@Controller('analytics')
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  // Rotta: GET /analytics/dashboard?tenantId=...&startDate=...&endDate=...
  @Get('dashboard')
  async getDashboard(
    @Query('tenantId') tenantId: string,
    @Query('startDate') startDate: string,
    @Query('endDate') endDate: string,
  ) {
    if (!tenantId || !startDate || !endDate) {
      throw new BadRequestException('Mancano tenantId, startDate o endDate nei parametri della richiesta');
    }

    return this.analyticsService.getDashboardStats(tenantId, startDate, endDate);
  }
}