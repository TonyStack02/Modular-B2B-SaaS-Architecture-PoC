# 🔐 Modulo Autenticazione e Sicurezza (Auth)

Questo modulo gestisce l'intero sistema di sicurezza, iscrizione, login e protezione delle rotte dell'applicazione Juicy. Sfrutta lo standard **JWT (JSON Web Tokens)** e la libreria **Passport** per garantire una separazione multi-tenant spietata ed efficiente basata sui ruoli degli utenti.

## 🗂️ Struttura dei File

Il modulo è strutturato per separare i controlli doganali, la logica di crittografia e i buttafuori di rete:

* **`auth.module.ts`**: La centrale di sicurezza. Configura il gestore dei token JWT, imposta i tempi di scadenza e unisce tutte le guardie e le strategie.
* **`dto/`**: Le barriere doganali per i dati in ingresso. `login.dto.ts` convalida email e password, mentre `register.dto.ts` si assicura che ci siano tutti i dati per creare una nuova attività (incluso il nome del locale).
* **`auth.controller.ts`**: Le porte pubbliche della fortezza. Espone le rotte per registrarsi e loggarsi senza bisogno di token.
* **`auth.service.ts`**: Il crittografo. Verifica le credenziali, frulla le password con `bcrypt` e genera materialmente i token JWT inserendovi il `tenantId`.
* **`jwt.strategy.ts` e `jwt-auth.guard.ts`**: Il buttafuori di primo livello. Intercettano i token inviati da Flutter negli Header HTTP e controllano se sono autentici e validi.
* **`roles.decorator.ts` e `roles.guard.ts`**: Il controllo dei gradi militari. Verificano se l'utente loggato ha il ruolo corretto (`OWNER`, `STAFF`, ecc.) per compiere una determinata azione.

---

## 🔍 Dettaglio dei Componenti e dei File

### 1. I Controllori di Ingresso (DTOs)
* **`login.dto.ts`**: Verifica che l'app passi un formato e-mail valido (`@IsEmail()`) e che la password non sia vuota.
* **`register.dto.ts`**: Gestisce l'onboarding iniziale di un nuovo cliente Juicy. Obbliga ad avere una password robusta di almeno 6 caratteri (`@MinLength(6)`) e richiede il nome del proprietario e della sua attività (`restaurantName`).

### 2. `auth.controller.ts`
Espone le rotte pubbliche sotto il prefisso `/auth`.
* **`POST /auth/register`**: Prende il pacchetto dati di iscrizione e lo passa al servizio.
* **`POST /auth/login`**: Prende le credenziali e, se valide, sputa fuori il token di accesso.

### 3. `auth.service.ts` (La Logica di Business)
Contiene l'intelligenza di protezione e l'interazione atomica con il database:
* **`register`**: Controlla l'univocità dell'e-mail. Per impedire ad attacchi esterni di leggere le password in chiaro, usa `bcrypt` frullandole con 10 cicli di salatura. Sfrutta poi la potenza relazionale di Prisma per creare **nella stessa transazione** sia l'azienda (`tenant`) sia l'utente con ruolo `OWNER` collegandoli indissolubilmente.
* **`login`**: Cerca l'utente. Confronta la password immessa con quella crittografata nel database tramite `bcrypt.compare`. Se l'esito è positivo, genera un **Payload** contenente le informazioni chiave: l'ID dell'utente (`sub`), il ruolo e soprattutto il `tenantId`. Questo payload viene firmato digitalmente per produrre l'`access_token`.

### 4. Il Sistema di Controllo Flusso (Guards e Strategia)
Il viaggio di una chiamata protetta (es: `/area` o `/analytics`) passa attraverso un doppio controllo automatico: