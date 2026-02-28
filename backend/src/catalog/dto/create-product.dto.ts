import { IsNotEmpty, IsOptional, IsString, IsUUID, Min, IsNumber } from 'class-validator';


export class CreateProductDto {

    @IsString()
    @IsNotEmpty()
    name: string; // Esempio: "Pizza Margherita"

    @IsString()
    @IsOptional()
    description?: string; // Ingredienti o dettagli

    @IsNumber() 
    @Min(0)
    price: number; // Prezzo di vendita

    @IsString()
    @IsOptional()
    imageUrl?: string;

    @IsNotEmpty()
    @IsUUID()
    categoryId: string; // L'ID della categoria a cui appartiene
}