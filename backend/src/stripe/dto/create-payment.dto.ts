// backend/src/stripe/dto/create-payment.dto.ts

import { IsNotEmpty, IsNumber, IsPositive, IsString } from 'class-validator';

export class CreatePaymentDto {
  @IsNumber()
  @IsPositive()
  amount: number; // L'importo totale dell'ordine da pagare

  @IsString()
  @IsNotEmpty()
  orderId: string;
}