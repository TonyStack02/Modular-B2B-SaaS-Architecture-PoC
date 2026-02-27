import { Injectable, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma.service'; // Per parlare con il DB
import { JwtService } from '@nestjs/jwt'; // Per generare il "badge" (token)
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import * as bcrypt from 'bcrypt'; // La libreria per frullare le password
import { access } from 'fs';

@Injectable()
export class AuthService {
    // Iniettiamo i servizi necessari nel costruttore
    constructor (
        private prisma: PrismaService,
        private jwtService: JwtService
    ) {}

    // --- LOGICA DI REGISTRAZIONE ---
    async register (dto: RegisterDto){
        // 1. Controlliamo se l'email esiste già per non avere duplicati
        const userExists = await this.prisma.user.findUnique({
            where: { email: dto.email},
        });


        if (userExists) {
            throw new BadRequestException('Questa email è già registrata');
        }

        // 2. "Frulliamo" la password. Il numero 10 è il "salt", ovvero la complessità del frullatore.
        const hashedPassword = await bcrypt.hash(dto.password, 10);

        // 3. Operazione Atomica: Creiamo il Ristorante e l'Owner insieme.
        // Usiamo la potenza di Prisma per collegarli subito
        return this.prisma.tenant.create({
            data: {
                name: dto.restaurantName,
                users: {
                    create: {
                        email: dto.email,
                        password: hashedPassword,
                        name: dto.name,
                        role: 'OWNER',
                    },
                },
            },
            // Chiediamo a Prisma di restituirci anche l'utente appena creato
            include: {
                users: true,
            },
        });
    }

    // --- LOGICA DI LOGIN ---
    async login (dto: LoginDto) {
        
        // 1. Cerchiamo l'utente nel database tramite email
        const user = await this.prisma.user.findUnique({
            where: { email: dto.email },
        });

        // 2. Se l'utente non esiste, lanciamo un errore di autorizzazione
        if(!user) {
           throw new UnauthorizedException('Credenziali non valide');
        }

        // 3. Confrontiamo la password ricevuta con quella frullata nel DB
        const isPasswordValid = await bcrypt.compare(dto.password, user.password);

        if(!isPasswordValid) {throw new UnauthorizedException ('Credenziali non valide!');}

        // 4. Se è tutto OK, prepariamo il "Payload" (le info da scrivere nel badge)
        // Qui mettiamo il tenantId così il backend saprà sempre a quale ristorante appartiene!
        const payload = {
            sub: user.id,
            email: user.email,
            role: user.role,
            tenantId: user.tenantId
        };

        // 5. Generiamo il token JWT firmato con la nostra chiave segreta
        return {
            access_token: this.jwtService.sign(payload),
        };

    }
}