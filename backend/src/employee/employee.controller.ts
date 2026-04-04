// backend/src/employee/employee.controller.ts

import { Controller, Get, Post, Body, Patch, Param, Delete, UseGuards, Request } from '@nestjs/common';
import { EmployeeService } from './employee.service';
import { CreateEmployeeDto } from './dto/create-employee.dto';
import { UpdateEmployeeDto } from './dto/update-employee.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // La nostra guardia
// Se hai anche i ruoli (es. RolesGuard), importali e usali! 

@Controller('employee')
@UseGuards(JwtAuthGuard) // Blindiamo tutto
export class EmployeeController {
  constructor(private readonly employeeService: EmployeeService) {}

  @Post()
  create(@Body() createEmployeeDto: CreateEmployeeDto, @Request() req) {
    // Passiamo i dati e l'ID del locale di chi fa la richiesta
    return this.employeeService.create(createEmployeeDto, req.user.tenantId);
  }

  @Get()
  findAll(@Request() req) {
    return this.employeeService.findAll(req.user.tenantId);
  }

  @Get(':id')
  findOne(@Param('id') id: string, @Request() req) {
    return this.employeeService.findOne(id, req.user.tenantId);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() updateEmployeeDto: UpdateEmployeeDto, @Request() req) {
    return this.employeeService.update(id, updateEmployeeDto, req.user.tenantId);
  }

  @Delete(':id')
  remove(@Param('id') id: string, @Request() req) {
    return this.employeeService.remove(id, req.user.tenantId);
  }
}