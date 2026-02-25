// backend/src/guest/guest.module.ts

import { Module } from '@nestjs/common';
import { GuestService } from './guest.service';
import { GuestController } from './guest.controller';
import { PrismaService } from '../prisma.service';

@Module({
  controllers: [GuestController],
  providers: [
    GuestService, 
    PrismaService 
  ], 
})
export class GuestModule {}