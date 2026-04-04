// backend/src/resource/resource.controller.ts

import { Controller, Get, Post, Body, UseGuards, Request, Patch, Param } from '@nestjs/common';
import { ResourceService } from './resource.service';
import { CreateResourceDto } from './dto/create-resource.dto';
import { UpdateResourceDto } from './dto/update-resource.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // Protezione JWT

@Controller('resource')
@UseGuards(JwtAuthGuard) // Solo chi è loggato può gestire i tavoli
export class ResourceController {
  constructor(private readonly resourceService: ResourceService) {}

  // Crea un nuovo tavolo: POST /resource
  @Post()
  create(@Body() dto: CreateResourceDto, @Request() req) {
    // req.user.tenantId arriva dal badge JWT decifrato dalla Strategy
    return this.resourceService.create(dto, req.user.tenantId);
  }

  // Lista di tutti i tavoli: GET /resource
  @Get()
  findAll(@Request() req) {
    return this.resourceService.findAll(req.user.tenantId);
  }

  @Patch(':id')
  update(
    @Param('id') id: string, 
    @Body() updateResourceDto: UpdateResourceDto
  ) {
    return this.resourceService.update(id, updateResourceDto);
  }
}