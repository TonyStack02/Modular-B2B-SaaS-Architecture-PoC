# ⚡ Modulo Ordini e Comunicazione Real-Time (Order)

Questo modulo gestisce il flusso operativo, finanziario e logistico delle comande e delle vendite all'interno di Juicy. Oltre alle tradizionali operazioni di database (CRUD), implementa un'architettura **WebSocket (Socket.io)** per spingere gli aggiornamenti di stato in tempo reale su tutti i dispositivi connessi dello stesso tenant e aggiorna in modo automatizzato le metriche del CRM.

## 🗂️ Struttura dei File

Il modulo è il più interconnesso del sistema ed è composto da:

* **`order.module.ts`**: L'hub del reparto vendite. Registra controller, servizi e il gateway di rete, esportando questi ultimi per consentire ad altri moduli (come il modulo `guest`) di inviare notifiche.
* **`dto/update-order-status.dto.ts`**: Il controllore di stato. Convalida che i cambi di stato rispettino il ciclo di vita approvato e accetta l'ID del cliente per la chiusura dei conti.
* **`order.controller.ts`**: L'interfaccia REST. Espone le rotte per consultare gli ordini, modificare gli stati ed erogare i dati immediati alla dashboard dell'iPad.
* **`order.gateway.ts`**: L'antenna real-time. Gestisce la persistenza delle connessioni Socket.io e la segmentazione dei dispositivi in "stanze" aziendali isolate.
* **`order.service.ts`**: Il cervello contabile e automatore. Calcola le transazioni finanziarie, esegue l'aggregazione dei ricavi odierni e aggiorna i saldi storici nel CRM dei clienti.

---

## 🔍 Dettaglio dei Componenti e dei File

### 1. Il Validatore del Ciclo di Vita (DTO)
* **`update-order-status.dto.ts`**: Sfrutta il decoratore `@IsEnum(OrderStatus)` collegato direttamente alle definizioni del database di Prisma. Impedisce stati arbitrari, accettando rigorosamente solo la sequenza: `PENDING`, `PREPARING`, `SERVED`, `PAID`, `CANCELLED`. Contiene il campo opzionale `customerId` utile in fase di checkout.

### 2. `order.gateway.ts` (L'Architettura dei WebSockets)
Gestisce i canali di streaming asincrono bidirezionale senza blocchi HTTP ed abilita il CORS (`*`) per dialogare nativamente con l'app Flutter sia su dispositivi mobili che su Chrome.
* **`handleConnection` / `handleDisconnect`**: Monitorano l'aggancio e lo sgancio fisico dei tablet dalla rete stampando i log di sistema.
* **`joinRoom` (`@SubscribeMessage`)**: Logica di isolamento multi-tenant fondamentale. Appena l'iPad effettua il boot, si iscrive a un canale esclusivo identificato dal suo `tenantId` (`client.join(tenantId)`). Il server segmenta il traffico: i messaggi viaggeranno solo a compartimenti stagni.
* **`sendNewOrderNotification` / `sendOrderUpdate`**: Funzionano come i megafoni di sistema. Utilizzano l'istruzione `this.server.to(tenantId).emit(...)` per irradiare l'evento (`order_created` o `order_updated`) esclusivamente ai dispositivi presenti in quella stanza tenant.

### 3. `order.controller.ts` (L'Interfaccia REST e Parallelismo)
Protetto integralmente da `JwtAuthGuard`. 
* **`GET /order/stats` (Iniezione Dashboard)**: Risponde istantaneamente alla Home di Flutter. Esegue in parallelo tramite `Promise.all` le query di fatturato giornaliero e conteggio comande aperte, riducendo i tempi di latenza di rete e restituendo la struttura esatta attesa dal modello Dart.
* **`GET /order`**: Restituisce lo storico degli ordini del locale.
* **`PATCH /order/:id/status`**: Innesca la mutazione di stato logistica o la chiusura fiscale dell'ordine.

### 4. `order.service.ts` (La Business Logic & Automazioni CRM)
Interagisce intensamente con PostgreSQL gestendo transazioni matematiche e statistiche:

* **`findAll`**: Scarica gli ordini del tenant in ordine decrescente (`createdAt: 'desc'`), includendo la risorsa fisica di posizionamento (`resource`) e l'array nidificato di tutti i prodotti inclusi nelle righe scontrino (`items.product`).
* **`updateStatus` (Il Liquidatore Finanziario)**:
  Quando lo stato inviato dall'iPad è `PAID`, scattano tre automazioni atomiche:
  1. *Il Ricalcolo Blindato:* Esegue un ciclo `reduce` sull'array dei prodotti acquistati, moltiplicando la quantità per l'importo storico memorizzato (`unitPrice`), blindando il totale reale sul server.
  2. *L'Aggiornamento Temporale:* Fissa la colonna `closedAt` all'esatto timestamp corrente.
  3. *L'Iniezione CRM:* Se all'ordine è abbinato un `customerId`, effettua una query di aggiornamento incrementale sulla tabella `customer`. Utilizza le istruzioni atomiche di Prisma `{ increment: 1 }` e `{ increment: finalTotal }` per aggiornare lo storico del fatturato generato da quel cliente in totale sicurezza transazionale.
  4. *Il Trigger Real-Time:* Chiama l'antenna WebSocket per notificare all'istante la chiusura del tavolo a tutti i tablet del locale.
* **`getTodayIncome`**: Sfrutta le funzioni di aggregazione native del database (`this.prisma.order.aggregate`) eseguendo una `_sum` sulla colonna `totalAmount` degli ordini pagati compresi tra le ore `00:00:00.000` e le `23:59:59.999` di oggi.

---

## 🚦 Flusso Operativo Real-Time in Movimento