# 🗺️ Feature: Planimetria e Editor Mappa (Floor Plan)

Questa feature implementa il motore di rendering vettoriale 2D per la gestione visiva degli spazi del locale. Permette la creazione di planimetrie interattive (*Drag & Drop*) per l'amministratore e la visualizzazione reattiva in tempo reale per lo staff operativo.

## 🗂️ Struttura dei File

Il modulo gestisce un'architettura di stato complessa unificando tre domini distinti (Aree, Risorse e Decorazioni strutturali):

* **`data/floor_plan_repository.dart`**: Il layer di trasporto. Centralizza le operazioni CRUD e le mutazioni geometriche (PATCH delle coordinate) verso i tre endpoint correlati di NestJS (`/area`, `/resource`, `/map-element`).
* **`domain/` (`area_model.dart`, `resource_model.dart`, `map_element_model.dart`)**: Entità tipizzate. Eseguono il parsing del JSON garantendo il casting rigoroso in `double` delle coordinate vettoriali.
* **`presentation/floor_plan_controller.dart`**: L'hub di sincronizzazione. Gestisce il `FloorPlanState` aggregato e implementa logiche di buffering ad alta frequenza per le gesture touch.
* **`presentation/widgets/`**: Componentistica UI vettoriale, inclusa la tela `InteractiveMapWidget`, i nodi draggabili (`MapElementWidget`, `ResourceWidget`) e la griglia matematica di supporto (`GridPainter`).
* **`presentation/floor_plan_screen.dart`**: Il router visivo della pagina. Gestisce lo switch tra la vista tradizionale a liste (Accordion) e il rendering grafico della mappa.

---

## 🔍 Analisi Tecnica dei Componenti

### 1. Il Gestore di Stato Multiplo (`floor_plan_controller.dart`)
Sfrutta la classe aggregatore `FloorPlanState` per unificare l'albero di dipendenze.
* **Buffering del Drag & Drop (Anti-DDoS)**: Il controller separa il ciclo di aggiornamento in due fasi per proteggere le performance:
  1. *Fase di Pan (`updateResourcePositionLocal`)*: Scatta a ogni singolo frame di movimento del dito (`deltaX`/`deltaY`). Muta esclusivamente la RAM dell'applicazione (`state = AsyncData(...)`), consentendo un rendering del tavolo a 60fps senza interrogare la rete.
  2. *Fase di Rilascio (`saveResourcePositionBackend`)*: Scatta unicamente sull'evento `onPanEnd`. Isola la coordinata finale e genera l'unica chiamata di rete HTTP `PATCH` verso PostgreSQL.

### 2. Il Motore Vettoriale (`InteractiveMapWidget` & Componenti)
Trasforma Flutter in un mini-motore CAD.
* **La Tela Cinetica (`InteractiveViewer`)**: Fornisce un piano d'appoggio virtuale di `2000x2000` pixel svincolato dai bordi fisici del tablet. L'attributo `panEnabled: !_isEditMode` implementa un lock semantico: impedisce lo slittamento accidentale della mappa mentre l'operatore sta attivamente spostando un tavolo o modificando un muro.
* **Orientamento Radiante (`Transform.rotate`)**: All'interno del `MapElementWidget`, le rotazioni salvate nel DB in gradi (0-360) vengono convertite algoritmicamente in radianti (`angle: element.rotation * 3.1415927 / 180`) permettendo il posizionamento di muri obliqui o diagonali.
* **Griglia Matematica (`GridPainter`)**: Un `CustomPainter` a bassissimo impatto di risorse. Sfrutta il canvas nativo per disegnare reticoli `Offset` traslucidi da 50px, ottimizzando la precisione di impaginazione dell'utente senza appesantire il rendering tree.

### 3. Integrazione BottomSheet Reattiva (Gestione Layout a Liste)
Nella vista `FloorPlanScreen` non mappa-centrica, l'UI esegue una sub-query in RAM incrociando lo stato del modulo vendite:
```dart
final activeOrderForThisTable = activeOrders.where((order) => order.resourceId == table.id).firstOrNull;