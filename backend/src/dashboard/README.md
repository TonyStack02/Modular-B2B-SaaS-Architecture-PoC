# 🎛️ Modulo Dashboard (Torre di Controllo)

Questo modulo gestisce l'aggregazione dei dati flash in tempo reale per la schermata principale (Home) di Juicy. Funziona come un orchestratore di servizi: raccoglie metriche rapide e contatori vitali da altri moduli (come il reparto Ordini) e li serve in parallelo per garantire un caricamento istantaneo dell'app sul tablet.

## 🗂️ Struttura dei File

Il modulo è estremamente snello e punta sul riuso della logica esistente:

* **`dashboard.module.ts`**: L'interconnessione. Configura il modulo importando `OrderModule` (l'isola degli ordini) per rendere disponibili i suoi servizi interni.
* **`dashboard.controller.ts`**: Il guardiano della Home. Espone la rotta di controllo protetta dal token JWT.
* **`dashboard.service.ts`**: Il direttore d'orchestra. Coordina le chiamate asincrone parallele verso gli altri servizi del backend.

---

## 🔍 Dettaglio dei Componenti e dei File

### 1. `dashboard.module.ts` (L'Incrocio dei Moduli)
A differenza degli altri moduli visti finora che parlano solo con `PrismaService`, questo modulo introduce il concetto di **Modularità Accoppiata**. 
* Tramite l'istruzione `imports: [OrderModule]`, Juicy non duplica il codice per contare gli ordini, ma chiede la chiave d'accesso per usare le funzioni pubbliche scritte all'interno del modulo Ordini.

### 2. `dashboard.controller.ts`
Gestisce l'endpoint **`GET /dashboard/stats`**.
* Interamente protetto da `@UseGuards(JwtAuthGuard)`.
* Estrae l'identificativo aziendale `req.user.tenantId` dal token crittografato e lo passa al volo al servizio, garantendo la barriera di sicurezza multi-tenant.

### 3. `dashboard.service.ts` (L'Algoritmo di Parallelismo)
Questo servizio non possiede un'istanza di Prisma, ma inietta nel costruttore l'`OrderService`. Contiene la funzione `getHomeStats` che implementa un'ottimizzazione fondamentale:

* **La Sincronizzazione Parallela (`Promise.all`)**
  Normalmente, l'esecuzione del codice asincrono (`await`) blocca il server fino al completamento della query. Scrivere due istruzioni separate creerebbe un collo di bottiglia (Tempo Totale = Tempo Query 1 + Tempo Query 2).
  Il codice aggira questo problema inserendo le promesse in un array dentro `Promise.all`:
  1. Spende un solo colpo di rete per inviare contemporaneamente a PostgreSQL sia la richiesta di conteggio degli ordini attivi (`countActiveOrders`) sia la richiesta dell'incasso odierno (`getTodayIncome`).
  2. Sfrutta il destructuring di JavaScript (`const [activeOrders, todayIncome] = ...`) per spacchettare i due risultati non appena tornano indietro dal magazzino dati.

---

## 🎁 Struttura Dati Restituita a Flutter

L'endpoint risponde con un JSON leggerissimo e pulito, perfetto per aggiornare i badge numerici della Home dell'iPad:

```json
{
  "activeOrders": 8,
  "todayIncome": 450.20
}