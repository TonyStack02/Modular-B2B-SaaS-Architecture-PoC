// backend/src/auth/jwt.strategy.ts
import { ExtractJwt, Strategy } from "passport-jwt";
import { PassportStrategy } from "@nestjs/passport";
import { Injectable } from "@nestjs/common";

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy){
    constructor () {
        super ({
            // 1. Diciamo alla strategia dove trovare il token: negli Header come "Bearer Token"
            jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),

            // 2. Non accettiamo token scaduti
            ignoreExpiration: false,

            // 3. Usiamo la stessa chiave segreta del file .env per decifrare il badge
            secretOrKey: process.env.JWT_SECRET || 'SUPER_SECRET_KEY',
        });
    }

    // 4. Questa funzione viene chiamata AUTOMATICAMENTE se il badge è valido.
    // Riceve il "payload" (le info che abbiamo scritto nel token durante il login)
    async validate (payload: any) {
        // Quello che restituiamo qui verrà inserito da NestJS dentro l'oggetto Request (req.user)
        // Così in ogni rotta sapremo chi è l'utente e a che ristorante appartiene!
        return {
            userId: payload.sub,
            email: payload.email,
            role: payload.role,
            tenantId: payload.tenantId
        };
    }
}