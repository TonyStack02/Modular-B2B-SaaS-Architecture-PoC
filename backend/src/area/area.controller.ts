// backend/src/area/area.controller.ts

import { Controller, Get, Post, Delete, Param, Body, UseGuards, Request } from '@nestjs/common';
import { AreaService } from './area.service';
import { CreateAreaDto } from './dto/create-area.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // La nostra guardia di sicurezza
import { RolesGuard } from 'src/auth/roles.guard';
import { Roles } from 'src/auth/roles.decorator';
import { UserRole } from '@prisma/client';

@Controller('area')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AreaController {
    constructor (private readonly areaService: AreaService) {}

    // Rotta per creare un'area: POST /area
    @Post()
    @Roles(UserRole.OWNER)
    createArea (@Body() dto: CreateAreaDto, @Request() req) {
        return this.areaService.createArea(dto, req.user.tenantId);
    }

    // Rotta per vedere tutte le aree: GET /area
    @Get()
    findAll (@Request() req) {
        return this.areaService.findAll(req.user.tenantId);
    }

    // Rotta per eliminare un'area: DELETE /area
    @Delete(':id')
    @Roles(UserRole.OWNER)
    remove(@Param('id') id: string, @Request() req) {
        // Passiamo sia l'ID dell'area che il tenantId per sicurezza
        return this.areaService.remove( id, req.user.tenantId);
    }
}