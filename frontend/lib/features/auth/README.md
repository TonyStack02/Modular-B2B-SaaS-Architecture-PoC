# 🔐 Feature: Autenticazione e Sessione (Auth)

Questa feature gestisce l'intero ciclo di vita della sessione dell'operatore (Login, Registrazione dell'attività aziendale e Logout) sul frontend di Juicy. Implementa un'architettura a tre strati disaccoppiata (*Clean Layered Architecture*) coordinata con i meccanismi di protezione multi-tenant del backend NestJS.

## 🗂️ Struttura dei File

La feature è organizzata per separare la logica di trasporto di rete dal rendering dell'interfaccia utente:

* **`data/auth_repository.dart`**: Lo strato di persistenza e trasporto (Data Layer). Si occupa esclusivamente delle chiamate HTTP atomiche verso gli endpoint di sicurezza.
* **`domain/user_model.dart`**: Lo strato delle entità (Domain Layer). Definisce il modello dati immutabile dell'utente loggato, ripulito dal token di sessione.
* **`presentation/auth_controller.dart`**: Il manager dello stato (Presentation Layer - Logic). Gestisce gli stati asincroni della sessione e coordina il flusso di login automatico post-registrazione.
* **`presentation/login_screen.dart`**: La vista di accesso. Renderizza i campi di input e risponde reattivamente ai cambi di stato del controller.
* **`presentation/register_screen.dart`**: La vista di onboarding. Implementa form complessi con validazione locale speculare ai DTO del server.

---

## 🔍 Analisi Tecnica dei Componenti

### 1. `data/auth_repository.dart` (Il Vettore HTTP)
Rende disponibile la classe tramite `authRepositoryProvider`, leggendo l'istanza centralizzata del client di rete `dioProvider`.
* **`login()`**: Esegue una chiamata `POST` all'endpoint `auth/login` inviando le credenziali grezze.
* **`register()`**: Accetta i parametri esigiti dal `RegisterDto` del backend (`email`, `password`, `name`, `restaurantName`) e invia una richiesta `POST` strutturata a `auth/register` per istanziare contemporaneamente il Tenant e l'utente amministratore con ruolo `OWNER`.

### 2. `domain/user_model.dart` (La Tipizzazione dell'Utente)
Modella il record dell'operatore connesso.
* Il factory `.fromJson` converte in modo protetto le chiavi stringa provenienti da PostgreSQL (`id`, `email`, `tenantId`).
* Applica un fallback di sicurezza sul posizionamento gerarchico dei permessi tramite l'istruzione `json['role']?.toString() ?? 'OWNER'`, garantendo che in caso di campi nulli l'app assegni i privilegi massimi di amministrazione per non bloccare l'interfaccia.

### 3. `presentation/auth_controller.dart` (L'Incrociatore di Stato)
Estende un `AsyncNotifier` centralizzato erogato tramite `authControllerProvider`. Gestisce lo stato in modalità mutazione asincrona protetta.

* **La Riconciliazione dei Metadati (Il Radar)**:
  Sia nel flusso di Login che di Registrazione, il controller applica una pezza di sicurezza strutturale prima del parsing del modello:
  ```dart
  if (response.data['tenantId'] != null && userData['tenantId'] == null) {
    userData['tenantId'] = response.data['tenantId'];
  }