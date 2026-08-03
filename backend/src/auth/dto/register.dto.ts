// backend/src/auth/dto/register.dto.ts

import { IsEmail, IsNotEmpty, IsString, MinLength } from 'class-validator';

export class LoginDto {
  @IsEmail()
  @IsNotEmpty()
  email!: string;

  @IsString()
  @IsNotEmpty()
  password!: string;
}


export class RegisterDto {
  @IsEmail()
  @IsNotEmpty()
  email!: string; // L'email dell'Owner

  @IsString()
  @IsNotEmpty()
  @MinLength(6)
  password!: string; // Password minima 6 caratteri

  @IsString()
  @IsNotEmpty()
  name!: string; // Nome dell'Owner

  @IsString()
  @IsNotEmpty()
  restaurantName!: string; // Nome della Pizzeria/Lido
}