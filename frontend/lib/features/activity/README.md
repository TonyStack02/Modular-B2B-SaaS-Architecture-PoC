# 🚀 Feature: Plancia Attività (Activity)

Questa cartella contiene lo strato visivo operativo in tempo reale di Juicy. Agisce come un aggregatore cross-feature: unisce i dati strutturali della planimetria geometrica (modulo `floor_plan`) con le transazioni finanziarie correnti (modulo `orders`), renderizzando il pannello di controllo interattivo per lo staff del locale.

## 🗂️ Struttura dei File

La feature è strutturata in modo ultra-snello poiché riutilizza interamente i controller e lo stato delle altre isole architetturali dell'applicazione:

* **`presentation/activity_screen.dart`**: La vista principale. Implementa una griglia di rendering cartesiana dinamica a due strati, abilitando gesture di navigazione spaziale e smistando i flussi di checkout e presa comande.

---

## 🔍 Analisi Tecnica della Schermata

### 1. `activity_screen.dart` (Il Pannello di Controllo Interattivo)
La classe estende un `ConsumerWidget` di Riverpod per agganciarsi al grafo di stato globale. 

* **Il Monitoraggio Concorrente (Multi-Watch)**:
  Il metodo `build` esegue il tracking simultaneo di due sorgenti asincrone distinte:
  * `floorPlanControllerProvider`: Fornisce i vettori dei muri e le coordinate geometriche statiche dei tavoli/postazioni.
  * `orderControllerProvider`: Fornisce l'array degli scontrini e delle comande attualmente aperte (`status == 'OPEN'`).

* **La Gestione degli Stati di Caricamento (Global Loading)**:
  Tramite l'istruzione condizionale `floorPlanState.isLoading || ordersState.isLoading`, la UI previene disallineamenti grafici (es. caricare i tavoli prima delle pareti). Se anche uno solo dei due flussi è in transito sulla rete, viene renderizzato un `CircularProgressIndicator` centralizzato.

* **La Griglia Vettoriale 2D (`InteractiveViewer` & `Stack`)**:
  Per ospitare layout complessi e multi-zona (es: spiagge o grandi sale), l'intera plancia è configurata su una tela fissa di `2000x2000` pixel, gestita dall'**`InteractiveViewer`**. Questo widget nativo abilita le gesture di:
  * *Pinch-to-zoom:* Scalabilità dinamica del viewport da un minimo di `0.5x` a un massimo di `2.0x`.
  * *Pan / Scroll:* Scorrimento diagonale e omnidirezionale fluido.
  All'interno, un widget `Stack` sfrutta il posizionamento assoluto (`Positioned`) leggendo le colonne `positionX` e `positionY` direttamente da PostgreSQL.

* **L'Algoritmo di Incrocio Dati (Data Cross-Referencing)**:
  All'interno del ciclo di mappatura dei tavoli, viene eseguito un filtraggio mirato in RAM:
  ```dart
  final activeOrder = activeOrders.where((o) => o.resourceId == table.id).firstOrNull;
  final isOccupied = activeOrder != null;