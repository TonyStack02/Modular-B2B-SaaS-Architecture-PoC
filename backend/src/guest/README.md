# 🌐 Modulo Clienti Pubblici (Guest)

Questo modulo gestisce l'interfaccia pubblica di Juicy, consentendo ai clienti finali sprovvisti di account di interagire direttamente con il locale (es. ordinando tramite QR code dall'ombrellone/tavolo o effettuando una prenotazione autonoma). Essendo un modulo pubblico, **non richiede l'autenticazione JWT** per le sue rotte.

## 🗂️ Struttura dei File

Il modulo è strutturato per gestire richieste pubbliche e integrarsi in tempo reale con i moduli interni:

* **`guest.module.ts`**: Configura il modulo importando `OrderModule` per avere accesso ai canali di comunicazione in tempo reale (WebSockets).
* **`dto/create-booking.dto.ts`**: Valida i dati della prenotazione inseriti autonomamente dal cliente.
* **`dto/create-order.dto.ts`**: Gestisce la struttura complessa del carrello dell'ordine pubblico, incluse le note personalizzate per ogni piatto/prodotto.
* **`guest.controller.ts`**: Espone gli endpoint pubblici per la lettura del menu, delle risorse e per l'invio di ordini e prenotazioni.
* **`guest.service.ts`**: Il motore di elaborazione sicuro. Calcola i prezzi reali lato server per evitare manomissioni e notifica lo staff in tempo reale.

---

## 🔍 Dettaglio dei Componenti e dei File

### 1. I Moduli di Convalida e Carrello (DTOs)
* **`create-booking.dto.ts`**: Richiede esplicitamente il `tenantId` (per capire in quale locale si sta prenotando), data/ora, numero di ospiti e i dati di contatto del cliente.
* **`create-order.dto.ts`**: Utilizza una convalida nidificata avanzata. La classe principale si assicura che arrivino il `tenantId` e il `resourceId` (il tavolo/ombrellone fisico). Tramite i decoratori `@ValidateNested({ each: true })` e `@Type(() => OrderItemDto)`, obbliga ogni singolo elemento del carrello (`items`) a verificare che l'ID del prodotto sia un UUID valido, che la quantità sia almeno 1 (`@Min(1)`) e accetta stringhe di testo opzionali per le varianti o richieste speciali (`notes`, es: "Senza ghiaccio" o "Salsa a parte").

### 2. `guest.controller.ts`
Espone le rotte pubbliche sotto il prefisso `/guest`. Non presenta la `JwtAuthGuard` perché deve essere accessibile da qualsiasi smartphone che scansiona un QR code. Riceve il `tenantId` (chiamato `id` nei parametri dell'URL) per indirizzare la richiesta al business corretto.

### 3. `guest.service.ts` (Business Logic Pubblica e Sicurezza)
Interagisce con il database e con lo strato di rete WebSocket implementando logiche protettive cruciali:

* **`getRestaurantMenu`**: Recupera l'albero completo del menu del locale filtrando per `tenantId`, includendo tutte le categorie e, dentro di esse, tutti i prodotti attivi in un'unica transazione.
* **`getRestaurantResources`**: Recupera le aree del locale (es: "Spiaggia Zona A") e vi include dentro lo stato dei tavoli/ombrelloni (`resources`).
* **`createOrder` (Il Calcolatore Blindato)**:
  Per impedire frodi o manomissioni dei prezzi da parte di client modificati, il servizio implementa un flusso di sicurezza rigido:
  1. Estrae esclusivamente gli ID dei prodotti inviati nel carrello e fa una query strutturata `where: { id: { in: productIds } }` per prelevare il listino prezzi ufficiale e immutabile dal database.
  2. Esegue un ciclo di mappatura in cui calcola il totale progressivo (`calculatedTotal`) moltiplicando il prezzo ufficiale del DB per la quantità richiesta dall'utente.
  3. Salva lo storico del prezzo di vendita in `unitPrice` (così se il gestore cambia i prezzi il giorno dopo, lo scontrino storico non viene alterato).
  4. Crea il record dell'ordine in stato `OPEN` e inserisce le righe di dettaglio (`OrderItem`) incluse le note di preparazione.
  5. **La Notifica Real-Time (`orderGateway`):** Chiama il metodo `sendNewOrderNotification` del gateway WebSocket. Questo agisce come un megafono aziendale, sparando l'ordine sugli iPad del personale loggato in quel tenant. La mappa dei tavoli si aggiorna istantaneamente senza costringere il personale a ricaricare la pagina.

---

## 🚦 Rotte API Esposte Pubblicamente

Nessuna rotta richiede token di autenticazione. Il `tenantId` deve essere passato nei parametri o nel corpo del JSON.

| Metodo | Rotta | Descrizione |
| :--- | :--- | :--- |
| **GET** | `/guest/:id/menu` | Scarica il menu digitale completo del locale specificato. |
| **GET** | `/guest/:id/resources` | Scarica la mappa degli spazi e dei tavoli/ombrelloni del locale. |
| **POST** | `/guest/booking` | Invia una richiesta di prenotazione autonoma da parte di un cliente. |
| **POST** | `/guest/order` | Invia un ordine dal tavolo/QR, calcola il totale sicuro e avvisa lo staff in tempo reale. |