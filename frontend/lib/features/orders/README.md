# 🧾 Feature: Gestione Comande e Cassa (Orders)

Questa feature rappresenta il motore transazionale di Juicy sul frontend. Gestisce la visualizzazione degli scontrini, la chiusura dei conti e l'integrazione incrociata con il CRM per il tracciamento del Life Time Value (LTV) e l'erogazione di punti fedeltà.

## 🗂️ Struttura dei File

Il modulo si integra fortemente con il sistema di stato globale ed è così suddiviso:

* **`data/order_repository.dart`**: Layer dati. Gestisce le richieste REST (`GET /order` e `PATCH /order/:id/status`) fornendo i canali per chiudere le transazioni finanziarie.
* **`domain/order_model.dart`**: Entità di dominio. Mappa ordini e singole righe scontrino (`OrderItemModel`) applicando conversioni crittografiche sicure per i valori monetari.
* **`presentation/order_controller.dart`**: Gestore dello stato attivo. Scarica l'intero registro transazionale e lo filtra in RAM trattenendo unicamente i tavoli/conti aperti, alimentando la logica di colorazione della mappa.
* **`presentation/widgets/checkout_bottom_sheet.dart`**: Il modulo POS rapido. Un `ModalBottomSheet` che gestisce l'incasso, la lettura dello scontrino e la ricerca/creazione on-the-fly di clienti in rubrica.

---

## 🔍 Analisi Tecnica dei Componenti

### 1. Robustezza del Parsing Finanziario (Domain)
I modelli `OrderModel` e `OrderItemModel` implementano un sistema di sanificazione estrema sui campi `price` e `totalAmount`.
* Essendo dati elaborati tramite ORM Prisma (che spesso serializza i tipi `Decimal` in formato `String` per non perdere precisione), l'app applica la conversione a doppia mandata:
  ```dart
  final priceString = product['price']?.toString() ?? '0';
  final parsedPrice = double.tryParse(priceString) ?? 0.0;