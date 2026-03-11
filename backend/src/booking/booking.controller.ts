// backend/src/booking/booking.controller.ts
import { Controller, Get, Post, Body, Patch, Param, UseGuards, Request } from '@nestjs/common';
import { BookingService } from './booking.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { UpdateBookingDto } from './dto/update-booking.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; // 🛡️ Importiamo la guardia

@Controller('booking')
@UseGuards(JwtAuthGuard) // 🛡️ Nessuno entra senza token!
export class BookingController {
  constructor(private readonly bookingService: BookingService) {}

  // POST /booking -> Crea nuova prenotazione manuale
  @Post()
  create(@Body() dto: CreateBookingDto, @Request() req) {
    return this.bookingService.create(req.user.tenantId, dto);
  }

  // GET /booking/month/2026/3 -> Prendi il calendario di Marzo
  @Get('month/:year/:month')
  findByMonth(
    @Param('year') year: string, 
    @Param('month') month: string,
    @Request() req
  ) {
    // Trasformiamo i parametri dell'URL (che sono stringhe) in numeri
    return this.bookingService.findByMonth(req.user.tenantId, parseInt(year), parseInt(month));
  }

  // PATCH /booking/:id -> Modifica stato (es. CANCELLED)
  @Patch(':id')
  update(
    @Param('id') id: string, 
    @Body() dto: UpdateBookingDto,
    @Request() req
  ) {
    return this.bookingService.update(id, req.user.tenantId, dto);
  }
}