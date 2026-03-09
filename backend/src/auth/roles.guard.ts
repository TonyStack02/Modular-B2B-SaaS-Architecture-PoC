// backend/src/auth/roles.guard.ts

import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '@prisma/client';
import { ROLES_KEY } from './roles.decorator';
import { Observable } from 'rxjs';

@Injectable()
export class RolesGuard implements CanActivate {
    constructor (private reflector: Reflector) {}
    
    canActivate(context: ExecutionContext): boolean {
        // 1. Legge quali ruoli sono richiesti per questa specifica rotta
        const requiredRoles = this.reflector.getAllAndOverride<UserRole[]>(ROLES_KEY, [
            context.getHandler(),
            context.getClass(),
        ]);

        // Se la rotta non ha il decoratore @Roles, l'accesso è libero (per chi è loggato)
        if (!requiredRoles) { return true; }

        // 2. Prende l'utente dalla richiesta (caricato prima dalla JwtAuthGuard)
        const { user } = context.switchToHttp().getRequest();

        // 3. Verifica se il ruolo dell'utente è tra quelli permessi
        const hasRole = requiredRoles.some( (UserRole) => user.role?.includes(UserRole));

        if (!hasRole) {
            throw new ForbiddenException('Non hai i permessi necessari per questa azione');
        }

        return hasRole;
    }

}