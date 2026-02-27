// backend/src/area/dto/create-area.dto.ts

import { IsNotEmpty, IsString } from "class-validator";

export class CreateAreaDto {
    // Il nome dell'area, ad esempio "Terrazza Vista Mare"
    @IsNotEmpty({ message: 'Il nome dell area non può essere vuoto' })
    @IsString({ message: 'Il nome deve essere una stringa' })
    name: string;
}