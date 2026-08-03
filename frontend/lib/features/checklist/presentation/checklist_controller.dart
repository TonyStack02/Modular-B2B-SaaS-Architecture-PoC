// lib/features/checklist/presentation/checklist_controller.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../data/checklist_repository.dart';
import '../domain/checklist_model.dart';

// 1. Usiamo lo stesso approccio del tuo BookingController, niente .family!
final checklistControllerProvider = AsyncNotifierProvider<ChecklistController, ChecklistInstanceModel?>(() {
  return ChecklistController();
});

class ChecklistController extends AsyncNotifier<ChecklistInstanceModel?> {
  IO.Socket? _socket;
  String? _currentInstanceId;

  @override
  Future<ChecklistInstanceModel?> build() async {
    // Quando la pagina viene chiusa, puliamo il socket per non sprecare risorse
    ref.onDispose(() {
      _socket?.dispose();
    });

    // Partiamo con un valore nullo finché la UI non ci chiede di caricare i dati
    return null; 
  }

  // 2. La UI chiama questo metodo appena si apre (Simile al tuo changeMonth o refresh)
  Future<void> loadChecklist(String instanceId, String tenantId) async {
    _currentInstanceId = instanceId;
    
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      _initSocket(instanceId);
      final repository = ref.read(checklistRepositoryProvider);
      return await repository.getDailyChecklist(instanceId, tenantId);
    });
  }

  // 3. Gestione del tempo reale con Socket.io
  void _initSocket(String instanceId) {
    if (_socket != null) return;

    _socket = IO.io('http://localhost:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      print('🟢 Connesso ai WebSocket delle Checklist!');
      _socket!.emit('join_checklist', {'instanceId': instanceId});
    });

    _socket!.on('task_updated', (data) {
      final currentState = state.value;
      if (currentState == null) return;

      final updatedResult = ChecklistResultModel.fromJson(data);
      
      final newResults = List<ChecklistResultModel>.from(currentState.results);
      final index = newResults.indexWhere((r) => r.taskTemplateId == updatedResult.taskTemplateId);
      
      if (index >= 0) {
        newResults[index] = updatedResult; // Aggiorna spunta esistente
      } else {
        newResults.add(updatedResult);     // Aggiunge nuova spunta
      }

      // Aggiorna la UI senza fare richieste HTTP
      state = AsyncData(currentState.copyWith(results: newResults));
    });
  }

  // 4. Invia la spunta o il valore al server
  void updateTask({
    required String taskTemplateId,
    required String employeeId,
    required String value,
  }) {
    if (_currentInstanceId == null) return;

    _socket?.emit('update_task', {
      'instanceId': _currentInstanceId,
      'taskTemplateId': taskTemplateId,
      'employeeId': employeeId,
      'value': value,
    });
  }
}