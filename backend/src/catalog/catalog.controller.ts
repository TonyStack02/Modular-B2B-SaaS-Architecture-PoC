// backend/src/catalog/catalog.controller.ts

import { Controller, Post, Get, Body, UseGuards, Request } from '@nestjs/common';
import { CatalogService } from './catalog.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // Il lucchetto che abbiamo creato
import { CreateCategoryDto } from './dto/create-category.dto';
import { CreateProductDto } from './dto/create-product.dto';

// @Controller('catalog') definisce il prefisso di tutte le rotte in questo file.
@Controller('catalog')
@UseGuards(JwtAuthGuard) // Protegge TUTTE le rotte di questo controller
export class CatalogController {
    constructor (private readonly catalogService: CatalogService) {}

    @Post('category')
    createCategory(@Body() dto: CreateCategoryDto, @Request() req) {
        return this.catalogService.createCategory(dto, req.user.tenantId);
    }

    @Post('product')
    createProduct (@Body() dto: CreateProductDto, @Request() req) {
        return this.catalogService.createProdut(dto, req.user.tenantId);    
    }

    @Get() 
    findAll(@Request() req) {
        return this.catalogService.findAll(req.user.tenantId);
    }
}