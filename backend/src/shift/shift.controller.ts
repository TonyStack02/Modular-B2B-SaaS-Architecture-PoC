// backend/src/shift/shift.controller.ts

import { Controller, Get, Post, Body, Param, Delete, UseGuards, Request, Query } from '@nestjs/common';
import { ShiftService } from './shift.service';
import { CreateShiftDto } from './dto/create-shift.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('shift')
@UseGuards(JwtAuthGuard)
export class ShiftController {
  constructor(private readonly shiftService: ShiftService) {}

  @Post()
  create(@Body() createShiftDto: CreateShiftDto, @Request() req) {
    return this.shiftService.create(createShiftDto, req.user.tenantId);
  }

  @Get()
  findAll(
    @Request() req, 
    @Query('start') start?: string, 
    @Query('end') end?: string
  ) {
    return this.shiftService.findAll(req.user.tenantId, start, end);
  }

  @Delete(':id')
  remove(@Param('id') id: string, @Request() req) {
    return this.shiftService.remove(id, req.user.tenantId);
  }
}