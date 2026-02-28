// backend/src/auth/roles.decorator.ts

import { SetMetadata } from "@nestjs/common";
import { UserRole } from '@prisma/client'; // Usiamo l'ENUM del DB

// Questo crea la chiave 'roles' nei metadati della rotta
export const ROLES_KEY = 'roles';
export const Roles = (...roles: UserRole[]) => SetMetadata (ROLES_KEY, roles);
