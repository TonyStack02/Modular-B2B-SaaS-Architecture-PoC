# 🪑 Modulo Risorse Operative (Resource)

Questo modulo gestisce le entità dinamiche e interattive del locale (es. "Tavolo 5", "Ombrellone 21", "Poltrona Barber 1"). A differenza degli elementi strutturali fissi (`MapElement`), le risorse sono collegate direttamente al flusso di business: contengono ordini, ospitano clienti e sono l'oggetto fisico associato a prenotazioni e appuntamenti.

## 🗂️ Struttura dei File

Il modulo segue l'architettura gerarchica multi-tenant di Juicy ed è composto da:

* **`resource.module.ts`**: L'orchestratore del modulo che inietta il controller e i servizi necessari.
* **`dto/create-resource.dto.ts`**: Il guardiano di inserimento. Verifica la validità del nome e che l'area associata sia espressa in formato UUID valido.
* **`dto/update-resource.dto.ts`**: Il controllore dei movimenti. Rende opzionali i parametri per consentire l'aggiornamento rapido e leggero delle sole coordinate cartesiane.
* **`resource.controller.ts`**: Gestisce gli endpoint protetti da token JWT, estraendo le informazioni sull'identità aziendale.
* **`resource.service.ts`**: Il nucleo logico. Esegue controlli incrociati relazionali tra aree e risorse prima di effettuare scritture su PostgreSQL.

---

## 🔍 Dettaglio dei Componenti e dei File

### 1. I Moduli di Convalida (DTOs)
* **`create-resource.dto.ts`**: Impedisce stringhe vuote per il campo `name` e impone tramite `@IsUUID('4')` che il puntatore all'area di appartenenza (`areaId`) sia una chiave esterna formalmente corretta.
* **`update-resource.dto.ts`**: Accetta in modo facoltativo (`@IsOptional()`) il nome modificato o i valori decimali delle posizioni pixel sullo schermo dell'iPad (`positionX`, `positionY`).

### 2. `resource.controller.ts`
Interamente protetto da `JwtAuthGuard`. 
* **`POST /resource`**: Estrae il `tenantId` dal badge JWT dell'utente loggato e lo passa al servizio per vincolare la risorsa al corretto account aziendale.
* **`GET /resource`**: Restituisce la lista di tutte le postazioni del locale.
* **`PATCH /resource/:id`**: Riceve le nuove coordinate cartesiane o variazioni di nome e le applica sul database. *(Nota di Refactoring: integrare il passaggio di `req.user.tenantId` per blindare l'endpoint da attacchi cross-tenant).*

### 3. `resource.service.ts` (La Business Logic Interconnessa)
Interagisce con PostgreSQL tramite Prisma implementando logiche protettive relazionali:

* **Il Controllo Incrociato preventivo (`create`)**
  Quando l'iPad tenta di creare una risorsa (es. un tavolo) inserendola in un'area, il backend implementa una difesa cruciale:
  1. Esegue una query `findUnique` sulla tabella `area` usando l'ID fornito dal DTO.
  2. Verifica che l'area esista e che la sua colonna `tenantId` combaci con l'ID dell'azienda che sta compiendo l'azione.
  3. Se il controllo fallisce (tentativo di inserimento in un'area di un altro locale), lancia una `ForbiddenException ('403')` bloccando la transazione. Se ha successo, inserisce la risorsa.

* **La Join Relazionale (`findAll`)**
  Scarica tutte le risorse del locale e, tramite l'istruzione `include: { area: true }`, ordina a Prisma di effettuare una join relazionale per incorporare l'intero oggetto area di appartenenza. Questo permette a Flutter di sapere subito in quale sala o sotto-zona si trova ogni elemento.

* **L'Aggiornamento Selettivo Vettoriale (`update`)**
  Utilizza l'operatore spread condizionale di JavaScript combinato con una verifica di esistenza dello stato (`dto.positionX !== undefined`). Questo schema permette all'app di inviare pacchetti parziali (es. solo la coordinata X se l'utente sta muovendo l'oggetto in linea retta orizzontale) ottimizzando le performance di scrittura sul database.

---

## 🎁 Struttura del JSON di Risposta per Flutter

L'endpoint di lettura restituisce i tavoli/ombrelloni arricchiti dei dati della zona madre:

```json
[
  {
    "id": "uuid-tavolo-12",
    "name": "Tavolo 12",
    "positionX": 450.00,
    "positionY": 210.50,
    "areaId": "uuid-area-terrazza",
    "tenantId": "uuid-tenant-1",
    "area": {
      "id": "uuid-area-terrazza",
      "name": "Terrazza Vista Mare",
      "tenantId": "uuid-tenant-1"
    }
  }
]