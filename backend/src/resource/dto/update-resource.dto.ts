// backend/src/resource/dto/update-resource.dto.ts

// Importiamo le regole di validazione per assicurarci che ci arrivino numeri veri e non testo a caso
import { IsNumber, IsOptional, IsString } from 'class-validator';

export class UpdateResourceDto {
  // Se vogliamo permettere all'Owner di rinominare il tavolo (es. da "Tavolo 1" a "Tavolo 1B")
  // IsOptional() significa che se non mandiamo il nome, NestJS non si arrabbia e tiene quello vecchio.
  @IsString()
  @IsOptional()
  name?: string;

  // Questa è la coordinata orizzontale (Sinistra/Destra) sullo schermo di Flutter
  @IsNumber()
  @IsOptional()
  positionX?: number;

  // Questa è la coordinata verticale (Alto/Basso) sullo schermo di Flutter
  @IsNumber()
  @IsOptional()
  positionY?: number;
}