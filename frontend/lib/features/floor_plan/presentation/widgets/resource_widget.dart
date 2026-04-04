// lib/features/floor_plan/presentation/widgets/resource_widget.dart

import 'package:flutter/material.dart';
import '../../data/domain/resource_model.dart';

class ResourceWidget extends StatelessWidget {
  // Passiamo il modello con tutti i dati del tavolo (id, nome, x, y)
  final ResourceModel resource;
  
  // Questa variabile ci dice se siamo in modalità "Spostamento" o "Lavoro normale"
  final bool isEditMode;
  
  // Una funzione che scatta quando muoviamo il dito sullo schermo
  final Function(DragUpdateDetails) onPanUpdate;
  
  // Una funzione che scatta quando togliamo il dito (utile per salvare sul DB)
  final VoidCallback onPanEnd;
  
  // Una funzione che scatta quando clicchiamo normalmente il tavolo
  final VoidCallback onTap;

  const ResourceWidget({
    super.key,
    required this.resource,
    required this.isEditMode,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // GestureDetector è il sensore tattile di Flutter
    return GestureDetector(
      // Se NON siamo in edit mode, onTap si attiva e apre l'ordine. Altrimenti non fa nulla al click.
      onTap: !isEditMode ? onTap : null,
      
      // onPanUpdate scatta continuamente mentre trasciniamo il dito (solo se in Edit Mode)
      onPanUpdate: isEditMode ? onPanUpdate : null,
      
      // onPanEnd scatta quando alziamo il dito dallo schermo (solo se in Edit Mode)
      onPanEnd: isEditMode ? (details) => onPanEnd() : null,
      
      // Disegniamo fisicamente il tavolo
      child: Container(
        // Dimensioni fisse per il nostro tavolo (puoi ingrandirlo se vuoi)
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          // Se siamo in Edit Mode il tavolo diventa arancione, altrimenti azzurro
          color: isEditMode ? Colors.orange.shade100 : Colors.blue.shade100,
          // Arrotondiamo i bordi
          borderRadius: BorderRadius.circular(12),
          // Aggiungiamo un bordino per farlo risaltare
          border: Border.all(
            color: isEditMode ? Colors.orange : Colors.blue,
            width: 2,
          ),
          // Un po' di ombra per l'effetto 3D
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(2, 2),
            )
          ],
        ),
        // Dentro il quadratino ci mettiamo un'icona e il testo centrati
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // L'icona: qui domani potrai mettere Icons.beach_access per gli ombrelloni!
            Icon(
              Icons.table_restaurant, 
              color: isEditMode ? Colors.orange : Colors.blue,
            ),
            const SizedBox(height: 4),
            // Il nome del tavolo (es. "Tavolo 1")
            Text(
              resource.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}