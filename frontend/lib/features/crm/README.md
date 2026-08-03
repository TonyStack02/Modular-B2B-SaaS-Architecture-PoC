# 👥 Feature: Rubrica Clienti (CRM)

Questa feature implementa il sistema di gestione relazionale (CRM) di Juicy sul frontend. Permette di registrare l'anagrafica clienti, avviare comunicazioni rapide via WhatsApp e, soprattutto, visualizzare in tempo reale le metriche di *Life Time Value* (totale speso, prenotazioni e ordini effettuati) elaborate dal backend.

## 🗂️ Struttura dei File

La feature è progettata secondo i pattern della *Clean Architecture* e ottimizza il rendering asincrono:

* **`data/customer_repository.dart`**: Il layer di comunicazione (Data). Esegue le chiamate HTTP (GET, POST, DELETE) verso l'endpoint `/customer` utilizzando l'istanza sicura di `Dio`.
* **`domain/customer_model.dart`**: L'entità del dominio. Traduce i campi anagrafici e i KPI finanziari (calcolati in aggregazione da NestJS) in proprietà Dart tipizzate e immutabili.
* **`presentation/customer_controller.dart`**: La logica di stato. Un `AsyncNotifier` che implementa pattern avanzati di aggiornamento in memoria (*Optimistic UI* e *Local State Injection*).
* **`presentation/add_customer_screen.dart`**: Il form di creazione. Implementa la validazione lato client prima di innescare l'invio HTTP.
* **`presentation/widgets/customer_card_widget.dart`**: Il componente visivo riutilizzabile. Renderizza i KPI del cliente e integra i *deep link* per l'apertura nativa delle app di messaggistica.

---

## 🔍 Analisi Tecnica dei Componenti

### 1. `domain/customer_model.dart` (Sanificazione Dati Finanziari)
Il factory costruttore `.fromJson` previene eccezioni a runtime causate da parsing non omogenei di database relazionali (es. PostgreSQL `Decimal` type).
* Invece di eseguire un casting diretto `as double`, converte preventivamente il valore numerico in stringa e ne innesca il parsing nativo, applicando valori paracadute di default in caso di anomalie:
  ```dart
  totalSpent: json['totalSpent'] != null ? double.parse(json['totalSpent'].toString()) : 0.0,