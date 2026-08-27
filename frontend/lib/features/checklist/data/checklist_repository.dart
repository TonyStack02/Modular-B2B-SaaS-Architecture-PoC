import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart'; // Il tuo provider Dio globale
import '../domain/checklist_model.dart';

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  return ChecklistRepository(ref.read(dioProvider));
});

class ChecklistRepository {
  final Dio _dio;
  ChecklistRepository(this._dio);

  // Scarica l'istanza giornaliera e i suoi template
  Future<ChecklistInstanceModel?> getDailyChecklist(String instanceId, String tenantId) async {
    final response = await _dio.get(
      '/checklists/$instanceId',
      queryParameters: {'tenantId': tenantId},
    );
    
    // 🛡️ LO SCUDO: Se il backend ci risponde vuoto, fermiamo tutto e restituiamo null
    if (response.data == null || response.data == '') {
      print("⚠️ Nessuna checklist trovata sul server per l'ID: $instanceId");
      return null;
    }

    print("📋 DATI CHECKLIST RICEVUTI DA NESTJS: ${response.data}");
    return ChecklistInstanceModel.fromJson(response.data);
  }

  // NOTA: Il salvataggio dei task lo faremo via WebSocket nel controller per avere latenza zero,
  // ma se in futuro vorrai usare il REST in fallback, questa è la chiamata pronta:
  Future<void> saveTaskResultHttp(Map<String, dynamic> resultData) async {
    await _dio.post('/checklists/result', data: resultData);
  }

  Future<void> createTemplateHttp(Map<String, dynamic> data) async {
     await _dio.post('/checklists/templates', data: data); 
  }

  /*
   * ⬇️ SCARICA TUTTE LE CHECKLIST DI OGGI
   * Chiama la rotta Lazy del backend che genera (se mancano) e restituisce
   * l'elenco completo delle routine previste per la giornata.
   */
  Future<List<ChecklistInstanceModel>> getDailyChecklistsList(String tenantId) async {
    // Effettuiamo la chiamata GET passando il tenantId come parametro query
    final response = await _dio.get(
      '/checklists/daily',
      queryParameters: {'tenantId': tenantId},
    );
    
    // Se la risposta è vuota o null, ritorniamo una lista vuota per evitare crash
    if (response.data == null || response.data == '') {
      return [];
    }

    // Trasformiamo il JSON restituito in una lista dinamica
    final List<dynamic> data = response.data;
    
    // Mappiamo ogni elemento del JSON trasformandolo nel nostro modello fortemente tipizzato
    return data.map((json) => ChecklistInstanceModel.fromJson(json)).toList();
  }
}