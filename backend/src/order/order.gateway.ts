// backend/src/order/order.gateway.ts

import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

// Abilitiamo il CORS così il frontend Flutter (e Chrome!) potrà connettersi senza blocchi
@WebSocketGateway({ cors: { origin: '*' } })
export class OrderGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  // Quando un dispositivo apre l'app
  handleConnection(client: Socket) {
    console.log(`🟢 Client connesso al WebSocket: ${client.id}`);
  }

  // Quando un dispositivo chiude l'app
  handleDisconnect(client: Socket) {
    console.log(`🔴 Client disconnesso: ${client.id}`);
  }

  // 🏠 LA STANZA: Il telefono appena si connette dice "Io sono del ristorante X"
  @SubscribeMessage('joinRoom')
  handleJoinRoom(client: Socket, tenantId: string) {
    client.join(tenantId);
    console.log(`🏠 Client ${client.id} è entrato nella stanza del ristorante: ${tenantId}`);
  }

  // 📣 EVENTO 1: Un cameriere ha preso un NUOVO ordine
  sendNewOrderNotification(tenantId: string, order: any) {
    this.server.to(tenantId).emit('order_created', order);
    console.log(`⚡ WebSocket: Segnale 'order_created' inviato alla stanza ${tenantId}`);
  }

  // 📣 EVENTO 2: La cassa ha PAGATO un ordine (o la cucina ha cambiato stato)
  sendOrderUpdate(tenantId: string, order: any) {
    this.server.to(tenantId).emit('order_updated', order);
    console.log(`⚡ WebSocket: Segnale 'order_updated' inviato alla stanza ${tenantId} per l'ordine ${order.id}`);
  }
}