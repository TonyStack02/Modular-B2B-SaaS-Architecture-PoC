// lib/features/analytics/presentation/analytics_controller.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/analytics_model.dart';
import '../../../core/api_client.dart';

// 1. IL CONTROLLER DELLA DATA (Di default: ultimi 30 giorni)
final dateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now);
});

// 2. IL CONTROLLER DEL GRAFICO (Incasso vs Ordini)
final selectedMetricProvider = StateProvider<String>((ref) => 'Incasso');

// 3. IL PROVIDER CHE SCARICA I DATI (Ascolta i cambiamenti di data in automatico!)
final analyticsProvider = FutureProvider.autoDispose<AnalyticsData>((ref) async {
  final dio = ref.watch(dioProvider);
  final user = ref.watch(authControllerProvider).value;
  final dateRange = ref.watch(dateRangeProvider); // ASCOLTA IL CALENDARIO!

  if (user == null || user.tenantId == null) throw Exception("Utente non loggato");

  // Formattiamo le date scelte dall'utente
  final startStr = "${dateRange.start.year}-${dateRange.start.month.toString().padLeft(2, '0')}-${dateRange.start.day.toString().padLeft(2, '0')}";
  final endStr = "${dateRange.end.year}-${dateRange.end.month.toString().padLeft(2, '0')}-${dateRange.end.day.toString().padLeft(2, '0')}";

  final response = await dio.get(
    '/analytics/dashboard',
    queryParameters: {
      'tenantId': user.tenantId,
      'startDate': startStr,
      'endDate': endStr,
    },
  );

  return AnalyticsData.fromJson(response.data);
});