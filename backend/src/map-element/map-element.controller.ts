// backend/src/map-element/map-element.controller.ts

import { Controller, Get, Post, Body, Patch, Param, UseGuards, Request, Delete } from '@nestjs/common';
import { MapElementService } from './map-element.service';
import { CreateMapElementDto } from './dto/create-map-element.dto';
import { UpdateMapElementDto } from './dto/update-map-element.dto';

// 1. IMPORTIAMO LA GUARDIA DI SICUREZZA
// Questa serve per bloccare chi non ha fatto il login e per leggere i dati dell'utente dal Token
import { JwtAuthGuard } from '../auth/jwt-auth.guard'; 

@Controller('map-element')
// 2. APPLICHIAMO LA GUARDIA A TUTTO IL CONTROLLER
// Da questo momento in poi, se l'app Flutter non manda il Token JWT valido, 
// NestJS respinge la chiamata con un errore 401 Unauthorized.
@UseGuards(JwtAuthGuard) 
export class MapElementController {
  constructor(private readonly mapElementService: MapElementService) {}

  // Rotta per creare un nuovo muro o porta: POST /map-element
  @Post()
  create(@Body() createMapElementDto: CreateMapElementDto, @Request() req) {
    // 3. ESTRAIAMO IL VERO TENANT ID
    // req.user viene popolato in automatico dalla JwtAuthGuard decifrando il token.
    // Ora passiamo al Service il vero ID del ristorante loggato!
    return this.mapElementService.create(createMapElementDto, req.user.tenantId);
  }

  // Rotta per scaricare tutti i muri del locale: GET /map-element
  @Get()
  findAll(@Request() req) {
    // Anche qui, leggiamo il tenantId dell'utente connesso, 
    // così il DB gli restituisce SOLO i muri del suo ristorante e non quelli degli altri!
    return this.mapElementService.findAll(req.user.tenantId);
  }

  // Rotta per salvare le coordinate del muro quando alzi il dito: PATCH /map-element/:id
  @Patch(':id')
  update(@Param('id') id: string, @Body() updateMapElementDto: UpdateMapElementDto) {
    // Qui aggiorniamo un elemento specifico tramite il suo ID univoco,
    // quindi non ci serve ripassare il tenantId al service.
    return this.mapElementService.update(id, updateMapElementDto);
  }

  // 💥 Rotta per eliminare l'elemento: DELETE /map-element/:id
  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.mapElementService.remove(id);
  }
}