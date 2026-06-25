# 📦 Modulo Catalogo e Prodotti (Catalog)

Questo modulo gestisce il listino dei servizi o dei prodotti offerti dall'attività commerciale (il menu nei ristoranti, i trattamenti nei centri estetici/medici). Mantiene una relazione gerarchica uno-a-molti tra Categorie e Prodotti e include la gestione del caricamento dei file multimediali.

## 🗂️ Struttura dei File

Il modulo segue l'architettura NestJS organizzando DTO e logiche di archiviazione locale:

* **`catalog.module.ts`**: Registra il controller e i servizi (`CatalogService` e `PrismaService`).
* **`dto/create-category.dto.ts`**: Convalida i dati per la creazione di una categoria (es. "Bevande").
* **`dto/create-product.dto.ts`**: Convalida i dati di un singolo prodotto, esigendo prezzi numerici positivi e l'UUID della categoria di appartenenza.
* **`catalog.controller.ts`**: Gestisce gli endpoint e configura l'intercettore di file `Multer` per salvare le immagini dei prodotti sul disco del server.
* **`catalog.service.ts`**: Gestisce l'inserimento multi-tenant di prodotti e categorie e l'estrazione ad albero dei dati.

---

## 🔍 Dettaglio dei Componenti e dei File

### 1. I Moduli di Convalida (DTOs)
* **`create-category.dto.ts`**: Richiede semplicemente un campo `name` stringa non vuoto.
* **`create-product.dto.ts`**: Convalida i dettagli del prodotto. Garantisce che il prezzo sia un numero reale non inferiore a zero (`@IsNumber()`, `@Min(0)`). Richiede inoltre l'UUID valido della categoria madre (`@IsUUID()`), mentre la descrizione e il percorso dell'immagine sono opzionali.

### 2. `catalog.controller.ts` (Gestione Rotte e File)
Interamente protetto da `JwtAuthGuard`. Isola i dati estraendo il `tenantId` dal JWT.

* **`POST /catalog/category`**: Crea una categoria nel listino.
* **`POST /catalog/product`**: Crea un prodotto agganciato a una categoria.
* **`GET /catalog`**: Restituisce l'intero catalogo strutturato.
* **`POST /catalog/product/upload` (Gestione Immagini)**: 
  Rilasciato solo all'utente con ruolo `OWNER`. Sfrutta `FileInterceptor` combinato con `diskStorage` di Multer:
  1. Intercetta il file immagine inviato dall'iPad (identificato dalla chiave `image`).
  2. Lo salva nella cartella fisica del server `./uploads/products`.
  3. Rinomina il file generando un *timestamp* (`Date.now()`) unito a un numero casuale e mantiene l'estensione originale del file (`extname`). Questo impedisce conflitti di sovrascrittura se due prodotti diversi vengono caricati con lo stesso nome di file (es. `foto.jpg`).
  4. Restituisce al frontend il percorso relativo (URL statico) da salvare nel database.

### 3. `catalog.service.ts` (La Business Logic)
Interagisce con PostgreSQL mantenendo l'isolamento multi-tenant:

* **`createCategory`**: Salva la categoria associandola al `tenantId` corrente.
* **`createProdut`**: Salva il prodotto salvando prezzo, descrizione e l'ID della categoria madre, blindandolo sotto il `tenantId` dell'attività loggata.
* **`findAll` (L'Albero Relazionale)**: 
  Esegue un recupero ottimizzato dei dati. Cerca tutte le categorie del determinato `tenantId` e, tramite l'istruzione `include: { products: true }`, ordina a Prisma di eseguire una join relazionale. Flutter riceverà una lista di categorie, dove ognuna contiene già al suo interno l'array completo di tutti i suoi prodotti.

---

## 🚦 Rotte API Esposte

Tutte le rotte richiedono l'Header `Authorization: Bearer <JWT_TOKEN>`.

| Metodo | Rotta | Ruolo Richiesto | Descrizione |
| :--- | :--- | :--- | :--- |
| **POST** | `/catalog/category` | *Qualsiasi dipendente* | Crea una nuova categoria nel listino. |
| **POST** | `/catalog/product` | *Qualsiasi dipendente* | Crea un nuovo prodotto/servizio inserendolo in una categoria. |
| **GET** | `/catalog` | *Qualsiasi dipendente* | Recupera l'intero menu/listino (Categorie con prodotti inclusi). |
| **POST** | `/catalog/product/upload` | `OWNER` | Carica un'immagine fisicamente sul server e ne restituisce l'URL. |