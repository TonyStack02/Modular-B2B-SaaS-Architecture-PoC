# 💳 Modulo Pagamenti Digitali (Stripe)

Questo modulo gestisce l'integrazione con la piattaforma di pagamento **Stripe**, consentendo ai clienti finali di saldare i conti (ordini o prenotazioni) in totale sicurezza tramite carte di credito, Apple Pay o Google Pay. Implementa un'architettura asincrona basata su **Webhook** per la riconciliazione automatica dello stato dei pagamenti.

## 🗂️ Struttura dei File

Il modulo è strutturato per gestire l'avvio delle transazioni protette e la ricezione di eventi pubblici asincroni inviati da Stripe:

* **`stripe.module.ts`**: L'hub dei pagamenti. Importa `OrderModule` per consentire al sistema di alterare lo stato delle comande al saldo del conto.
* **`dto/create-payment.dto.ts`**: Il controllore finanziario in ingresso. Valida che l'importo inviato sia un numero positivo e che sia associato a un ID d'ordine valido.
* **`stripe.controller.ts`**: Espone sia la rotta protetta per inizializzare la transazione, sia la rotta pubblica di ascolto dei server di Stripe (Webhook).
* **`stripe.service.ts`**: L'interfaccia crittografica con l'SDK ufficiale di Stripe. Gestisce l'inizializzazione del gateway finanziario e la decifratura delle firme digitali.

---

## 🔍 Dettaglio dei Componenti e dei File

### 1. Il Validatore Finanziario (DTO)
* **`create-payment.dto.ts`**: Sfrutta `@IsNumber()` e `@IsPositive()` per blindare il campo `amount`, impedendo l'invio di importi negativi o nulli. Richiede obbligatoriamente l'UUID dell'ordine (`orderId`) da saldare.

### 2. `stripe.service.ts` (L'Integrazione SDK)
Inietta le chiavi di sicurezza prelevate dal file `.env` ed esegue i controlli di configurazione all'avvio:
* **Inizializzazione**: Controlla la presenza di `STRIPE_SECRET_KEY`. Configura l'istanza ufficiale dell'SDK bloccando la versione API stabile (`2026-02-25.clover`).
* **`createPaymentIntent`**: Riceve l'importo in formato decimale (es: `15.50`) e implementa la conversione obbligatoria in centesimi interi richiesta da Stripe tramite `Math.round(amount * 100)` (es: `1550`). Configura i metodi di pagamento automatici e inserisce l'ID della comanda nei `metadata`. Questo blocco funziona come un "post-it immutabile" che viaggerà sui server di Stripe.
* **`verifyWebHook`**: Recupera lo `STRIPE_WEBHOOK_SECRET` dal `.env`. Sfrutta la funzione crittografica dell'SDK `stripe.webhooks.constructEvent` confrontando il corpo grezzo della richiesta (`Buffer`) con la firma digitale presente negli Header HTTP per garantire l'autenticità del messaggio.

### 3. `stripe.controller.ts` (Il Gestore dei Flussi)
Presenta una configurazione mista di sicurezza (Endpoint protetti ed Endpoint pubblici):

* **`POST /stripe/create-intent` (Protetto)**
  Blindato da `JwtAuthGuard`. Viene chiamato dall'app quando l'utente clicca su "Paga ora". Richiede il `client_secret` a Stripe e lo restituisce a Flutter, permettendo al tablet o allo smartphone di visualizzare il foglio di pagamento nativo.
* **`POST /stripe/webhook` (Pubblico)**
  Non presenta la guardia JWT poiché viene invocato direttamente dai server di Stripe. Implementa la logica asincrona di riconciliazione:
  1. Intercetta gli Header `stripe-signature` e la proprietà `req.rawBody` (corpo grezzo non modificato).
  2. Invia i dati al servizio di verifica crittografica. Se la firma non corrisponde, lancia un `BadRequestException`, respingendo l'attacco.
  3. **Il Riconciliatore di Stato:** Se Stripe conferma l'evento `payment_intent.succeeded` (pagamento andato a buon fine), il controller estrae l'`orderId` memorizzato inizialmente nei `metadata`. 
  4. **L'Aggiornamento del Database:** Invoca il metodo `markAsPaid(orderId)` del modulo ordini (`OrderService`), che provvede a impostare lo stato della comanda su `PAID`, calcolare i totali storici nel CRM e notificare i tablet del locale in tempo reale tramite WebSockets.

---

## 🚦 Diagramma del Flusso di Pagamento Asincrono