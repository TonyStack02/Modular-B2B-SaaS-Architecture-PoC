# 📅 Feature: Gestione Prenotazioni e Calendario (Bookings)

Questa feature implementa l'agenda e il sistema di pianificazione degli appuntamenti e delle prenotazioni dei clienti su Juicy. Interagisce in modo cross-funzionale con il modulo `floor_plan` per consentire l'assegnazione fisica delle prenotazioni alle risorse reali del locale (tavoli, ombrelloni, cabine) censite nel database.

## 🗂️ Struttura dei File

La feature rispetta la separazione dei livelli aziendali dell'architettura Clean:

* **`data/booking_repository.dart`**: Il livello dati. Gestisce le chiamate REST verso NestJS per prelevare i flussi mensili e inviare le nuove prenotazioni.
* **`domain/booking_model.dart`**: L'entità del dominio. Traduce i dati tipizzati di PostgreSQL e risolve le differenze di fuso orario (`UTC` vs `LocalTime`).
* **`presentation/booking_controller.dart`**: La logica di presentazione. Un controller mensile reattivo che ottimizza il consumo di RAM scaricando i dati a blocchi temporali.
* **`presentation/calendar_screen.dart`**: L'interfaccia utente. Sfrutta `TableCalendar` per mostrare i pallini degli eventi e integra form nidificati per l'onboarding immediato dei clienti.

---

## 🔍 Analisi Tecnica dei Componenti

### 1. `domain/booking_model.dart` (La Gestione del Timezone)
Definisce la struttura dati della prenotazione.
* **Risoluzione Oraria**: Nel factory `.fromJson`, l'istruzione `DateTime.parse(json['dateTime']).toLocal()` converte la stringa ISO universale (UTC, terminante con 'Z' sul database) nel fuso orario locale del dispositivo iPad.
* **Join Nidificata**: Estrae in modo sicuro il nome della risorsa fisica associata leggendo l'oggetto join del database: `json['resource'] != null ? json['resource']['name'] : null`.

### 2. `presentation/booking_controller.dart` (La Cache Temporale)
Estende un `AsyncNotifier` erogato da `bookingControllerProvider`. Tiene traccia del mese visualizzato tramite la variabile interna dello stato `_currentMonth`.
* **Ottimizzazione di Rete (`changeMonth`)**: Quando l'utente naviga nel calendario, il controller non accumula i dati, ma sovrascrive lo stato impostando `AsyncLoading()` ed effettua una query mirata `/booking/month/anno/mese`. I mesi passati o futuri non visibili vengono epurati dalla RAM, mantenendo l'app leggera.
* **Formattazione ISO (`addBooking`)**: Prima di sparare il payload JSON verso la rotta `POST /booking`, converte l'oggetto nativo `DateTime` unito della UI in una stringa standardizzata tramite `dateTime.toIso8601String()`, soddisfacendo i controlli del `CreateBookingDto` di NestJS.

### 3. `presentation/calendar_screen.dart` (L'Accoppiamento Reattivo)
Un `ConsumerStatefulWidget` che orchestra l'interfaccia dell'agenda.
* **Il Flusso Cross-Feature (Multi-Watch)**:
  Il metodo `build` monitora contemporaneamente il controller delle prenotazioni e il `floorPlanControllerProvider`:
  ```dart
  final floorPlanState = ref.watch(floorPlanControllerProvider);
  final List<ResourceModel> resources = floorPlanState.value?.resources ?? [];