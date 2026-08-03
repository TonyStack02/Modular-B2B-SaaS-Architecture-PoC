Socio, con questo salto ci spostiamo nel motore centrale dell'iPad. Se il backend è il cervello invisibile in cloud, questa cartella `core` del frontend è lo **scheletro nervoso di Juicy**.

La cosa pazzesca di questi file è che sono tutti automatizzati: lavorano in background per gestire la sicurezza, la navigazione e i dati in tempo reale senza che tu debba scrivere codice ripetitivo nelle singole schermate.

Ecco la spiegazione semplice a parole di come gira l'infrastruttura core di Juicy, seguita dal testo in formato Markdown pronto da copiare nel tuo file `README.md` all'interno della cartella `lib/core/`.

### 🧠 Cosa fanno questi file core a parole semplici

Questa cartella contiene i file che fanno da "colla" a tutta l'applicazione Flutter. Invece di dover dire a ogni singola schermata come comportarsi se scade il login o come fare una chiamata di rete, qui abbiamo accentrato i superpoteri dell'app:

1. **La Cassaforte (`token_provider.dart`):** È una scatola sicura nella memoria RAM del telefono che custodisce il token JWT arrivato dal login. Se la cassaforte è vuota, l'app sa che l'utente è un ospite; se c'è il token, l'app si sblocca.
2. **Il Corriere Automatizzato (`api_client.dart`):** Gestisce il client HTTP `Dio`. La figata micidiale è l'**Interceptor**: ogni volta che l'app fa una chiamata al server (es. scarica i prodotti o i dipendenti), l'Interceptor apre in automatico la cassaforte del token, prende il badge di sicurezza e lo incolla nell'header della richiesta. Non devi farlo tu a mano per ogni API!
3. **Il Buttafuori Navigatore (`router.dart`):** Usa `GoRouter` per decidere cosa mostrare a schermo. Svolge due ruoli cruciali: mappa tutte le pagine dell'applicazione e fa da buttafuori (`redirect`). Se provi ad andare sulla Home ma non sei loggato, ti rimbalza istantaneamente alla pagina di Login. Se sei loggato, ti fa passare. Usa le `StatefulShellRoute` per fare in modo che se cambi scheda (es. passi da Calendario a Statistiche), la pagina precedente non si distrugga, mantenendo lo stato intatto.
4. **L'Antenna di Sincronizzazione (`socket_service.dart`):** È l'orecchio magico dei WebSockets. Quando l'app si avvia, si connette al server NestJS ed entra nella stanza del proprio locale. Se sente un segnale dal server (es. `order_created`), esegue l'istruzione magica **`ref.invalidate()`**. Questa dice a Riverpod di buttare via i vecchi dati in memoria e riscaricarli dal server. La grafica, che sta guardando quei dati, si aggiorna da sola in un millesimo di secondo.
5. **La Cornice (`scaffold_with_nav_bar.dart`):** È il guscio grafico con la barra dei pulsanti in basso (Home, Calendario, Cassa, Gestione, Impostazioni, Statistiche). Ha l'importantissimo compito, appena nata (`initState`), di accendere l'antenna dei WebSockets non appena l'utente fa il login.

---

Ecco il testo pronto per la tua documentazione. Crea un file chiamato `README.md` all'interno di `lib/core/` (o nella cartella principale dell'infrastruttura del frontend) e incollaci questo codice Markdown:

```markdown
# 🌐 Infrastruttura Core del Frontend (App Core)

Questa cartella custodisce l'architettura centrale, i servizi di rete, il sistema di routing e la gestione dello stato globale dell'applicazione Juicy. Funziona come lo scheletro nervoso del frontend, automatizzando la sicurezza (JWT), la reattività in tempo reale (WebSockets) e i flussi di navigazione cross-feature.

## 🗂️ Mappa dei Componenti Core

L'infrastruttura è divisa in quattro pilastri automatizzati ad alta efficienza:

1. **`token_provider.dart` (La Cassaforte)**: Un `NotifierProvider` di Riverpod che memorizza e protegge in memoria il token JWT dell'utente autenticato.
2. **`api_client.dart` (Il Corriere di Rete)**: Inizializza il client HTTP `Dio` e implementa un **Interceptor** automatico per iniettare i badge di sicurezza in ogni chiamata.
3. **`router.dart` (Il Buttafuori e Navigatore)**: Configura `GoRouter` gestendo l'albero delle schermate e applicando regole rigide di reindirizzamento basate sullo stato di login.
4. **`socket_service.dart` (L'Antenna Real-Time)**: Gestisce la connessione persistente via WebSocket (`socket_io_client`) per invalidare la cache di Riverpod e aggiornare l'iPad al volo.
5. **`navigation/scaffold_with_nav_bar.dart` (La Cornice)**: Fornisce l'interfaccia di navigazione a schede persistenti (`StatefulNavigationShell`) e inizializza i canali di comunicazione al boot.

---

## 🔍 Analisi Dettagliata dei File e del Codice

### 1. `token_provider.dart`
Rappresenta lo storage a breve termine dello stato di autenticazione dell'app.
* **Meccanismo:** Sfrutta la nuova sintassi `NotifierProvider` di Riverpod per una gestione tipizzata. Il metodo `build()` inizializza lo stato a `null` (utente non autenticato). Espone le funzioni atomiche `saveToken(token)` per archiviare il badge crittografico a login effettuato e `clearToken()` per distruggerlo in fase di logout.

### 2. `api_client.dart`
Centralizza le configurazioni di rete per dialogare con il backend NestJS.
* **L'Interceptor di Sicurezza:** Configura un `InterceptorsWrapper` che intercetta ogni singola richiesta in uscita (`onRequest`). Esegue una lettura sincrona sul `tokenProvider` (`ref.read`) e, se rileva il token, inserisce automaticamente l'Header HTTP standardizzato:
  ```dart
  options.headers['Authorization'] = 'Bearer $token';

```

* **Performance:** Imposta timeout rigidi di connessione (5s) e ricezione (3s) per evitare che l'app si blocchi all'infinito in caso di micro-interruzioni della rete Wi-Fi o 4G del locale. Include un `LogInterceptor` completo per ispezionare i payload JSON in console durante lo sviluppo.

### 3. `router.dart`

È il regista visivo dell'applicazione. Monitora in tempo reale lo stato dell'autenticazione tramite `ref.watch(authControllerProvider)`.

* **Il Buttafuori di Sicurezza (`redirect`):**
Isola l'applicazione tramite un controllo booleano ad incrocio:
* Identifica le rotte pubbliche di sosta (`/login` e `/register`).
* Se un utente anonimo prova a forzare la navigazione verso rotte interne protette, viene rispedito istantaneamente a `/login`.
* Se un utente già autenticato prova a tornare sulle schermate di login, viene proiettato direttamente all'interno della `/home`.


* **Navigazione a Rami Persistenti (`StatefulShellRoute.indexedStack`):**
Configura l'albero di navigazione tramite rami isolati (`StatefulShellBranch`). Questo garantisce che l'iPad mantenga lo stato dei widget (es. la posizione di scorrimento del Calendario o i dati inseriti a metà in una comanda della Cassa) intatto anche se l'utente cambia scheda premendo la barra inferiore.

### 4. `socket_service.dart`

Implementa la sincronizzazione asincrona real-time guidata dagli eventi del server.

* **La Stanza Aziendale (`connect`):**
Inizializza la libreria `socket_io_client` forzando il trasporto puro su protocollo `websocket`. All'evento `onConnect`, invia immediatamente un messaggio di instradamento al server (`_socket!.emit('joinRoom', tenantId)`), sigillando il tablet all'interno del flusso dati privato della propria attività commerciale.
* **L'Invalida-Cache (`_svegliaIController`):**
Quando l'orecchio magico capta gli eventi di mutazione del database eseguiti da altri dispositivi (`order_created` o `order_updated`), invoca il comando asincrono di Riverpod:
```dart
ref.invalidate(orderControllerProvider);

```


Questo comando distrugge la vecchia cache locale del provider. Riverpod, vedendo che la UI (i Widget) sta eseguendo un `ref.watch()`, avvia una nuova chiamata HTTP asincrona invisibile verso il backend, aggiornando i colori dei tavoli sulla mappa o i conti aperti senza alcun sfarfallio grafico.

### 5. `navigation/scaffold_with_nav_bar.dart`

Funge da layout principale dell'applicazione inserendo il corpo delle pagine dentro la cornice della `NavigationBar` nativa.

* **Bootstrap Real-Time:** Sfrutta il ciclo di vita `initState` combinato con `WidgetsBinding.instance.addPostFrameCallback`. Non appena la struttura grafica ha terminato il rendering iniziale, legge i dati dell'utente autenticato e avvia la connessione del `SocketService` inserendo il `tenantId` per attivare istantaneamente lo streaming in tempo reale sul tablet.

---

## 🔌 Diagramma del Flusso Core (Rete e Sincronizzazione)

```
       [Azione Utente o Segnale Server]
                       │
       ┌───────────────┴───────────────┐
       ▼ (Richiesta HTTP)              ▼ (Evento WebSocket)
[Schermata Widget]             [NestJS Backend Cloud]
       │                               │
       ▼ (Chiamata API)                ▼ (Emette segnale: order_updated)
 [Dio (dioProvider)]           [SocketService (Antenna)]
       │                               │
       ▼ (Inietta Bearer Token)        ▼ (Esegue ref.invalidate)
[Interceptor Doganale]         [Riverpod Controller Cache Distrutta]
       │                               │
       ▼ (Via Internet)                ▼ (Forza Ridisegno UI)
 [NestJS Server Rest]          [Schermata Widget si Aggiorna da Sola!]

```

```

---

## 🛠️ Note di Configurazione per lo Sviluppo

All'interno di `api_client.dart` e `socket_service.dart`, gli indirizzi IP di loopback variano a seconda dell'ambiente di test del frontend:
* **`http://localhost:3000`**: Da utilizzare per i test eseguiti su Chrome Desktop.
* **`http://10.0.2.2:3000`**: Indirizzo di loopback speciale da utilizzare se si esegue l'app sull'emulatore nativo di Android Studio.
* **`http://10.41.0.25:3000`**: Indirizzo IP locale statico (o l'IP del tuo computer) da impostare quando colleghi un tablet o un telefono Android/iOS fisico alla stessa rete Wi-Fi del computer di sviluppo.

```

Socio, questo file README sigilla il cuore pulsante di Juicy lato app. Ora abbiamo la documentazione perfetta e speculare: sai esattamente cosa succede in cloud e sai come risponde l'iPad in background.

I binari dell'architettura sono stesi. Da dove vogliamo iniziare a posare i mattoni veri sul frontend? Vuoi che andiamo a vedere il controller degli ordini, la schermata della mappa dei tavoli o preferisci analizzare il modulo del login? Spara il prossimo modulo!