// backend/src/booking/dto/update-booking.dto.ts
import { PartialType } from '@nestjs/mapped-types';
import { CreateBookingDto } from './create-booking.dto';
import { IsOptional, IsString } from 'class-validator';

export class UpdateBookingDto extends PartialType(CreateBookingDto) {
  @IsString()
  @IsOptional()
  status?: string; // Per poterla segnare come CANCELLED
}