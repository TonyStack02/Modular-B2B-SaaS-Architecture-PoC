// backend/src/shift/dto/create-shift.dto.ts

import { IsString, IsDateString, IsOptional, IsUUID } from 'class-validator';

export class CreateShiftDto {
  @IsUUID()
  employeeId!: string; // ID del dipendente a cui assegniamo il turno

  @IsDateString()
  startTime!: string; // Inizio (ISO String con la Z finale!)

  @IsDateString()
  endTime!: string; // Fine

  @IsOptional()
  @IsString()
  notes?: string;
}