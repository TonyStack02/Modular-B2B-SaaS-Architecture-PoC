# 👥 Modulo Personale e Risorse Umane (Employee)

Questo modulo gestisce la gestione dello staff, dei contratti e della conformità legale del personale dipendente di Juicy in modalità multi-tenant. Centralizza le informazioni anagrafiche, i costi aziendali, la gestione dei saldi (ferie/malattia) e le scadenze dei certificati obbligatori.

## 🗂️ Struttura dei File

Il modulo rispetta l'architettura a strati standard di NestJS:

* **`employee.module.ts`**: Registra il controller e i servizi necessari (`EmployeeService` e `PrismaService`).
* **`dto/create-employee.dto.ts`**: La barriera doganale dei dati personali. Convalida la tipologia di ogni campo (stringhe, numeri, date ISO ed ENUM di stato).
* **`dto/update-employee.dto.ts`**: Estende le regole di creazione rendendo ogni parametro facoltativo per supportare le modifiche parziali (es. rinnovo della sola visita medica).
* **`employee.controller.ts`**: Espone il set completo di rotte CRUD, estraendo dal JWT il `tenantId` per proteggere l'accesso.
* **`employee.service.ts`**: L'esecutore delle query su PostgreSQL. Isola e manipola i record del personale in totale sicurezza.

---

## 🔍 Dettaglio dei Componenti e dei File

### 1. Il Validatore di Anagrafica e Scadenze (DTOs)
* **`create-employee.dto.ts`**: Gestisce un modello dati molto ricco diviso in 5 macro-aree:
  * *Anagrafica Base:* Richiede obbligatoriamente `firstName`, `lastName` e il ruolo lavorativo (`jobRole`). Email, telefono e codice fiscale (`taxCode`) sono opzionali.
  * *Scadenze Legali:* Sfrutta `@IsDateString()` per assicurarsi che date critiche come `haccpExpiry` (scadenza attestato alimentare) o `medicalCheckExpiry` (visita medica del lavoro) arrivino in formato standardizzato.
  * *Costi e Orari:* Convalida che la paga oraria (`hourlyWage`) e le ore da contratto (`weeklyContractHours`) siano valori numerici puliti.
  * *Sicurezza e Saldi:* Accetta opzionalmente un `pinCode` (per l'autenticazione rapida sui tablet di cassa) e i contatori di ferie e malattie.
  * *Stato:* Controlla tramite `@IsEnum(EmployeeStatus)` che lo stato del dipendente sia uno dei valori approvati dal database (es. `ACTIVE`, `TERMINATED`).

### 2. `employee.controller.ts`
Interamente protetto da `JwtAuthGuard`. Espone le classiche rotte di gestione del personale passando il `tenantId` estratto in background dal token dell'utente loggato.
* **`POST /employee`**: Inserisce un nuovo dipendente.
* **`GET /employee`**: Mostra l'organigramma aziendale completo del locale.
* **`GET /employee/:id`**: Mostra la scheda dettagliata di un singolo dipendente.
* **`PATCH /employee/:id`**: Aggiorna i dati della scheda dipendente.
* **`DELETE /employee/:id`**: Elimina il record del dipendente dal database.

### 3. `employee.service.ts` (La Business Logic HR)
Comunica con il database tramite Prisma garantendo che nessuna operazione possa scavalcare i confini aziendali del tenant:

* **`create`**: Sfrutta l'operatore di spread (`...dto`) per mappare tutti i campi convalidati e vi inserisce l'identificativo `tenantId`.
* **`findAll`**: Restituisce tutti i dipendenti associati al locale, ordinandoli automaticamente in ordine alfabetico per nome (`orderBy: { firstName: 'asc' }`) per facilitare la consultazione nelle liste su tablet.
* **`update` e `remove` (Sicurezza di Scrittura)**:
  Prisma esegue le query di modifica e cancellazione inserendo nel blocco `where` sia l'ID della risorsa sia il `tenantId` (`where: { id: id, tenantId: tenantId }`). Questa accortezza impedisce a utenti maliziosi di altri account tenant di alterare o eliminare le schede del personale di aziende concorrenti modificando semplicemente i parametri ID nelle chiamate API.

---

## 🚦 Rotte API Esposte

Tutte le rotte richiedono l'Header `Authorization: Bearer <JWT_TOKEN>`.

| Metodo | Rotta | Descrizione |
| :--- | :--- | :--- |
| **POST** | `/employee` | Registra un nuovo dipendente agganciandolo al locale corrente. |
| **GET** | `/employee` | Recupera l'elenco in ordine alfabetico di tutto lo staff del locale. |
| **GET** | `/employee/:id` | Recupera i dettagli sensibili, contrattuali e logistici di un singolo dipendente. |
| **PATCH** | `/employee/:id` | Aggiorna i campi della scheda dipendente (es. scadenze o aumenti di stipendio). |
| **DELETE** | `/employee/:id` | Rimuove definitivamente il dipendente dal database aziendale. |