// backend/src/checklist/checklist.service.ts

import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma.service';
import { TaskType } from '@prisma/client'; // 1. <--- IMPORTIAMO L'ENUM UFFICIALE DA PRISMA

@Injectable()
export class ChecklistService {
  // Iniettiamo PrismaService nel costruttore per poter parlare con il nostro database PostgreSQL
  constructor(private readonly prisma: PrismaService) {}

  // backend/src/checklist/checklist.service.ts

  /**
   * MOTORE LAZY: Ottiene e genera al volo le checklist del giorno corrente.
   * Viene chiamato appena un cameriere apre la pagina delle checklist.
   */
  async getDailyChecklists(tenantId: string) {
    
    // 1. Capiamo che giorno è oggi e lo trasformiamo nel formato atteso dal DB (es. "MONDAY")
    const today = new Date();
    const days = ['SUNDAY', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'];
    const currentDayString = days[today.getDay()];

    // 2. Creiamo una data "pulita" a mezzanotte esatta. 
    // Ci serve per dire al DB "Questa è la checklist del 3 Agosto", ignorando l'ora in cui viene creata.
    const todayMidnight = new Date(today.getFullYear(), today.getMonth(), today.getDate());

    // 3. Peschiamo dal DB TUTTI i modelli (Template) di questo ristorante 
    // che hanno il giorno di oggi nell'array 'daysOfWeek'.
    const templatesForToday = await this.prisma.checklistTemplate.findMany({
      where: {
        tenantId: tenantId,
        daysOfWeek: {
          has: currentDayString, // Comando speciale di Prisma per cercare negli array
        },
      },
    });

    // 4. GENERAZIONE ON-DEMAND (Il vero trucco!)
    // Cicliamo ogni modello che abbiamo trovato per oggi...
    for (const template of templatesForToday) {
      
      // ...e cicliamo ogni orario previsto per quel modello (es. ["14:00", "23:00"])
      for (const time of template.targetTimes) {
        
        // Usiamo upsert: se l'istanza per questo giorno e orario esiste già, non fa nulla (update vuoto).
        // Se NON esiste, la crea al volo in una frazione di secondo.
        // L'indice univoco @@unique([templateId, date, targetTime]) che abbiamo messo nel DB garantisce che non ci siano mai cloni!
        await this.prisma.checklistInstance.upsert({
          where: {
            // Prisma autogenera il nome dell'indice composto unendo i nomi dei campi
            templateId_date_targetTime: {
              templateId: template.id,
              date: todayMidnight,
              targetTime: time,
            },
          },
          update: {}, // Nessuna modifica se l'istanza c'è già (i camerieri la stanno già compilando)
          create: {
            date: todayMidnight,
            targetTime: time,
            tenantId: tenantId,
            templateId: template.id,
            status: 'PENDING', // Di base nasce come "da fare"
          },
        });
      }
    }

    // 5. RITORNIAMO TUTTO AL FRONTEND
    // Ora che siamo sicuri al 100% che tutte le istanze di oggi esistano,
    // le andiamo a pescare e le rispediamo a Flutter per farle vedere ai ragazzi.
    return this.prisma.checklistInstance.findMany({
      where: {
        tenantId: tenantId,
        date: todayMidnight, // Solo quelle di oggi!
      },
      // Includiamo tutta la roba collegata che ci serve sulla UI
      include: {
        template: {
          include: {
            tasks: {
              orderBy: { order: 'asc' }, // Assicuriamoci che le domande siano nell'ordine giusto (1, 2, 3...)
            },
          },
        },
        results: true, // Includiamo anche eventuali spunte già messe dai colleghi
      },
      orderBy: {
        targetTime: 'asc', // Ordiniamo per orario: prima le checklist della mattina, poi quelle della sera
      },
    });
  }

  /**
   * SALVA UNA SPUNTA (UPSERT)
   * Questa funzione viene chiamata ogni volta che un cameriere fa "Tap" su una spunta.
   * Usa il super-potere dell'UPSERT: se la spunta non c'è la crea, se c'è già la aggiorna.
   */
  async saveTaskResult(
    instanceId: string,
    taskTemplateId: string,
    employeeId: string,
    value: string, // 'true', '4.5', 'foto.jpg', ecc.
  ) {
    // Usiamo l'upsert di Prisma per inserire o aggiornare la riga in un colpo solo (senza controllare prima se esiste)
    return this.prisma.checklistTaskResult.upsert({
      // 'where' usa l'indice univoco che abbiamo creato nello schema Prisma.
      // Cerca se esiste già una risposta per questa specifica domanda in questa specifica checklist di oggi.
      where: {
        instanceId_taskTemplateId: {
          instanceId: instanceId,
          taskTemplateId: taskTemplateId,
        },
      },
      // Se NON esiste, crea una nuova riga con questi dati (INSERT)
      create: {
        instanceId: instanceId,
        taskTemplateId: taskTemplateId,
        employeeId: employeeId,
        value: value,
      },
      // Se ESISTE GIÀ, aggiorna i dati esistenti (UPDATE)
      // Questo è utilissimo se un cameriere spunta, poi toglie la spunta, o cambia il valore di una temperatura.
      update: {
        employeeId: employeeId, // Aggiorniamo anche l'employeeId nel caso l'abbia modificato un altro collega
        value: value,
        timestamp: new Date(), // Aggiorniamo l'ora all'istante attuale
      },
      // Come per la lettura, ci tiriamo dietro il nome del dipendente per poterlo mandare via WebSocket ai colleghi
      include: {
        employee: {
          select: { firstName: true, lastName: true },
        },
      },
    });
  }

  /**
   * CREAZIONE DI UN NUOVO MODELLO DI CHECKLIST (TEMPLATE)
   * Questa funzione viene chiamata dal gestore del locale per creare una nuova routine
   * (es. "Chiusura Cucina") con tutte le sue domande associate.
   */
  async createTemplate(
    tenantId: string,
    name: string,
    tasks: { title: string; type: string; order: number }[],
    daysOfWeek: string[], 
    targetTimes: string[],
    description?: string,
  ) {
    return this.prisma.checklistTemplate.create({
      data: {
        tenantId: tenantId,
        name: name,
        description: description,

        daysOfWeek: daysOfWeek,
        targetTimes: targetTimes,
        
        tasks: {
          create: tasks.map((task) => ({
            title: task.title,
            // 3. <--- MAGIA: diciamo a TS che questa stringa è al 100% un TaskType di Prisma
            type: task.type as TaskType, 
            order: task.order,
          })),
        },
      },
    });
  }
}