// backend/src/area/area.controller.ts

import { Controller, Get, Post, Body, UseGuards, Request } from '@nestjs/common';
import { AreaService } from './area.service';
import { CreateAreaDto } from './dto/create-area.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // La nostra guardia di sicurezza

@Controller('area')
@UseGuards(JwtAuthGuard)
export class AreaController {
    constructor (private readonly areaService: AreaService) {}

    // Rotta per creare un'area: POST /area
    @Post()
    createArea (@Body() dto: CreateAreaDto, @Request() req) {
        return this.areaService.createArea(dto, req.user.tenantId);
    }

    // Rotta per vedere tutte le aree: GET /area
    @Get()
    findAll (@Request() req) {
        return this.areaService.findAll(req.user.tenantId);
    }
}