import { IsEnum, IsNotEmpty } from 'class-validator';
import { OrderStatus } from '@prisma/client'; // Prendiamo gli stati direttamente dal database

export class UpdateOrderStatusDto {
  @IsEnum(OrderStatus)
  @IsNotEmpty()
  status: OrderStatus; // Gli stati sono: PENDING, PREPARING, SERVED, PAID, CANCELLED
}