# 🗺️ Modulo Area

Questo modulo gestisce la configurazione e la categorizzazione degli spazi fisici all'interno del locale (es. "Sala Principale", "Terrazza", "Giardino"). Serve come raggruppatore logico per le risorse fisiche (come i tavoli) che verranno posizionate all'interno di queste zone.

## 🗂️ Struttura dei File

Il modulo segue l'architettura standard a strati di NestJS ed è composto da:

1. **`area.module.ts`**: La colla del modulo. Registra il controller e i servizi necessari (`AreaService` e `PrismaService`).
2. **`dto/create-area.dto.ts`**: Il controllore di forma. Valida i dati inviati dal frontend quando si tenta di creare una nuova zona.
3. **`area.controller.ts`**: Il posto di blocco. Gestisce gli endpoint HTTP, applica le guardie di sicurezza (autenticazione e controllo dei ruoli) ed estrae i dati dell'utente.
4. **`area.service.ts`**: L'esecutore. Parla con il database PostgreSQL tramite Prisma per salvare, leggere o eliminare i dati in totale sicurezza multi-tenant.

---

## 🔍 Dettaglio dei Componenti e dei File

### 1. `dto/create-area.dto.ts`
Contiene la classe `CreateAreaDto` che valida il corpo della richiesta (`@Body()`) per la creazione di un'area.
* **`name`**: Deve essere obbligatoriamente una stringa e non può essere vuota. Se il frontend sbaglia, i decoratori `@IsNotEmpty` e `@IsString` bloccano la richiesta sul nascere restituendo i messaggi di errore personalizzati in italiano.

### 2. `area.controller.ts`
Questo controller è blindato a livello di classe con `@UseGuards(JwtAuthGuard, RolesGuard)`. Significa che **nessuno** può chiamare queste rotte se non è loggato e se il sistema di controllo ruoli non è attivo.

* **`POST /area` (Creazione)**: Riservata solo all'utente con ruolo `OWNER` (`@Roles(UserRole.OWNER)`). Estrae il `tenantId` dal token dell'utente loggato (`req.user.tenantId`) e passa il nome dell'area al service.
* **`GET /area` (Lettura)**: Accessibile a tutto lo staff loggato (anche camerieri). Recupera l'elenco delle aree filtrando rigorosamente per il `tenantId` estratto dal token, impedendo la fuga di dati tra attività diverse.
* **`DELETE /area/:id` (Eliminazione)**: Riservata solo all'utente con ruolo `OWNER`. Riceve l'ID dell'area come parametro nell'URL e lo passa al service insieme al `tenantId` per i controlli di sicurezza.

### 3. `area.service.ts`
Implementa le transazioni con il database PostgreSQL. Ogni query è agganciata al `tenantId`:

* **`createArea`**: Inserisce una nuova riga nella tabella `area` collegando il nome inviato dall'app al `tenantId` dell'attività corrente.
* **`findAll`**: Restituisce esclusivamente le aree in cui la colonna `tenantId` combacia con quella dell'utente richiedente.
* **`remove` (Cancellazione Sicura)**: Prima di procedere con la cancellazione fisica, esegue una query di controllo `findFirst` verificando che l'ID dell'area e il `tenantId` corrispondano. Se un Owner malizioso cercasse di indovinare l'ID di un'area di un altro locale per cancellarla, il sistema non troverebbe il record e lancerebbe un blocco di sicurezza (`Error`), impedendo l'eliminazione.

---

## 🚦 Rotte API Esposte

Tutte le rotte richiedono l'Header `Authorization: Bearer <JWT_TOKEN>`.

| Metodo | Rotta | Ruolo Richiesto | Descrizione |
| :--- | :--- | :--- | :--- |
| **POST** | `/area` | `OWNER` | Crea una nuova area nel locale corrente. |
| **GET** | `/area` | *Qualsiasi dipendente* | Recupera tutte le aree del locale corrente. |
| **DELETE** | `/area/:id` | `OWNER` | Elimina l'area specificata (previo controllo di possesso). |