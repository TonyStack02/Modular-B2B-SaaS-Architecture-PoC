// backend/src/catalog/catalog.controller.ts

import { Controller, Post, Get, Body, UseGuards, Request, UseInterceptors, UploadedFile } from '@nestjs/common';

import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';

import { CatalogService } from './catalog.service';

import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // Il lucchetto che abbiamo creato

import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { UserRole } from '@prisma/client';

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

    @Post('product/upload')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(UserRole.OWNER)
    // Usiamo un intercettore per gestire il file nel body della richiesta
    @UseInterceptors(FileInterceptor('image', {
        storage: diskStorage({
            destination: './uploads/products', // Dove salviamo le foto
            filename: (req, file, cb) => {
                // Generiamo un nome unico: timestamp + estensione originale
                const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
                cb(null, `${uniqueSuffix}${extname(file.originalname)}`);
            },
        }),
    }))
    uploadFile(@UploadedFile() file: Express.Multer.File) {
        // Restituiamo il percorso del file che il frontend salverà nel database
        return {url: `/uploads/products/${file.filename}`};
    }


}