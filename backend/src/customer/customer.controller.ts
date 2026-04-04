// backend/src/customer/customer.controller.ts

import { Controller, Get, Post, Body, Param, Delete, UseGuards, Request } from '@nestjs/common';
import { CustomerService } from './customer.service';
import { CreateCustomerDto } from './dto/create-customer.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // 🛡️ Importante!

@Controller('customer')
@UseGuards(JwtAuthGuard) // Blindiamo tutta la rotta
export class CustomerController {
  constructor(private readonly customerService: CustomerService) {}

  @Post()
  create(@Body() createCustomerDto: CreateCustomerDto, @Request() req) {
    return this.customerService.create(createCustomerDto, req.user.tenantId);
  }

  @Get()
  findAll(@Request() req) {
    // Passiamo l'ID del locale per prendere solo i SUOI clienti
    return this.customerService.findAll(req.user.tenantId);
  }

  @Delete(':id')
  remove(@Param('id') id: string, @Request() req) {
    return this.customerService.remove(id, req.user.tenantId);
  }
}