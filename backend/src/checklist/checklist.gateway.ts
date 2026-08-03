// backend/src/checklist/checklist.gateway.ts

import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ChecklistService } from './checklist.service';

// Decoratore per trasformare questa classe in un Gateway Socket.io con cors abilitato per il frontend
@WebSocketGateway({
  cors: {
    origin: '*',
  },
})
export class ChecklistGateway {
  // Iniettiamo il server Socket.io globale e il nostro ChecklistService per poter salvare su DB
  @WebSocketServer()
  server!: Server;

  constructor(private readonly checklistService: ChecklistService) {}

  /**
   * EVENTO: UN CLIENT ENTRA NELLA STANZA DELLA CHECKLIST
   * Quando il cameriere apre la schermata della checklist, l'app si connette a una "room" specifica per quella giornata.
   */
  @SubscribeMessage('join_checklist')
  handleJoinChecklist(
    @MessageBody() data: { instanceId: string },
    @ConnectedSocket() client: Socket,
  ) {
    // Facciamo unire il socket del client alla stanza dedicata (es. "checklist_uuid-dell-istanza")
    const roomName = `checklist_${data.instanceId}`;
    client.join(roomName);
    console.log(`📱 Client ${client.id} è entrato nella stanza: ${roomName}`);
  }

  /**
   * EVENTO: UN CAMERIERE METTE O TOGLIE UNA SPUNTA
   * Quando l'utente fa Tap su un task, l'app manda questo evento al server.
   */
  @SubscribeMessage('update_task')
  async handleUpdateTask(
    @MessageBody() data: {
      instanceId: string;
      taskTemplateId: string;
      employeeId: string;
      value: string;
    },
  ) {
    // 1. SALHIAMO SUBITO SU DATABASE (Persistenza sicura, niente va perso se chiudi l'app)
    const savedResult = await this.checklistService.saveTaskResult(
      data.instanceId,
      data.taskTemplateId,
      data.employeeId,
      data.value,
    );

    // 2. SPARIAMO L'EVENTO IN TEMPO REALE A TUTTI I COLLEGATI NELLA STESSA STANZA
    // In questo modo il collega che sta dall'altra parte della sala vede la spunta accendersi in 10ms
    const roomName = `checklist_${data.instanceId}`;
    this.server.to(roomName).emit('task_updated', savedResult);
  }
}