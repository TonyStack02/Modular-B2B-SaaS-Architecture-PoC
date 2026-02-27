// backend/src/auth/jwt-auth.guard.ts
import { Injectable } from "@nestjs/common";
import { AuthGuard } from "@nestjs/passport";

@Injectable()
// Estendiamo AuthGuard('jwt') che punta automaticamente alla nostra JwtStrategy
export class JwtAuthGuard extends AuthGuard('jwt') {}