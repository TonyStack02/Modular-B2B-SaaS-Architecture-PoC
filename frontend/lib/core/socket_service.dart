// lib/core/socket_service.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

// Importiamo i controller che dovremo svegliare
import '../features/orders/presentation/order_controller.dart';
import '../features/floor_plan/presentation/floor_plan_controller.dart';

// Esponiamo la nostra Antenna a tutta l'app
final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService(ref);
  
  // Se l'app si chiude, spegniamo l'antenna per non consumare batteria a vuoto
  ref.onDispose(() => service.disconnect());
  
  return service;
});

class SocketService {
  final Ref ref;
  io.Socket? _socket;

  SocketService(this.ref);

  // Accendiamo l'antenna e sintonizziamoci sul canale del nostro Ristorante (tenantId)
  void connect(String tenantId) {
    if (_socket != null && _socket!.connected) return; // Già connessi!

    // 🚨 NOTA BENE: Usa 'http://localhost:3000' se sei su Chrome.
    // Quando passerai al telefono/tablet, rimetti il tuo IP (es. 10.41.0.25)
    _socket = io.io('http://localhost:3000', io.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect() // Lo facciamo partire noi manualmente
        .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      print('🟢 WebSocket: Connessione stabilita con il Server!');
      // Appena agganciato il server, gli urliamo: "Ehi, fammi entrare nella stanza del mio ristorante!"
      _socket!.emit('joinRoom', tenantId);
    });

    // ------------------------------------------------------------------
    // 👂 L'ORECCHIO MAGICO: COSA FACCIAMO QUANDO SENTIAMO UN URLO?
    // ------------------------------------------------------------------

    _socket!.on('order_created', (data) {
      print('⚡ WebSocket: Ho sentito un order_created! Aggiorno la Mappa...');
      _svegliaIController();
    });

    _socket!.on('order_updated', (data) {
      print('⚡ WebSocket: Ho sentito un order_updated! Aggiorno la Cassa...');
      _svegliaIController();
    });

    _socket!.onDisconnect((_) => print('🔴 WebSocket: Disconnesso'));
  }

  // La funzione che preme il tasto "Aggiorna" al posto tuo!
  void _svegliaIController() {
    // ref.invalidate() dice a Riverpod: "I dati che hai in memoria sono vecchi, riscaricali!"
    // E visto che la grafica sta "guardando" (watch) questi provider, lo schermo si aggiornerà da solo.
    ref.invalidate(orderControllerProvider);
    ref.invalidate(floorPlanControllerProvider);
  }

  void disconnect() {
    _socket?.disconnect();
  }
}