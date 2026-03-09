// lib/features/floor_plan/presentation/floor_plan_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/floor_plan_repository.dart';
import '../domain/area_model.dart';
import '../domain/resource_model.dart';

// Un "pacchetto" custom per contenere sia le aree che le risorse insieme
class FloorPlanState {
  final List<AreaModel> areas;
  final List<ResourceModel> resources;

  FloorPlanState({required this.areas, required this.resources});
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
    return FloorPlanState(areas: areas, resources: resources);
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
}