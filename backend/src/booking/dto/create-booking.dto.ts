// backend/src/booking/dto/create-booking.dto.ts
import { IsInt, IsNotEmpty, IsOptional, IsString, IsDateString, IsUUID, Min } from 'class-validator';

export class CreateBookingDto {
  @IsDateString()
  @IsNotEmpty()
  dateTime: string;

  @IsInt()
  @Min(1)
  guests: number;

  @IsString()
  @IsNotEmpty()
  customerName: string; // Il nome di chi chiama al telefono

  @IsString()
  @IsOptional()
  customerPhone?: string; // Il numero di telefono

  @IsUUID()
  @IsOptional()
  resourceId?: string; // Se gli assegniamo subito un tavolo
}