// lib/features/activity/presentation/activity_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Importiamo la Mappa e gli Ordini
import '../../floor_plan/presentation/floor_plan_controller.dart';
import '../../floor_plan/presentation/widgets/map_element_widget.dart';
import '../../floor_plan/presentation/widgets/resource_widget.dart';
import '../../orders/presentation/order_controller.dart';
import '../../orders/presentation/widgets/checkout_bottom_sheet.dart'; // 👈 IL NOSTRO SUPER POPUP!

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final floorPlanState = ref.watch(floorPlanControllerProvider);
    final ordersState = ref.watch(orderControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plancia Attività 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(floorPlanControllerProvider.notifier).refresh();
              ref.read(orderControllerProvider.notifier).refresh();
            },
          )
        ],
      ),
      body: floorPlanState.isLoading || ordersState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : floorPlanState.when(
              error: (err, stack) => Center(child: Text("Errore: $err")),
              loading: () => const SizedBox.shrink(),
              data: (planData) {
                final activeOrders = ordersState.value ?? [];

                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 2.0,
                  constrained: false,
                  child: SizedBox(
                    width: 2000,
                    height: 2000,
                    child: Stack(
                      children: [
                        // 1. DISEGNIAMO I MURI E LE PORTE (Mappa statica, non si sposta nulla)
                        ...planData.mapElements.map((element) {
                          return Positioned(
                            left: element.positionX,
                            top: element.positionY,
                            child: MapElementWidget(
                              element: element,
                              isEditMode: false, // 🔒 Niente modifiche qui!
                              onPanUpdate: (_) {},
                              onPanEnd: () {},
                              onTap: () {},
                            ),
                          );
                        }),

                        // 2. DISEGNIAMO I TAVOLI "VIVI"
                        ...planData.resources.map((table) {
                          // Controlliamo se questo tavolo ha un ordine aperto
                          final activeOrder = activeOrders.where((o) => o.resourceId == table.id).firstOrNull;
                          final isOccupied = activeOrder != null;

                          return Positioned(
                            left: table.positionX,
                            top: table.positionY,
                            child: ResourceWidget(
                              resource: table,
                              isEditMode: false, // 🔒 Niente drag & drop
                              isOccupied: isOccupied, // 🎨 Colore Rosso/Verde
                              onTap: () {
                                if (isOccupied) {
                                  // 🔴 TAVOLO OCCUPATO: Apriamo il super-popup di pagamento!
                                  CheckoutBottomSheet.show(context, activeOrder);
                                } else {
                                  // 🟢 TAVOLO LIBERO: Andiamo al POS per prendere un nuovo ordine!
                                  context.push('/pos/${table.id}'); 
                                }
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}