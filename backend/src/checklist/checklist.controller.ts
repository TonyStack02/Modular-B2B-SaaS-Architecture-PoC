// backend/src/checklist/checklist.controller.ts

import { Controller, Get, Post, Body, Param, Query } from '@nestjs/common';
import { ChecklistService } from './checklist.service';

@Controller('checklists') // Tutte le rotte di questo controller inizieranno con l'indirizzo /checklists
export class ChecklistController {
  // Iniettiamo il nostro ChecklistService per poter sfruttare le funzioni che abbiamo scritto prima
  constructor(private readonly checklistService: ChecklistService) {}

  // backend/src/checklist/checklist.controller.ts

  /**
   * ROTTA GET PER CARICARE LE CHECKLIST DEL GIORNO
   * Viene chiamata dall'app Flutter ogni volta che un cameriere apre la sezione Checklist.
   */
  @Get('daily')
  async getDailyChecklists(
    @Query('tenantId') tenantId: string // Peschiamo l'ID del ristorante dai parametri URL (?tenantId=...)
  ) {
    // Chiamiamo il nostro motore Lazy e restituiamo l'array di istanze di oggi!
    return this.checklistService.getDailyChecklists(tenantId);
  }

  /**
   * ROTTA POST PER SALVARE O AGGIORNARE UNA SPUNTA
   * Esempio di chiamata: POST /checklists/result
   * Invia nel corpo (body) i dati necessari per registrare l'azione del cameriere.
   */
  @Post('result')
  async saveTaskResult(
    @Body() body: {
      instanceId: string;     // A quale checklist giornaliera stiamo lavorando
      taskTemplateId: string; // Quale domanda/compito specifico stiamo spuntando
      employeeId: string;     // Quale dipendente sta compiendo l'azione (per l'accountability)
      value: string;          // Il valore inserito (es. 'true', '3.5' per le temperature, o il link della foto)
    },
  ) {
    // Sfruttiamo la funzione upsert del service per salvare il dato all'istante sul database
    return this.checklistService.saveTaskResult(
      body.instanceId,
      body.taskTemplateId,
      body.employeeId,
      body.value,
    );
  }

  /**
   * ROTTA POST PER CREARE UN NUOVO TEMPLATE (Uso: HR / Titolare)
   * L'app Flutter invia qui il JSON con il nome del modello e la lista delle domande.
   */
  @Post('templates')
  async createTemplate(
    @Body() body: {
      tenantId: string;
      name: string;
      description?: string;
      daysOfWeek: string[]; 
      targetTimes: string[];
      tasks: { title: string; type: string; order: number }[];
    },
  ) {
    // Passiamo semplicemente i dati estratti dal Body al nostro Service per salvarli nel DB
    return this.checklistService.createTemplate(
      body.tenantId,
      body.name,
      body.tasks,
      body.daysOfWeek,
      body.targetTimes,
      body.description,
    );
  }
}