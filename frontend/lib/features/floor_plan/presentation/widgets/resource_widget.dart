// lib/features/floor_plan/presentation/widgets/resource_widget.dart

import 'package:flutter/material.dart';
import '../../domain/resource_model.dart';

class ResourceWidget extends StatelessWidget {
  final ResourceModel resource;
  final bool isEditMode;
  // 🌉 NUOVO: Ci dice se il tavolo sta mangiando!
  final bool isOccupied; 
  
  final Function(DragUpdateDetails)? onPanUpdate;
  final VoidCallback? onPanEnd;
  final VoidCallback onTap;

  const ResourceWidget({
    super.key,
    required this.resource,
    required this.isEditMode,
    this.isOccupied = false, // Di default è libero
    this.onPanUpdate,
    this.onPanEnd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: !isEditMode ? onTap : null,
      onPanUpdate: isEditMode ? onPanUpdate : null,
      onPanEnd: isEditMode ? (details) => onPanEnd?.call() : null,
      
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          // 🎨 LA MAGIA DEI COLORI:
          // Se in EditMode -> Arancione
          // Se Occupato -> Rosso
          // Se Libero -> Verde
          color: isEditMode 
              ? Colors.orange.shade100 
              : (isOccupied ? Colors.red.shade100 : Colors.green.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEditMode 
                ? Colors.orange 
                : (isOccupied ? Colors.redAccent : Colors.green),
            width: 2,
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant, 
              color: isEditMode 
                  ? Colors.orange 
                  : (isOccupied ? Colors.redAccent : Colors.green),
            ),
            const SizedBox(height: 4),
            Text(
              resource.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}