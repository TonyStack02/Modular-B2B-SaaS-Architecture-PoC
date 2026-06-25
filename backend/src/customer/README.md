# 👥 Modulo Clienti e CRM (Customer)

Questo modulo gestisce la rubrica dei clienti (CRM) di Juicy in modalità multi-tenant. Oltre a salvare i dati anagrafici fondamentali, elabora metriche avanzate in tempo reale (valore del cliente, numero di appuntamenti e storico di spesa) per identificare i clienti più profittevoli per l'attività.

## 🗂️ Struttura dei File

Il modulo segue la classica architettura a strati di NestJS:

* **`customer.module.ts`**: Registra il controller e i servizi necessari (`CustomerService` e `PrismaService`).
* **`dto/create-customer.dto.ts`**: Il validatore di forma. Si assicura che il nome sia presente e che l'email inserita rispetti lo standard dei client di posta.
* **`dto/update-customer.dto.ts`**: Rende opzionali tutti i campi di creazione per permettere modifiche parziali sulla scheda cliente.
* **`customer.controller.ts`**: Espone gli endpoint pubblici della rubrica, intercettando e isolando le richieste tramite il `tenantId` estratto dal JWT.
* **`customer.service.ts`**: Il motore analitico. Calcola i KPI di spesa di ogni cliente integrando i dati relazionali di ordini e prenotazioni.

---

## 🔍 Dettaglio dei Componenti e dei File

### 1. I Moduli di Validazione (DTOs)
* **`create-customer.dto.ts`**: Convalida l'input dell'iPad. `firstName` è l'unico campo obbligatorio (`!:`). I campi `lastName`, `phone`, `email` e `notes` (es. allergie o preferenze mediche) sono opzionali. Se l'email viene inserita, il decoratore `@IsEmail()` verifica che sia formattata correttamente.

### 2. `customer.controller.ts`
Completamente blindato dietro la `JwtAuthGuard`. Ogni operazione è protetta dall'isolamento multi-tenant:
* **`POST /customer`**: Crea un nuovo cliente associandolo al locale del richiedente.
* **`GET /customer`**: Recupera la rubrica arricchita delle statistiche di spesa.
* **`DELETE /customer/:id`**: Rimuove un cliente passando l'ID e il `tenantId` per evitare che un'attività cancelli i clienti di un'altra.

### 3. `customer.service.ts` (La Logica del CRM)
Interagisce con PostgreSQL tramite Prisma ed esegue calcoli di aggregazione:

* **`create`**: Inserisce un nuovo record spacchettando il DTO con l'operatore spread (`...dto`) e iniettando il `tenantId` estratto dal badge di login.
* **`findAll` (L'Algoritmo di Valore Cliente)**:
  Esegue una query ottimizzata combinando conteggi e selezioni mirate:
  1. Tramite `_count`, dice al database di calcolare il numero totale di righe collegate nelle tabelle `bookings` e `orders` per quel cliente.
  2. Tramite `select: { totalAmount: true }` dentro la relazione `orders`, estrae solo i totali in denaro di ogni scontrino, evitando di scaricare inutilmente i dettagli di ogni singolo piatto o prodotto acquistato.
  3. **Il Calcolatore di Spesa (`reduce`):** Esegue una mappatura dell'array trasformando i dati grezzi in un formato pulito per Flutter. Converte il valore memorizzato nel database in un numero reale (`Number(order.totalAmount || 0)`) e lo somma per calcolare il `totalSpent`.

---

## 🎁 Struttura Dati Restituita a Flutter

L'app riceve un oggetto JSON strutturato e pronto per essere inserito nelle schede della UI senza bisogno di ulteriori calcoli sul tablet:

```json
[
  {
    "id": "uuid-cliente-1",
    "firstName": "Marco",
    "lastName": "Rossi",
    "phone": "+3934567890",
    "email": "marco.rossi@email.com",
    "notes": "Cliente VIP, preferisce trattamenti serali",
    "totalBookings": 14,
    "totalOrders": 12,
    "totalSpent": 840.50
  }
]