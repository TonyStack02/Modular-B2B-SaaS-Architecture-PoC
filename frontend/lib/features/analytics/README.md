# 📊 Feature: Analisi di Business (Analytics)

Questa feature implementa la dashboard analitica avanzata ("God-Mode") dell'applicazione Juicy. Consente ai titolari dei locali di monitorare l'andamento finanziario dell'attività, tracciare le metriche chiave di prestazione (KPI) e visualizzare report grafici interattivi basati su intervalli temporali personalizzabili.

## 🗂️ Struttura dei File

La feature rispetta rigorosamente i principi della *Clean Architecture* e la separazione dei livelli (Domain ➔ Presentation):

* **`domain/analytics_model.dart`**: Lo strato dei dati immutabili. Modella le risposte JSON del server in entità Dart tipizzate, implementando logiche di fallback "anti-crash".
* **`presentation/analytics_controller.dart`**: Lo strato logico reattivo. Gestisce lo stato dei filtri metrici e temporali, pilotando le chiamate HTTP asincrone in base alle interazioni dell'utente.
* **`presentation/analytics_screen.dart`**: Lo strato dell'interfaccia utente. Renderizza i widget statistici e i grafici vettoriali dinamici tramite la libreria `fl_chart`.

---

## 🔍 Analisi Tecnica dei Componenti

### 1. `domain/analytics_model.dart` (La Struttura Dati)
Incapitola la risposta del server suddividendola in quattro modelli relazionali: `AnalyticsData`, `DailyTrend`, `TopProduct`, e `CategorySplit`.
* **Meccanismo di Fallback Crittografico**: Il costruttore factory `.fromJson` applica un pattern difensivo sistematico utilizzando gli operatori coalescenti (es. `?? {}`, `?? []`, `?? 0`). Se il database NestJS restituisce record nulli o incompleti a causa di giornate senza vendite, il modello azzera il dato o istanzia array vuoti, prevenendo eccezioni di tipo `NullThrownError` a runtime.
* **Risoluzione delle Incoerenze (`qty`)**: Integra una logica di retrocompatibilità flessibile per la classifica dei prodotti: `json['qty'] ?? json['quantitySold'] ?? 0`, armonizzando il parsing sia se il server risponde con la nomenclatura troncata del nuovo motore, sia con quella estesa del vecchio database.

### 2. `analytics_controller.dart` (L'Iniezione Reattiva)
Gestisce lo stato aziendale della schermata tramite tre moduli di Riverpod:
* **`dateRangeProvider`**: Un `StateProvider` che memorizza un oggetto `DateTimeRange`. Di default imposta una finestra temporale retroattiva di 30 giorni rispetto all'istante di boot dell'app (`DateTime.now()`).
* **`selectedMetricProvider`**: Gestisce lo switch del grafico principale consentendo l'alternanza visiva tra l'analisi del fatturato ("Incasso") e il volume delle transazioni ("Ordini").
* **`analyticsProvider` (Il Calcolatore Asincrono Automatizzato)**: Estende un `FutureProvider.autoDispose`. Questo componente osserva (`ref.watch`) sia le credenziali dell'utente che il `dateRangeProvider`. **Scatta l'automazione:** ogni volta che l'utente muta l'intervallo di date sul calendario della UI, il provider si risveglia in background, riformatta le date in stringhe ISO `YYYY-MM-DD` ed esegue una chiamata reattiva di tipo `GET` verso `/analytics/dashboard`, iniettando i dati freschi nella UI senza ricaricare la pagina.

### 3. `analytics_screen.dart` (L'Interfaccia Vettoriale)
Implementa un layout dashboard pulito avvolto in una `ListView` con sfondo neutro per far risaltare i dati.
* **Il Pattern Reattivo `.when`**: Consente la sintonizzazione immediata sullo stato di `analyticsProvider`. Separa atomicamente le viste di caricamento (`CircularProgressIndicator`), gestione errori di rete e visualizzazione del pannello.
* **Pannello KPI (Key Performance Indicators)**: Sfrutta una riga speculare (`Row`) che distribuisce tre card informative paritarie: il Fatturato Totale del Periodo, il Volume degli scontrini chiusi e il valore dello Scontrino Medio (`averageOrderValue`).
* **Rappresentazione Grafica Avanzata (`fl_chart`)**:
  * *LineChart (Andamento Temporale):* Mappa dinamicamente i punti cartesiani (`FlSpot`) convertendo l'asse X nell'indice dell'array temporale e l'asse Y nel valore finanziario o numerico a seconda del valore del menu a tendina (`selectedMetric`).
  * *PieChart (Spaccato Categorie):* Calcola le fette della torta in percentuale sul fatturato totale (`e.value.revenue / data.totalRevenue`) e include una logica cromatica mirata (es. evidenzia le pizze in arancione e ruota i colori primari per le altre categorie merceologiche).
  * *BarChart (Top 5 Piatti):* Renderizza istogrammi verticali estratti dall'array `topProducts`. Applica troncamenti intelligenti sulle stringhe dei nomi superiori a 8 caratteri per preservare la pulizia visiva dell'asse orizzontale.

---

## 🚦 Diagramma del Flusso dei Dati Analitici