// backend/src/catalog/catalog.service.ts

import { Injectable } from "@nestjs/common";
import { PrismaService } from "../prisma.service";
import { CreateCategoryDto } from "./dto/create-category.dto";
import { CreateProductDto } from "./dto/create-product.dto";

@Injectable()
export class CatalogService {
    constructor (private prisma: PrismaService) {}

    // Creazione di una categoria legata a un ristorante specifico
    async createCategory (dto: CreateCategoryDto, tenantId: string) {
        return this.prisma.category.create({
            data: {
                name: dto.name,
                tenantId: tenantId, // Isolamento dei dati (Multi-tenancy)
            }
        });
    }

    // Creazione di un prodotto dentro una categoria
    async createProdut (dto: CreateProductDto, tenantId: string) {
        return this.prisma.product.create({
            data: {
                name: dto.name,
                description: dto.description,
                price: dto.price,
                imageUrl: dto.imageUrl,
                categoryId: dto.categoryId,
                tenantId: tenantId,
            }
        });
    }

    // Recupera tutte le categorie con i relativi prodotti (lato Owner)
    async findAll (tenantId: string) {
        return this.prisma.category.findMany({
            where: {tenantId: tenantId},
            include: { products: true}, // Include la lista prodotti in ogni categoria
        });
    }

}