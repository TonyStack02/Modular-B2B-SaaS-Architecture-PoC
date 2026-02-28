// backend/src/order/order.gateway.ts

import {
    WebSocketGateway,
    WebSocketServer,
    SubscribeMessage,
    OnGatewayConnection,
    OnGatewayDisconnect
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

// Abilitiamo il CORS così il frontend Flutter potrà connettersi senza blocchi
@WebSocketGateway ({cors: { origin: '*'}})
export class OrderGateway implements OnGatewayConnection, OnGatewayDisconnect {
    @WebSocketServer()
    server: Server;

    // Quando un Owner si connette (es. Mario apre la Dashboard)
    handleConnection(client: Socket) {
        console.log (`Client connesso: ${client.id}`);
    }

    handleDisconnect(client: Socket) {
        console.log (`Client disconnesso: ${client.id}`);
    }

    // Mario "entra" in una stanza basata sul suo tenantId
    @SubscribeMessage('joinRoom')
    handleJoinRoom (client: Socket, tenantId: string) {
        client.join (tenantId);
        console.log (`Client ${client.id} si è unito nella stanza del ristorante: ${tenantId}`);
    }

    // Funzione che useremo per inviare la notifica di un nuovo ordine
    sendNewOrderNotification (tenantId: string, order: any) {
        this.server.to(tenantId).emit('newOrder', order);
    }
}