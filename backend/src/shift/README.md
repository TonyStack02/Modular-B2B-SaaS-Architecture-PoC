# 📅 Modulo Gestione Turni (Shift)

Questo modulo gestisce la pianificazione oraria, il tabellone dei turni e il monitoraggio delle ore lavorative del personale dipendente di Juicy in modalità multi-tenant. Si integra direttamente con il modulo `Employee` per incrociare le metriche di costo del lavoro.

## 🗂️ Struttura dei File

Il modulo rispetta l'architettura a tre strati standard di NestJS:

* **`shift.module.ts`**: L'interruttore del modulo. Registra il controller e provvede a iniettare i servizi di business e di database (`ShiftService` e `PrismaService`).
* **`dto/create-shift.dto.ts`**: Il controllore dei tempi. Convalida che gli orari di inizio e fine arrivino in formato data ISO standard e che il dipendente associato esista tramite UUID.
* **`dto/update-shift.dto.ts`**: Estende le regole di creazione tramite `PartialType` per consentire modifiche parziali (es. lo spostamento d'orario di un singolo turno).
* **`shift.controller.ts`**: Il varco protetto. Riceve le chiamate REST, gestisce i parametri di filtro temporale nell'URL ed estrae il `tenantId` dal JWT.
* **`shift.service.ts`**: L'esecutore analitico. Filtra i turni in base ai range temporali richieste dall'iPad ed esegue l'arricchimento relazionale dei dati finanziari.

---

## 🔍 Dettaglio dei Componenti e dei File

### 1. I Validatori di Allocazione (DTOs)
* **`create-shift.dto.ts`**: Regola l'input proveniente dal frontend:
  * `employeeId`: Stringa in formato `@IsUUID()` che punta alla scheda del personale.
  * `startTime` e `endTime`: Stringhe in formato `@IsDateString()` (devono includere lo standard ISO con la Z finale per evitare disallineamenti di fuso orario tra tablet e server).
  * `notes`: Stringa opzionale per inserire mansioni specifiche del turno (es: "Turno spezzato - Chiusura cassa").

### 2. `shift.controller.ts`
Interamente protetto da `JwtAuthGuard`. 
* **`POST /shift`**: Inserisce un turno a tabellone legandolo al locale del gestore loggato.
* **`GET /shift`**: Recupera i turni. Accetta due parametri opzionali di query nell'URL (`@Query('start')` e `@Query('end')`), permettendo a Flutter di scaricare solo la settimana o il mese corretto che l'utente sta visualizzando sullo schermo.
* **`DELETE /shift/:id`**: Rimuove un turno dal calendario passando l'ID e il `tenantId` di sicurezza.

### 3. `shift.service.ts` (La Business Logic Finanziaria)
Comunica con PostgreSQL tramite Prisma implementando query ottimizzate ad arricchimento relazionale:

* **Il Filtro Dinamico del Periodo (`findAll`)**
  Il metodo applica una clausola `where` dinamica sfruttando l'operatore spread sulle condizioni (`...()`). Se l'iPad passa i parametri `start` e `end`, il server converte le stringhe in oggetti data nativi e applica i filtri `gte` (maggiore o uguale) e `lte` (minore o uguale) sulla timeline del DB. Se non vengono passati parametri, scarica lo storico globale del tenant.

* **La Join selettiva ad alto rendimento (`include`)**
  Sia in fase di creazione che di lettura, il servizio implementa un'ottimizzazione fondamentale per il controllo dei costi (Labor Cost Control):
  Tramite il blocco `include: { employee: { select: { ... } } }`, il database non estrae tutti i dati sensibili del dipendente (come codice fiscale, pin o indirizzo), ma seleziona chirurgicamente solo `firstName`, `lastName`, `jobRole` e soprattutto **`hourlyWage`** (la paga oraria).

---

## 🎁 Struttura del JSON Restituito a Flutter (Pronto per i Calcoli)

L'iPad riceve un payload arricchito che permette al frontend di stampare il nome del dipendente sul calendario dei turni e calcolare i costi aziendali senza fare calcoli pesanti o richieste di rete aggiuntive:

```json
[
  {
    "id": "uuid-turno-1",
    "employeeId": "uuid-dipendente-mario",
    "startTime": "2026-06-25T08:00:00.000Z",
    "endTime": "2026-06-25T16:00:00.000Z",
    "notes": "Turno Mattina Cucina",
    "tenantId": "uuid-tenant-locale",
    "employee": {
      "firstName": "Mario",
      "lastName": "Rossi",
      "hourlyWage": 12.50,
      "jobRole": "Cuoco"
    }
  }
]