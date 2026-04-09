// backend/src/guest/dto/create-order.dto.ts

import { IsArray, IsInt, IsNotEmpty, IsOptional, IsString, IsUUID, Min, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

class OrderItemDto {
  // L'ID del prodotto (es. l'ID della Margherita)
  @IsUUID()
  @IsNotEmpty()
  productId: string; 

  // Quante ne vogliono
  @IsInt()
  @Min(1)
  quantity: number;

  // 📝 ECCO LA MODIFICA: Insegniamo al server ad accettare le note
  // Usiamo @IsOptional() perché non tutti i piatti avranno una nota
  // Usiamo @IsString() per assicurarci che sia testo e non roba strana (es. codice malevolo)
  @IsOptional()
  @IsString()
  notes?: string; 
}

export class CreateOrderDto {
  // A quale ristorante appartiene l'ordine
  @IsUUID()
  @IsNotEmpty()
  tenantId: string;

  // L'ID del tavolo da cui ordinano
  @IsUUID()
  @IsNotEmpty()
  resourceId: string; 

  // L'ID del cliente (se è registrato in rubrica)
  @IsUUID()
  @IsOptional()
  customerId?: string;

  // La lista dei prodotti ordinati, che deve rispettare le regole scritte sopra in OrderItemDto
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items: OrderItemDto[]; 
}