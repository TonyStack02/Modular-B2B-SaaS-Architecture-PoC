import { Module } from '@nestjs/common';
import { CatalogService } from './catalog.service';
import { CatalogController } from './catalog.controller';
import { PrismaService } from 'src/prisma.service';

@Module({
  providers: [CatalogService, PrismaService],
  controllers: [CatalogController]
})
export class CatalogModule {}
