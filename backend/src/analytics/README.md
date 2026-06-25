# 📊 Modulo Analytics

Questo modulo gestisce l'elaborazione dei dati statistici e delle metriche di business (KPI) per la dashboard di Juicy. Estrae i dati grezzi degli ordini dal database e li trasforma in strutture ottimizzate per essere visualizzate nei grafici del frontend (Flutter).

## 🗂️ Struttura dei File

Il modulo è composto da tre file principali:

1. **`analytics.module.ts`**: Il passaporto del modulo. Configura e unisce il controller e il service, iniettando anche `PrismaService` per consentire l'accesso al database.
2. **`analytics.controller.ts`**: Il vigile urbano. Gestisce la rotta HTTP, convalida i parametri passati nell'URL dall'app e passa il lavoro al service.
3. **`analytics.service.ts`**: Il cervello matematico. Contiene il "tritacarne" logico che macina i dati degli ordini e calcola fatturato, medie e classifiche.

---

## 🔍 Dettaglio dei Componenti e dei File

### 1. `analytics.controller.ts`
Gestisce l'endpoint **`GET /analytics/dashboard`**. 
* **Cosa fa:** Aspetta tre parametri di query dall'app: `tenantId` (l'ID del locale), `startDate` (data inizio) e `endDate` (data fine).
* **Controllo Doganale:** Esegue un controllo immediato: se manca anche uno solo di questi tre parametri, blocca la richiesta e lancia un errore `400 BadRequestException`, impedendo al server di lavorare a vuoto. Se i dati ci sono, chiama il service.

### 2. `analytics.service.ts`
È il cuore pulsante del modulo. Contiene la funzione principale `getDashboardStats` che si divide in 3 fasi operative:

* **Fase 1: Il Recupero dei Dati**
  Imposta l'orario della data di fine alle `23:59:59` per coprire l'intera giornata finale. Poi fa una singola query a PostgreSQL tramite Prisma cercando solo gli ordini che:
  * Appartengono a quel determinato `tenantId`.
  * Hanno lo stato impostato su `PAID` (ordini effettivamente completati e pagati).
  * Sono stati creati all'interno del range di date richiesto.
  * *Inclusione Relazioni:* Tramite Prisma tira su in un colpo solo anche le righe dello scontrino (`items`), i dettagli del prodotto venduto e la categoria di appartenenza.

* **Fase 2: Il Tritacarne (Data Processing)**
  Il codice esegue un ciclo `for` su tutti gli ordini recuperati e accumula i dati in strutture temporanee (`Record` di JavaScript):
  * Somma i totali per calcolare il `totalRevenue` (fatturato totale).
  * Raggruppa gli ordini giorno per giorno per creare l'andamento giornaliero (`dailyTrend`).
  * Entra dentro ogni riga di ogni scontrino per aggiornare la quantità totale venduta di ogni singolo prodotto (`productSales`) e calcolare quanto ha incassato ogni singola categoria merceologica (`categorySplit`).

* **Fase 3: Il Packaging per Flutter**
  Prende i dati accumulati e li formatta in array puliti pronti per essere digeriti dai grafici `fl_chart` del frontend:
  * Calcola lo scontrino medio (`averageOrderValue`).
  * Ordina i prodotti dal più venduto al meno venduto ed estrae solo i primi 5 (**Top 5 Products**).
  * Restituisce un super-JSON diviso in `kpi` (numeri secchi) e `charts` (andamenti e classifiche).

---

## 🎁 Formato del JSON restituito a Flutter

Il modulo risponde all'app con questa esatta struttura dati:

```json
{
  "kpi": {
    "totalRevenue": 1540.50,
    "totalOrders": 42,
    "averageOrderValue": 36.67
  },
  "charts": {
    "dailyTrend": [
      { "date": "2026-06-20", "revenue": 740.00, "orders": 20 },
      { "date": "2026-06-21", "revenue": 800.50, "orders": 22 }
    ],
    "topProducts": [
      { "name": "Pizza Margherita", "qty": 15 },
      { "name": "Birra Media", "qty": 12 }
    ],
    "categorySplit": [
      { "name": "Cibo", "revenue": 1100.00 },
      { "name": "Bevande", "revenue": 440.50 }
    ]
  }
}