// backend/src/customer/customer.module.ts

import { Module } from '@nestjs/common';
import { CustomerService } from './customer.service';
import { CustomerController } from './customer.controller';
import { PrismaService } from '../prisma.service'; // 👈 Aggiungi l'import

@Module({
  controllers: [CustomerController],
  providers: [CustomerService, PrismaService], // 👈 Inseriscilo qui
})
export class CustomerModule {}