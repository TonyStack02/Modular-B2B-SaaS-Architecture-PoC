# 📦 Feature: Gestione Listino e Menu (Catalog)

Questa feature implementa il pannello di configurazione del catalogo commerciale (il menu dei ristoranti, i listini dei trattamenti o dei servizi) di Juicy. Gestisce la visualizzazione gerarchica ad albero delle categorie merceologiche e l'inserimento reattivo di nuovi prodotti relazionati.

## 🗂️ Struttura dei File

Il modulo applica la separazione dei livelli definita dall'architettura Clean:

* **`data/catalog_repository.dart`**: Il livello dati. Gestisce l'interfacciamento REST verso gli endpoint `/catalog`, `/catalog/category` e `/catalog/product` di NestJS.
* **`domain/category_model.dart` & `product_model.dart`**: Il livello di dominio. Definiscono le strutture dati immutabili e i factory di conversione bidirezionale JSON/Dart.
* **`presentation/catalog_controller.dart`**: La logica di presentazione. Un `AsyncNotifier` centralizzato che orchestra il ri-pompaggio dei flussi dati in RAM a seguito di mutazioni di inserimento.
* **`presentation/catalog_screen.dart`**: L'interfaccia utente. Renderizza una lista di pannelli a tendina comprimibili (`ExpansionTile`) e gestisce i dialoghi di onboarding dei prodotti.

---

## 🔍 Analisi Tecnica dei Componenti

### 1. Il Livello dei Modelli Relazionali (Domain)
* **`category_model.dart`**: Mappa il nodo radice dell'albero. Estrae l'array grezzo `products` e lo converte in una lista tipizzata di sottomodelli tramite una mappatura funzionale lineare, tollerando array vuoti di fallback.
* **`product_model.dart`**: Mappa la foglia del catalogo. Gestisce la conversione di sicurezza finanziaria del prezzo:
  ```dart
  price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0