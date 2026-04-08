// backend\src\order\dto\update-order-status.dto.ts

import { IsEnum, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { OrderStatus } from '@prisma/client'; // Prendiamo gli stati direttamente dal database

export class UpdateOrderStatusDto {
  @IsEnum(OrderStatus)
  @IsNotEmpty()
  status!: OrderStatus; // Gli stati sono: PENDING, PREPARING, SERVED, PAID, CANCELLED

  //Permettiamo di associare un cliente quando l'ordine viene pagato
  @IsOptional()
  @IsString()
  customerId?: string;
}