// backend/src/map-element/dto/create-map-element.dto.ts

import { IsString, IsNumber, IsOptional } from 'class-validator';

export class CreateMapElementDto {
  @IsString()
  type!: string; // 👈 Il punto esclamativo zittisce l'errore di TypeScript!

  @IsOptional()
  @IsString()
  text?: string; // Col punto interrogativo è già a posto (può essere nullo)

  @IsNumber()
  positionX!: number;

  @IsNumber()
  positionY!: number;

  @IsNumber()
  width!: number;

  @IsNumber()
  height!: number;

  @IsOptional()
  @IsNumber()
  rotation?: number;
}