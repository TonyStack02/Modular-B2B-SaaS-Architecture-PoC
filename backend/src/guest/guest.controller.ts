// backend/src/guest/guest.controller.ts

import { Controller, Get, Post, Body, Param } from '@nestjs/common';
import { GuestService } from './guest.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { CreateOrderDto } from './dto/create-order.dto';

@Controller('guest') // Tutte le richieste inizieranno con /guest
export class GuestController {
  constructor(private readonly guestService: GuestService) {}

  // Esempio chiamata: GET /guest/MENU_ID/menu
  @Get(':id/menu')
  getMenu(@Param('id') id: string) {
    return this.guestService.getRestaurantMenu(id);
  }

  // Esempio chiamata: GET /guest/MENU_ID/resources
  @Get(':id/resources')
  getResources(@Param('id') id: string) {
    return this.guestService.getRestaurantResources(id);
  }

  // Rotta per inviare una prenotazione: POST /guest/booking
  @Post('booking')
  // @Body() dice a NestJS di prendere i dati dal corpo della richiesta e metterli nel DTO
  createBooking(@Body() dto: CreateBookingDto){
    return this.guestService.createBooking(dto);
  }

  // Rotta per inviare un ordine: POST /guest/order
  @Post('order')
  createOrder(@Body() dto: CreateOrderDto){
    return this.guestService.createOrder(dto);
  }

}