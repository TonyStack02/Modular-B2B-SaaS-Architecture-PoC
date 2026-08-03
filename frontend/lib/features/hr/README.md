# 👔 Feature: Risorse Umane e Gestione Locale (HR & Management)

Questa feature centralizza il pannello di controllo direzionale di Juicy. Aggrega la gestione anagrafica dello staff (HR), la pianificazione dei turni (Roster) con calcolo del costo del lavoro in tempo reale, e l'accesso rapido al database dei clienti VIP (CRM).

## 🗂️ Struttura dei File

L'architettura unifica domini di dati differenti all'interno di un'unica interfaccia a schede (TabBar):

* **`data/` (`employee_repository.dart`, `shift_repository.dart`)**: Il livello di trasporto duale. Gestisce l'invio e la ricezione di anagrafiche e orari di lavoro comunicando con i microservizi di NestJS.
* **`domain/` (`employee_model.dart`, `shift_model.dart`)**: I modelli di dominio. `ShiftModel` incapsula logiche di business avanzate calcolando autonomamente la propria durata e il costo orario associato.
* **`presentation/hr_controller.dart`**: Lo state manager aggregato. Unifica i flussi asincroni di dipendenti e turni all'interno della singola classe `HrState`.
* **`presentation/add_employee_screen.dart`**: Il form di assunzione. Gestisce input complessi con data picker multipli per l'onboarding amministrativo e contrattuale.
* **`../management/presentation/management_screen.dart`**: L'hub direzionale. Un contenitore a schede (`TabBarView`) che riutilizza componenti trasversali e implementa un calendario orizzontale nativo per la consultazione del roster.

---

## 🔍 Analisi Tecnica dei Componenti

### 1. Modelli Intelligenti (`ShiftModel` e `EmployeeModel`)
Il dominio non è anemico, ma sposta il calcolo dei costi direttamente nei *getter* del modello, mantenendo i widget puliti:
```dart
double get durationInHours => endTime.difference(startTime).inMinutes / 60.0;
double get totalCost => employee == null ? 0.0 : durationInHours * employee!.hourlyWage;