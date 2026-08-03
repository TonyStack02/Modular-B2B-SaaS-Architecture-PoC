// lib/features/floor_plan/presentation/floor_plan_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/floor_plan_repository.dart';
import '../domain/area_model.dart';
import '../domain/resource_model.dart';
import '../domain/map_element_model.dart';

// Un "pacchetto" custom per contenere sia le aree che le risorse insieme
class FloorPlanState {
  final List<AreaModel> areas;
  final List<ResourceModel> resources;
  final List<MapElementModel> mapElements;

  FloorPlanState({required this.areas, required this.resources, required this.mapElements});
}

final floorPlanControllerProvider = AsyncNotifierProvider<FloorPlanController, FloorPlanState>(() {
  return FloorPlanController();
});

class FloorPlanController extends AsyncNotifier<FloorPlanState> {
  @override
  Future<FloorPlanState> build() async {
    return _fetchData();
  }

  Future<FloorPlanState> _fetchData() async {
    final repo = ref.read(floorPlanRepositoryProvider);
    // Scarichiamo Aree e Tavoli in parallelo per fare prima!
    final areas = await repo.getAreas();
    final resources = await repo.getResources();
    final mapElements = await repo.getMapElements();
    return FloorPlanState(areas: areas, resources: resources, mapElements: mapElements);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchData());
  }

  // Crea un'area e ricarica
  Future<void> addArea(String name) async {
    await ref.read(floorPlanRepositoryProvider).createArea(name);
    await refresh();
  }

  // Crea un tavolo e ricarica
  Future<void> addResource(String name, String areaId) async {
    await ref.read(floorPlanRepositoryProvider).createResource(name, areaId);
    await refresh();
  }

  // ------------------------------------------------------------------------
  // 📍 NUOVI METODI PER LA MAPPA INTERATTIVA (DRAG & DROP)
  // ------------------------------------------------------------------------

  // 1. SPOSTAMENTO LOCALE (In tempo reale)
  // Questa funzione scatta 60 volte al secondo mentre il dito si muove.
  // NON chiama il server (altrimenti esploderebbe), modifica solo la memoria RAM di Flutter.
  void updateResourcePositionLocal(String id, double deltaX, double deltaY) {
    // Se non abbiamo ancora caricato i dati, non facciamo nulla
    if (state.value == null) return;

    final currentState = state.value!;

    // Creiamo una nuova lista di tavoli, modificando SOLO quello che stiamo toccando
    final updatedResources = currentState.resources.map((table) {
      if (table.id == id) {
        // Creiamo una copia del tavolo con le nuove coordinate
        // (Aggiungiamo lo spostamento X e Y del dito alla posizione attuale)
        return ResourceModel(
          id: table.id,
          name: table.name,
          areaId: table.areaId,
          positionX: table.positionX + deltaX,
          positionY: table.positionY + deltaY,
        );
      }
      return table; // Gli altri tavoli rimangono immobili
    }).toList();

    // Sovrascriviamo lo stato di Riverpod. 
    // Usiamo AsyncData per dire alla UI: "Ehi, ho nuovi dati, ridisegna lo schermo!"
    state = AsyncData(FloorPlanState(
      areas: currentState.areas,
      resources: updatedResources,
      mapElements: currentState.mapElements,
    ));
  }

  // 2. SALVATAGGIO SUL BACKEND (Quando si alza il dito)
  // Questa funzione scatta UNA SOLA VOLTA quando l'Owner posiziona il tavolo e stacca il dito.
  Future<void> saveResourcePositionBackend(String id) async {
    if (state.value == null) return;

    // Andiamo a pescare il tavolo dalla memoria per leggere le sue coordinate DEFINITIVE
    final tableToSave = state.value!.resources.firstWhere((r) => r.id == id);

    try {
      // Diciamo al Fattorino (Repository) di inviare la richiesta PATCH/PUT a NestJS
      await ref.read(floorPlanRepositoryProvider).updateResourcePosition(
        tableToSave.id,
        tableToSave.positionX,
        tableToSave.positionY,
      );
      print("Posizione del tavolo ${tableToSave.name} salvata sul server con successo!");
    } catch (e) {
      print("Errore nel salvataggio della posizione: $e");
      // Se il server è giù o c'è un errore, per fare le cose perfette
      // in futuro potremmo far tornare il tavolo alla posizione originale ricaricando i dati.
    }
  }

  // --- NUOVI METODI PER L'AUTOCAD (MURI E TESTI) ---

  // 1. Spawna un elemento al volo sulla mappa
  // 1. Crea il muro UFFICIALE sul database e poi lo mostra
  Future<void> spawnMapElement(String type) async {
    if (state.value == null) return;

    final width = type == 'WALL' ? 150.0 : (type == 'DOOR' ? 60.0 : 120.0);
    final height = type == 'WALL' ? 20.0 : (type == 'DOOR' ? 10.0 : 40.0);
    final text = type == 'TEXT' ? "Testo" : null;

    // Chiamiamo il backend che crea il muro e ci dà il suo VERO ID nel database!
    final newElement = await ref.read(floorPlanRepositoryProvider).createMapElement(
      type, 100.0, 100.0, width, height, text: text
    );

    // Lo aggiungiamo allo schermo
    final currentState = state.value!;
    state = AsyncData(FloorPlanState(
      areas: currentState.areas,
      resources: currentState.resources,
      mapElements: [...currentState.mapElements, newElement],
    ));
  }

  // 2. Sposta l'elemento trascinandolo col dito
  void updateMapElementPositionLocal(String id, double deltaX, double deltaY) {
    if (state.value == null) return;
    final currentState = state.value!;

    final updatedElements = currentState.mapElements.map((el) {
      if (el.id == id) {
        return MapElementModel(
          id: el.id, type: el.type, text: el.text,
          positionX: el.positionX + deltaX,
          positionY: el.positionY + deltaY,
          width: el.width, height: el.height, rotation: el.rotation,
        );
      }
      return el;
    }).toList();

    state = AsyncData(FloorPlanState(
      areas: currentState.areas, resources: currentState.resources, mapElements: updatedElements,
    ));
  }

  // Questa funzione scatta quando l'Owner stacca il dito dopo aver spostato il muro
  Future<void> saveMapElementBackend(String id) async {
    if (state.value == null) return;

    // Peschiamo il muro dalla memoria per leggere le sue coordinate attuali
    final elementToSave = state.value!.mapElements.firstWhere((e) => e.id == id);

    try {
      await ref.read(floorPlanRepositoryProvider).updateMapElementPosition(
        elementToSave.id,
        elementToSave.positionX,
        elementToSave.positionY,
      );
      print("Posizione del decoro salvata sul server con successo!");
    } catch (e) {
      print("Errore nel salvataggio della decorazione: $e");
    }
  }

  // 💥 CANCELLAZIONE
  Future<void> deleteMapElement(String id) async {
    if (state.value == null) return;
    final currentState = state.value!;

    // 1. Lo facciamo sparire SUBITO dallo schermo per far sembrare l'app super veloce
    final filteredElements = currentState.mapElements.where((e) => e.id != id).toList();
    state = AsyncData(FloorPlanState(
      areas: currentState.areas, resources: currentState.resources, mapElements: filteredElements,
    ));

    // 2. Poi lo eliminiamo dal database in background
    try {
      await ref.read(floorPlanRepositoryProvider).deleteMapElement(id);
    } catch (e) {
      print("Errore cancellazione: $e");
    }
  }

  // 🛠️ MODIFICA PROPRIETA' (Dimensione, Rotazione, Testo)
  Future<void> updateMapElementProps(String id, {double? w, double? h, double? rot, String? txt}) async {
    if (state.value == null) return;
    final currentState = state.value!;

    // 1. Aggiorniamo la RAM del telefono per far vedere il muro che si allarga in tempo reale
    final updatedElements = currentState.mapElements.map((e) {
      if (e.id == id) {
        return MapElementModel(
          id: e.id, type: e.type, positionX: e.positionX, positionY: e.positionY,
          width: w ?? e.width, height: h ?? e.height, 
          rotation: rot ?? e.rotation, text: txt ?? e.text,
        );
      }
      return e;
    }).toList();

    state = AsyncData(FloorPlanState(
      areas: currentState.areas, resources: currentState.resources, mapElements: updatedElements,
    ));

    // 2. Salviamo le nuove misure sul server
    await ref.read(floorPlanRepositoryProvider).updateMapElementProperties(id, w: w, h: h, rot: rot, txt: txt);
  }
}