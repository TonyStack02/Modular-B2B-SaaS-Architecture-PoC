// lib/features/analytics/presentation/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'analytics_controller.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(analyticsProvider);
    final dateRange = ref.watch(dateRangeProvider);
    final selectedMetric = ref.watch(selectedMetricProvider);

    // Formattiamo le date per farle vedere in alto (es. 12 Apr - 12 Mag)
    final dateFormat = DateFormat('dd MMM yyyy', 'it_IT'); 
    final dateString = "${dateFormat.format(dateRange.start)} - ${dateFormat.format(dateRange.end)}";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('🚀 Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          // 📅 IL TASTO DEL CALENDARIO
          TextButton.icon(
            icon: const Icon(Icons.date_range, color: Colors.blueAccent),
            label: Text(dateString, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            onPressed: () async {
              // Apriamo il picker di Flutter (Fino a 20 anni fa!)
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(DateTime.now().year - 20), // 20 anni fa
                lastDate: DateTime.now(),
                initialDateRange: dateRange,
                builder: (context, child) => Theme(
                  data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: Colors.blueAccent)),
                  child: child!,
                ),
              );
              if (picked != null) {
                // Aggiorniamo lo stato: l'app scaricherà i nuovi dati DA SOLA!
                ref.read(dateRangeProvider.notifier).state = picked;
              }
            },
          )
        ],
      ),
      body: analyticsState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
        error: (err, stack) => Center(child: Text('Errore: $err', style: const TextStyle(color: Colors.red))),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              
              // 💰 1. LE KPI PRINCIPALI
              Row(
                children: [
                  Expanded(child: _buildKpiCard("Incasso Periodo", "€${data.totalRevenue.toStringAsFixed(2)}", Icons.account_balance_wallet, Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildKpiCard("Ordini Totali", "${data.totalOrders}", Icons.receipt_long, Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildKpiCard("Scontrino Medio", "€${data.averageOrderValue.toStringAsFixed(2)}", Icons.analytics, Colors.purple)),
                ],
              ),
              const SizedBox(height: 24),

              // 📈 2. IL GRAFICO A LINEE (Con Menu a Tendina)
              _buildChartContainer(
                title: "Andamento nel Tempo",
                action: DropdownButton<String>(
                  value: selectedMetric,
                  underline: const SizedBox(),
                  items: ['Incasso', 'Ordini'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)));
                  }).toList(),
                  onChanged: (newValue) => ref.read(selectedMetricProvider.notifier).state = newValue!,
                ),
                child: data.dailyTrend.isEmpty 
                  ? const Center(child: Text("Nessun dato in questo periodo"))
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Nascondiamo le date sotto per pulizia
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            // Scegliamo dinamicamente i dati in base al menu a tendina
                            spots: data.dailyTrend.asMap().entries.map((e) {
                              double yValue = selectedMetric == 'Incasso' ? e.value.revenue : e.value.orders.toDouble();
                              return FlSpot(e.key.toDouble(), yValue);
                            }).toList(),
                            isCurved: true,
                            color: selectedMetric == 'Incasso' ? Colors.green : Colors.blue,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true, 
                              color: (selectedMetric == 'Incasso' ? Colors.green : Colors.blue).withOpacity(0.2)
                            ),
                          ),
                        ],
                      ),
                    ),
              ),

              const SizedBox(height: 24),

              // 🍕 3. GRAFICI IN PARALLELO (Torta e Barre)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LA TORTA (Incassi per Categoria)
                  Expanded(
                    flex: 1,
                    child: _buildChartContainer(
                      title: "Incassi per Categoria",
                      child: data.categorySplit.isEmpty
                        ? const Center(child: Text("Nessun dato"))
                        : PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: data.categorySplit.asMap().entries.map((e) {
                                final isPizza = e.value.name.toLowerCase().contains('pizz');
                                final color = isPizza ? Colors.orange : Colors.primaries[e.key % Colors.primaries.length];
                                return PieChartSectionData(
                                  color: color,
                                  value: e.value.revenue,
                                  title: "${((e.value.revenue / data.totalRevenue) * 100).toStringAsFixed(0)}%",
                                  radius: 50,
                                  titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                );
                              }).toList(),
                            )
                          ),
                    )
                  ),
                  const SizedBox(width: 16),
                  // LE BARRE (Top 5 Prodotti)
                  Expanded(
                    flex: 1,
                    child: _buildChartContainer(
                      title: "Top 5 Piatti",
                      child: data.topProducts.isEmpty
                        ? const Center(child: Text("Nessun dato"))
                        : BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      if (value.toInt() >= data.topProducts.length) return const SizedBox.shrink();
                                      String name = data.topProducts[value.toInt()].name;
                                      if (name.length > 8) name = "${name.substring(0, 8)}.";
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: data.topProducts.asMap().entries.map((entry) {
                                return BarChartGroupData(
                                  x: entry.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: entry.value.quantitySold.toDouble(),
                                      color: Colors.orangeAccent,
                                      width: 20,
                                      borderRadius: BorderRadius.circular(4),
                                    )
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                    )
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  // Helper per creare le Card con i Box Shadow
  Widget _buildChartContainer({required String title, required Widget child, Widget? action}) {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}