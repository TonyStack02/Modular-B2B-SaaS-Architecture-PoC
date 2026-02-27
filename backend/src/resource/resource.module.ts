// backend/src/resource/resource.module.ts

import { Module } from '@nestjs/common';
import { ResourceService } from './resource.service';
import { ResourceController } from './resource.controller';
import { PrismaService } from '../prisma.service';

@Module({
  controllers: [ResourceController],
  providers: [ResourceService, PrismaService],
})
export class ResourceModule {}