# 🏠 Feature: Dashboard e Home Screen

Questa feature implementa la schermata principale di atterraggio (Home) dell'applicazione Juicy. Funge sia da cruscotto analitico rapido (KPI giornalieri) sia da hub di navigazione (Quick Actions) per smistare l'operatore verso i flussi di vendita, configurazione e gestione planimetrica.

## 🗂️ Struttura dei File

Il modulo segue il pattern architetturale consolidato, ottimizzato per chiamate di rete a bassissima latenza:

* **`data/dashboard_repository.dart`**: Layer di accesso ai dati. Interroga l'endpoint aggregatore `/order/stats` del backend NestJS.
* **`domain/dashboard_stats_model.dart`**: Layer di dominio. Modella i KPI sintetici (Incasso odierno e Ordini Attivi) implementando il casting sicuro dei decimali finanziari.
* **`presentation/dashboard_controller.dart`**: State management. Gestisce il ciclo di vita del caricamento iniziale e fornisce l'handler per il refresh manuale.
* **`presentation/home_screen.dart`**: Layer di presentazione. Costruisce la UI con componenti modulari (Stat Cards e Quick Actions) e gestisce i BottomSheet contestuali.

---

## 🔍 Analisi Tecnica dei Componenti

### 1. Gestione dei Dati (Domain & Data)
La dashboard non esegue calcoli complessi lato client. Si affida interamente all'endpoint aggregato di NestJS (`Promise.all` sul backend) per garantire un tempo di caricamento istantaneo (Time-to-Interactive quasi nullo).
* Il factory `DashboardStatsModel.fromJson` converte la stringa dei ricavi `todayIncome` tramite `double.tryParse`, azzerando il rischio di eccezioni se il database dovesse inviare interi, stringhe o valori nulli.

### 2. `dashboard_controller.dart` (Pull-to-Refresh)
Estende `AsyncNotifier<DashboardStatsModel>`. Espone l'azione `refresh()`, che re-inietta lo stato `AsyncLoading()` forzando il *rebuild* della UI, per poi invocare la funzione di recupero asincrona blindata all'interno di `AsyncValue.guard()`.

### 3. `home_screen.dart` (Layout e Routing)
Sfrutta il costrutto `dashboardState.when` per gestire atomicamente i tre stati della chiamata di rete (Loading, Error, Data).
* **Responsive Layout**: L'intestazione dei KPI utilizza il widget `Row` abbinato a figli `Expanded`. Questo garantisce che le *Stat Cards* si ridimensionino proporzionalmente (50% dello schermo ciascuna) senza mai causare errori di *RenderFlex Overflow* su tablet di dimensioni diverse.
* **L'Iniezione di Dipendenza Locale (`_showTableSelection`)**:
  Per l'apertura rapida di una comanda, la Home genera un `ModalBottomSheet`. L'architettura eccelle nell'uso del widget `Consumer` isolato all'interno del builder del modale:
  ```dart
  return Consumer(
    builder: (context, ref, child) {
      final floorState = ref.watch(floorPlanControllerProvider);
      // ...