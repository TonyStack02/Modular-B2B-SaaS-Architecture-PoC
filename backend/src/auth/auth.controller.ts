// backend/src/auth/auth.controller.ts


import { Controller, Body, Post } from '@nestjs/common';
import { AuthService } from './auth.service';
// Importiamo i DTO per la validazione automatica dei dati in ingresso
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

// @Controller('auth') definisce il prefisso di tutte le rotte in questo file.
// Esempio: tutte inizieranno con http://localhost:3000/auth/...
@Controller('auth')
export class AuthController {

    // Iniettiamo il servizio nel costruttore per poterlo usare
    constructor( private readonly authService: AuthService) {}

    // Rotta per la registrazione: POST /auth/register
    @Post('register')
    // @Body() dice a NestJS di estrarre i dati dal corpo della richiesta e metterli nel DTO
    register(@Body() dto: RegisterDto) {
        // Passiamo la palla al servizio per la logica di business
        return this.authService.register(dto);
    }
    
    // Rotta per il login: POST /auth/login
    @Post('login')
    login (@Body() dto: LoginDto) {
        // Restituirà il token JWT se le credenziali sono corrette
        return this.authService.login(dto);
    }
}