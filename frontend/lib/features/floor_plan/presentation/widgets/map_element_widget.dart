// lib/features/floor_plan/presentation/widgets/map_element_widget.dart

import 'package:flutter/material.dart';
import '../../data/domain/map_element_model.dart';

class MapElementWidget extends StatelessWidget {
  final MapElementModel element;
  final bool isEditMode;
  final Function(DragUpdateDetails) onPanUpdate;
  final VoidCallback onPanEnd;
  final VoidCallback onTap;

  const MapElementWidget({
    super.key,
    required this.element,
    required this.isEditMode,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Come per i tavoli, usiamo GestureDetector per permettere il trascinamento
    return GestureDetector(
    // Se clicco il muro in Edit Mode, si apre il popup!
      onTap: isEditMode ? onTap : null,
      onPanUpdate: isEditMode ? onPanUpdate : null,
      onPanEnd: isEditMode ? (details) => onPanEnd() : null,
      
      // 🔄 MAGIA: Ruotiamo il widget!
      // Flutter usa i radianti. Per convertire i gradi (0-360) in radianti si fa: gradi * pigreco / 180
      child: Transform.rotate(
        angle: element.rotation * 3.1415927 / 180,
        child: _buildShape(),
      ),
    );
  }

  // Questa funzione decide l'aspetto visivo in base al tipo ('type')
  Widget _buildShape() {
    switch (element.type) {
      
      // 🧱 SE È UN MURO
      case 'WALL':
        return Container(
          width: element.width,
          height: element.height,
          decoration: BoxDecoration(
            color: Colors.grey.shade800, // Grigio scuro per i muri
            borderRadius: BorderRadius.circular(4),
            // Se siamo in modalità modifica, mettiamo un bordino rosso per far capire che è selezionabile
            border: isEditMode ? Border.all(color: Colors.redAccent, width: 2) : null,
          ),
        );

      // 🚪 SE È UNA PORTA
      case 'DOOR':
        return Container(
          width: element.width,
          height: element.height,
          decoration: BoxDecoration(
            color: Colors.brown.shade400, // Marrone per la porta
            borderRadius: BorderRadius.circular(2),
            border: isEditMode ? Border.all(color: Colors.redAccent, width: 2) : null,
          ),
          // Disegniamo una piccola riga per fare la maniglia
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              width: 4, height: 12, color: Colors.yellow.shade700,
            ),
          ),
        );

      // 🔤 SE È UN TESTO (es. "Cucina")
      case 'TEXT':
        return Container(
          // Diamo un colore di sfondo semi-trasparente solo se stiamo modificando,
          // altrimenti il testo sembrerà fluttuare magicamente sulla mappa
          color: isEditMode ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          padding: const EdgeInsets.all(8),
          child: Text(
            element.text ?? 'Testo vuoto',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        );

      // Caso di emergenza se il tipo non è riconosciuto
      default:
        return Container(width: 50, height: 50, color: Colors.red);
    }
  }
}