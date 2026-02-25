// backend/src/guest/dto/create-booking.dto.ts
import { IsEmail, IsInt, IsNotEmpty, IsOptional, IsString, IsUUID, Min, IsDateString } from 'class-validator';

export class CreateBookingDto {
  @IsUUID()
  @IsNotEmpty()
  tenantId: string; // Il ristorante specifico

  @IsDateString()
  @IsNotEmpty()
  dateTime: string; // Data e ora della prenotazione

  @IsInt()
  @Min(1)
  guests: number; // Numero di persone, minimo 1

  @IsString()
  @IsNotEmpty()
  customerName: string;

  @IsEmail()
  @IsNotEmpty()
  customerEmail: string;

  @IsUUID()
  @IsOptional()
  resourceId?: string; // Tavolo specifico, opzionale
}