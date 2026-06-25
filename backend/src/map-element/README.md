# 📐 Modulo Elementi Mappa (MapElement)

Questo modulo gestisce i componenti strutturali e architettonici fissi della planimetria del locale (come muri, porte, finestre e banconi). Consente al frontend (Flutter) di salvare e ripristinare il layout geometrico vettoriale dello spazio fisico in modalità multi-tenant.

## 🗂️ Struttura dei File

Il modulo è strutturato in modo snello per gestire flussi CRUD ad alta frequenza (coordinati con i movimenti dell'utente sullo schermo):

* **`map-element.module.ts`**: Registra il modulo e inietta i servizi di persistenza (`MapElementService` e `PrismaService`).
* **`dto/create-map-element.dto.ts`**: Il controllore vettoriale. Valida che tutte le coordinate spaziali siano numeri e che i campi obbligatori siano formattati bene.
* **`dto/update-map-element.dto.ts`**: Estende il DTO di creazione per supportare aggiornamenti flessibili e parziali delle proprietà dell'oggetto.
* **`map-element.controller.ts`**: Espone gli endpoint per la gestione del layout, blindati dal token JWT di login.
* **`map-element.service.ts`**: L'esecutore geometrico. Scrive, legge ed elimina i vettori 2D sul database PostgreSQL.

---

## 🔍 Dettaglio dei Componenti e dei File

### 1. I Validatori Spaziali (DTOs)
* **`create-map-element.dto.ts`**: Mappa la fisica bidimensionale dell'oggetto sul database:
  * `type`: Una stringa obbligatoria che identifica la natura del blocco (es. `WALL`, `DOOR`, `WINDOW`).
  * `text`: Un testo opzionale (es. per scrivere "Uscita di Sicurezza" o il nome di una zona).
  * `positionX` & `positionY`: Coordinate cartesiane assolute del punto di origine dell'oggetto sulla griglia.
  * `width` & `height`: Dimensioni spaziali del rettangolo di collisione dell'elemento.
  * `rotation`: Angolo opzionale di rotazione in gradi dell'elemento (fondamentale per i muri obliqui).
* **`update-map-element.dto.ts`**: Sfrutta `PartialType`. Permette all'iPad di inviare anche solo le nuove coordinate `positionX` e `positionY` quando l'utente sposta un elemento, lasciando intatti larghezza, altezza e tipo sul database.

### 2. `map-element.controller.ts`
Interamente protetto da `JwtAuthGuard`. 
* **`POST /map-element`**: Riceve le geometrie iniziali del nuovo elemento e le assegna al `tenantId` estratto in background dal token crittografato dell'utente.
* **`GET /map-element`**: Scarica l'intero scheletro architettonico filtrando rigorosamente per il `tenantId` corrente. In questo modo, l'iPad carica solo la planimetria del proprio locale.
* **`PATCH /map-element/:id`**: Aggiorna le proprietà dell'elemento (es. quando l'utente finisce l'operazione di ridimensionamento o drag&drop).
* **`DELETE /map-element/:id`**: Elimina definitivamente l'elemento strutturale se l'utente lo trascina nel cestino dell'editor.

### 3. `map-element.service.ts` (La Business Logic Vettoriale)
Interagisce con PostgreSQL tramite Prisma per archiviare i dati di posizionamento:
* **`create`**: Esegue lo scompattamento del DTO (`...dto`) e lo blinda associandogli il `tenantId` aziendale.
* **`findAll`**: Recupera tutti gli elementi strutturali utili a ridisegnare la mappa del locale specifico.
* **`update`**: Modifica il record basandosi sull'ID univoco dell'elemento.
* **`remove`**: Esegue l'eliminazione fisica della riga del database.

---

## 🎁 Struttura Dati di Interscambio con Flutter

Quando l'app richiede la planimetria, riceve un array di oggetti geometrici pronti per essere renderizzati in un `CustomPainter` o in un sistema di widget posizionati (`Positioned`) in Flutter:

```json
[
  {
    "id": "uuid-elemento-muro-1",
    "type": "WALL",
    "text": null,
    "positionX": 120.50,
    "positionY": 340.00,
    "width": 200.00,
    "height": 15.00,
    "rotation": 90.00,
    "tenantId": "uuid-tenant-1"
  }
]