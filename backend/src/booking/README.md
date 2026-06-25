# 📅 Modulo Prenotazioni e Calendario (Booking)

Questo modulo gestisce l'intero ciclo di vita degli appuntamenti e delle prenotazioni all'interno di Juicy. È il motore dietro la schermata del Calendario del frontend e si collega direttamente al CRM (`Customer`) e alle risorse fisiche (`Resource`, come i tavoli o le poltrone) in modalità multi-tenant.

## 🗂️ Struttura dei File

Il modulo segue l'architettura a strati ed è composto da:

* **`booking.module.ts`**: Configura il modulo iniettando il controller e i servizi necessari.
* **`dto/create-booking.dto.ts`**: Convalida i dati inviati dall'app quando si prende un appuntamento (data, ospiti, nome, telefono e risorsa opzionale).
* **`dto/update-booking.dto.ts`**: Estende il DTO di creazione rendendo tutti i campi opzionali (`PartialType`) e aggiunge lo stato per gestire le cancellazioni.
* **`booking.controller.ts`**: Espone le rotte per inserire, filtrare e modificare le prenotazioni, blindato dal buttafuori di sicurezza JWT.
* **`booking.service.ts`**: Il nucleo operativo. Contiene l'automazione di sincronizzazione con il CRM e il calcolo matematico dei range mensili.

---

## 🔍 Dettaglio dei Componenti e dei File

### 1. I Moduli di Convalida (DTOs)
* **`create-booking.dto.ts`**: Protegge il database esigendo dati puliti. `@IsDateString()` si assicura che l'orario sia in formato ISO standard. `@Min(1)` impedisce di salvare prenotazioni con zero o meno ospiti. Il campo `resourceId` (l'ID del tavolo) è un UUID opzionale, utile se si vuole assegnare subito un posto o lasciarlo libero.
* **`update-booking.dto.ts`**: Permette modifiche parziali (es. spostare solo l'orario o cambiare il numero di persone) e introduce il campo `status` per gestire logiche come `CANCELLED`.

### 2. `booking.controller.ts`
Interamente protetto da `@UseGuards(JwtAuthGuard)`. Estrae il `tenantId` da ogni richiesta per isolare i dati.
* **`POST /booking`**: Riceve il DTO e avvia la creazione della prenotazione.
* **`GET /booking/month/:year/:month`**: Riceve l'anno e il mese dall'URL come stringhe, esegue il parsing in numeri interi (`parseInt`) e chiama il filtro mensile.
* **`PATCH /booking/:id`**: Modifica una prenotazione esistente (o la cancella modificandone lo stato).

### 3. `booking.service.ts` (La Business Logic)
Qui dentro ci sono le due automazioni più importanti del modulo:

* **Il Ponte Magico con il CRM (`create`)**
  Quando arriva una prenotazione con un numero di telefono (`customerPhone`), il servizio fa un controllo incrociato:
  1. Cerca nella tabella `customer` se esiste già quel telefono per quel `tenantId`.
  2. **Se esiste:** Recupera l'ID del cliente esistente e lo associa alla prenotazione.
  3. **Se NON esiste:** Crea automaticamente una nuova scheda cliente nel CRM salvando nome e telefono, e poi aggancia il nuovo ID generato.
  Infine, salva la prenotazione impostando lo stato di default su `CONFIRMED`.

* **Il Calcolatore del Mese (`findByMonth`)**
  Per evitare di scaricare migliaia di prenotazioni storiche appesantendo l'iPad, questa funzione isola i dati:
  1. Prende il mese (es. 3 per Marzo) e calcola la data di inizio (`startDate` al giorno 1). *Nota: Sottrae 1 perché in JavaScript i mesi partono da 0.*
  2. Crea la data di fine (`endDate`) impostando il giorno a `0` del mese successivo, che restituisce matematicamente l'ultimo giorno del mese richiesto, fissando l'orario alle `23:59:59.999`.
  3. Esegue una `findMany` includendo i dettagli della risorsa/tavolo associata (`include: { resource: true }`) e ordina tutto in ordine cronologico ascendente.

* **La Modifica Protetta (`update`)**
  Prima di eseguire l'aggiornamento, fa una query preventiva `findFirst` usando la combinazione `id` + `tenantId`. Se un utente prova a modificare una prenotazione di un altro locale tramite codice, il sistema lancia una `NotFoundException`, bloccando l'attacco.

---

## 🚦 Rotte API Esposte

Tutte le rotte richiedono l'Header `Authorization: Bearer <JWT_TOKEN>`.

| Metodo | Rotta | Descrizione |
| :--- | :--- | :--- |
| **POST** | `/booking` | Crea una prenotazione ed eventualmente un nuovo cliente nel CRM. |
| **GET** | `/booking/month/:year/:month` | Recupera solo le prenotazioni dell'anno/mese specificato. |
| **PATCH** | `/booking/:id` | Aggiorna i dettagli o annulla lo stato di una prenotazione. |