// backend/src/resource/dto/create-resource.dto.ts

import { IsNotEmpty, IsString, IsUUID } from 'class-validator';

export class CreateResourceDto {
    // Il nome identificativo, es: "Tavolo 12" o "Ombrellone 42"
    @IsString({ message: 'Il nome deve essere una stringa' })
    @IsNotEmpty({ message: 'Il nome della risorsa non può essere vuoto' })
    name: string;

    // L'ID dell'Area (già creata) in cui si trova questa risorsa
    // Usiamo IsUUID perché nel nostro schema gli ID sono stringhe UUID
    @IsUUID('4', { message: 'L ID dell area deve essere un UUID valido' })
    @IsNotEmpty({ message: 'L ID dell area è obbligatorio' })
    areaId: string;
}