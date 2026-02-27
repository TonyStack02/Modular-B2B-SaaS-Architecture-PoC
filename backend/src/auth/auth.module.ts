import { Module } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { JwtStrategy } from './jwt.strategy';

@Module({
  // 'imports' è la lista di altri moduli di cui questa "scatola" ha bisogno per funzionare
  imports: [
    PassportModule, // Carica le funzioni base per gestire badge e permessi
    
    // Configuriamo il modulo JWT
    JwtModule.register({
      // Il 'secret' è la chiave segreta usata per firmare il badge. 
      // Se qualcuno la scopre, può creare badge falsi. Per questo la mettiamo nel file .env
      secret: process.env.JWT_SECRET || 'SUPER_SECRET_KEY', 
      
      // Definiamo le opzioni del badge
      signOptions: { 
        expiresIn: '1d' // Il badge (token) "scade" dopo 24 ore. L'utente dovrà rifare il login.
      }, 
    }),
  ],
  
  // 'controllers' sono i file che ricevono le chiamate HTTP (es: POST /auth/login)
  controllers: [AuthController],
  
  // 'providers' sono i servizi che contengono la logica "intelligente" (calcoli, database)
  providers: [AuthService, JwtStrategy],
  exports: [AuthService],
})
export class AuthModule {}