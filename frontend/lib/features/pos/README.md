# 🛒 Feature: Point of Sale e Presa Comande (POS)

Questa feature implementa il terminale di vendita e il sistema di presa comande (Point of Sale) di Juicy. Consente allo staff di costruire carrelli complessi, gestire le richieste della cucina tramite annotazioni personalizzate per singolo piatto e inviare ordini multi-tenant relazionati fisicamente alla mappa del locale.

## 🗂️ Struttura dei File

La feature è organizzata per garantire la massima reattività dell'interfaccia (zero latenza di rete durante la composizione del carrello) delegando il trasporto HTTP unicamente in fase di checkout finale:

* **`data/pos_repository.dart`**: Il livello di trasporto transazionale. Sfrutta l'endpoint pubblico `/guest/order` del backend per generare il payload finale e salvare l'ordine su PostgreSQL.
* **`domain/cart_item_model.dart`**: Il modello aggregatore immutabile. Avvolge l'entità del prodotto unendovi metadati logistici (quantità e note) per formare le singole righe scontrino.
* **`presentation/cart_controller.dart`**: Lo State Manager sincrono. Un `NotifierProvider` che risiede unicamente nella memoria RAM locale (senza delay di rete), gestendo raggruppamenti complessi, incrementi/decrementi di quantità e somme finanziarie.
* **`presentation/pos_screen.dart`**: La vista operativa. Integra l'albero del catalogo prodotti e implementa un `Drawer` per ospitare il carrello scorrevole senza oscurare il menu.
* **`presentation/widgets/cart_drawer.dart`**: Il componente interattivo del carrello. Include pulsantiere di incremento, popup per la digitazione delle varianti e l'evocazione finale del checkout.

---

## 🔍 Analisi Tecnica dei Componenti

### 1. Il Pattern di Immutabilità (Domain)
Il `CartItemModel` rispetta i vincoli di Riverpod isolando ogni modifica tramite il metodo `.copyWith()`.
* **Calcolo Atomico**: Fornisce un _getter_ `totalPrice` precalcolato in fase di istanziazione, liberando la UI da operazioni matematiche e delegando al modello il controllo dell'aritmetica di riga (Prezzo Unitario × Quantità).

### 2. Logica di Raggruppamento Intelligente (Controller)
All'interno del `cart_controller.dart`, il metodo `addProduct` risolve una delle sfide più complesse dei software Horeca: la gestione delle varianti.
* Sfrutta l'istruzione di matching composito:
  ```dart
  item.product.id == product.id && item.notes == notes