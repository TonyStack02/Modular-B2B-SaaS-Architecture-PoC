// backend/src/booking/booking.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { UpdateBookingDto } from './dto/update-booking.dto';

@Injectable()
export class BookingService {
  constructor(private prisma: PrismaService) {}


  // L'Owner aggiunge una prenotazione a mano
  async create(tenantId: string, dto: CreateBookingDto) {
    let customerId: string | null = null;

    // 🌉 IL PONTE MAGICO: Se ci hanno dato un numero di telefono, scatta l'automazione
    if (dto.customerPhone && dto.customerPhone.trim() !== '') {
      
      // 1. Cerchiamo se questo numero esiste già nella nostra rubrica clienti
      const existingCustomer = await this.prisma.customer.findFirst({
        where: { 
          tenantId: tenantId, 
          phone: dto.customerPhone 
        }
      });

      if (existingCustomer) {
        // 2A. TROVATO! Usiamo il suo ID.
        // In futuro, se l'Owner ha scritto "Mario" ma in rubrica è "Mario Rossi",
        // terrà fede la rubrica.
        customerId = existingCustomer.id;
      } else {
        // 2B. NON TROVATO! Lo creiamo noi in background senza disturbare l'Owner.
        const newCustomer = await this.prisma.customer.create({
          data: {
            tenantId: tenantId,
            firstName: dto.customerName, // Salviamo il nome che ci ha appena detto al telefono
            phone: dto.customerPhone,
            // Lasciamo vuoti cognome ed email per ora
          }
        });
        customerId = newCustomer.id; // Prendiamo l'ID del cliente appena "nato"
      }
    }

    // 3. Creiamo finalmente la prenotazione
    return this.prisma.booking.create({
      data: {
        tenantId: tenantId,
        dateTime: new Date(dto.dateTime),
        guests: dto.guests,
        customerName: dto.customerName, // Continuiamo a salvarlo qui per sicurezza e storico
        customerPhone: dto.customerPhone,
        resourceId: dto.resourceId, // L'ID del tavolo (se glielo assegniamo subito)
        customerId: customerId, // 👈 IL COLLEGAMENTO D'ORO AL CRM!
        status: 'CONFIRMED'
      }
    });
  }

  // 📅 LA MAGIA PER IL CALENDARIO: Trova le prenotazioni di un mese specifico
  async findByMonth(tenantId: string, year: number, month: number) {
    // JS conta i mesi da 0 (Gennaio) a 11 (Dicembre). Noi passiamo 1-12, quindi facciamo month - 1
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59, 999); // L'ultimo giorno del mese

    return this.prisma.booking.findMany({
      where: {
        tenantId: tenantId,
        dateTime: {
          gte: startDate, // Da inizio mese...
          lte: endDate    // ...a fine mese
        }
      },
      include: {
        resource: true // Includiamo i dettagli del tavolo
      },
      orderBy: { dateTime: 'asc' } // In ordine cronologico
    });
  }

  // Aggiorna o cancella una prenotazione
  async update(id: string, tenantId: string, dto: UpdateBookingDto) {
    // Verifichiamo che esista e sia del nostro ristorante
    const booking = await this.prisma.booking.findFirst({
      where: { id, tenantId }
    });

    if (!booking) throw new NotFoundException('Prenotazione non trovata');

    return this.prisma.booking.update({
      where: { id },
      data: {
        ...dto,
        dateTime: dto.dateTime ? new Date(dto.dateTime) : undefined
      }
    });
  }
}