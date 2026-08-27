class ChecklistResultModel {
  final String id;
  final String taskTemplateId;
  final String? value;
  final String? employeeName;

  ChecklistResultModel({
    required this.id,
    required this.taskTemplateId,
    this.value,
    this.employeeName,
  });

  factory ChecklistResultModel.fromJson(Map<String, dynamic> json) {
    return ChecklistResultModel(
      id: json['id'].toString(),
      taskTemplateId: json['taskTemplateId'].toString(),
      value: json['value']?.toString(),
      // Costruiamo il nome del dipendente concatenando firstName e lastName, se presenti
      employeeName: json['employee'] != null 
          ? '${json['employee']['firstName']} ${json['employee']['lastName']}'
          : null,
    );
  }
}

class ChecklistTaskModel {
  final String id;
  final String title;
  final String type;
  final int order;

  ChecklistTaskModel({
    required this.id,
    required this.title,
    required this.type,
    required this.order,
  });

  factory ChecklistTaskModel.fromJson(Map<String, dynamic> json) {
    return ChecklistTaskModel(
      id: json['id'].toString(),
      title: json['title'].toString(),
      type: json['type']?.toString() ?? 'BOOLEAN',
      order: json['order'] != null ? int.tryParse(json['order'].toString()) ?? 0 : 0,
    );
  }
}

class ChecklistInstanceModel {
  final String id;
  final String status;
  final String templateName;
  final String? templateDescription;
  final String targetTime;
  final List<ChecklistTaskModel> tasks;
  final List<ChecklistResultModel> results;

  ChecklistInstanceModel({
    required this.id,
    required this.status,
    required this.templateName,
    this.templateDescription,
    required this.targetTime,
    required this.tasks,
    required this.results,
  });

  factory ChecklistInstanceModel.fromJson(Map<String, dynamic> json) {
    final template = json['template'] ?? {};
    
    return ChecklistInstanceModel(
      id: json['id'].toString(),
      status: json['status']?.toString() ?? 'PENDING',
      templateName: template['name']?.toString() ?? 'Checklist',
      templateDescription: template['description']?.toString(),
      targetTime: json['targetTime']?.toString() ?? '00:00',
      // Mappiamo le liste in modo sicuro
      tasks: (template['tasks'] as List?)
              ?.map((t) => ChecklistTaskModel.fromJson(t))
              .toList() ?? [],
      results: (json['results'] as List?)
              ?.map((r) => ChecklistResultModel.fromJson(r))
              .toList() ?? [],
    );
  }

  // Creiamo un metodo copyWith per aggiornare i risultati localmente in tempo reale!
  ChecklistInstanceModel copyWith({
    List<ChecklistResultModel>? results,
  }) {
    return ChecklistInstanceModel(
      id: id,
      status: status,
      templateName: templateName,
      templateDescription: templateDescription,
      targetTime: targetTime,
      tasks: tasks,
      results: results ?? this.results,
    );
  }
}