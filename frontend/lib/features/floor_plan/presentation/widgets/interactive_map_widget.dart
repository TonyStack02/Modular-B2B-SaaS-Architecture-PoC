// lib/features/floor_plan/presentation/widgets/interactive_map_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/floor_plan/domain/map_element_model.dart';
import 'package:frontend/features/floor_plan/presentation/widgets/map_element_widget.dart';
import '../floor_plan_controller.dart';
import '../../domain/resource_model.dart';
import 'resource_widget.dart'; 



class InteractiveMapWidget extends ConsumerStatefulWidget {
  // Riceviamo la lista completa di tutti i tavoli da disegnare
  final List<ResourceModel> resources;
  final List<MapElementModel> mapElements; 
  
  const InteractiveMapWidget({super.key, required this.resources, required this.mapElements});

  @override
  ConsumerState<InteractiveMapWidget> createState() => _InteractiveMapWidgetState();
}

class _InteractiveMapWidgetState extends ConsumerState<InteractiveMapWidget> {
  // L'interruttore: se true, possiamo spostare i tavoli. Se false, è una mappa statica.
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- LA BARRA DEI COMANDI DELLA MAPPA ---
        Container(
          color: Colors.grey.shade100,
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Spazia i bottoni ai lati
            children: [
              
              // LA TOOLBAR DI AUTOCAD (Appare SOLO se stiamo modificando)
              if (_isEditMode) 
                Row(
                  children: [
                    // Tasto: Aggiungi Muro
                    IconButton.filledTonal(
                      icon: const Icon(Icons.rectangle),
                      tooltip: "Aggiungi Muro",
                      // 1. Aggiungiamo 'async' perché ora chiamiamo il backend
                      onPressed: () async {
                        // 2. Usiamo 'await' e la nuova funzione spawnMapElement
                        await ref.read(floorPlanControllerProvider.notifier).spawnMapElement('WALL');
                      },
                    ),
                    const SizedBox(width: 8),
                    
                    // Tasto: Aggiungi Porta
                    IconButton.filledTonal(
                      icon: const Icon(Icons.door_front_door),
                      tooltip: "Aggiungi Porta",
                      onPressed: () async {
                        await ref.read(floorPlanControllerProvider.notifier).spawnMapElement('DOOR');
                      },
                    ),
                    const SizedBox(width: 8),
                    
                    // Tasto: Aggiungi Testo
                    IconButton.filledTonal(
                      icon: const Icon(Icons.text_fields),
                      tooltip: "Aggiungi Testo",
                      onPressed: () async {
                        await ref.read(floorPlanControllerProvider.notifier).spawnMapElement('TEXT');
                      },
                    ),
                  ],
                )
              else 
                const SizedBox.shrink(), // Se non siamo in edit mode, non mostriamo nulla a sinistra

              // IL BOTTONE PER ATTIVARE/DISATTIVARE LA MODALITA' EDIT
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _isEditMode ? Colors.redAccent : Colors.orange,
                ),
                icon: Icon(_isEditMode ? Icons.check : Icons.edit_location_alt, color: Colors.white),
                label: Text(_isEditMode ? "Salva Disposizione" : "Modifica Mappa", style: const TextStyle(color: Colors.white)),
                onPressed: () {
                  setState(() {
                    _isEditMode = !_isEditMode;
                  });
                },
              ),
            ],
          ),
        ),
        
        // La Tela vera e propria (Expanded le fa prendere tutto lo spazio rimasto)
        Expanded(
          // InteractiveViewer ci permette di fare Zoom e scorrere la mappa col dito
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 2.0,
            // 🚨 TRUCCO: Se stiamo spostando i mobili (Edit Mode), blocchiamo lo scorrimento della mappa
            // altrimenti il dito muoverà sia il tavolo che il pavimento!
            panEnabled: !_isEditMode,
            scaleEnabled: !_isEditMode,
            constrained: false, // Serve per non limitarci alla grandezza dello schermo del telefono
            
            // Il nostro pavimento infinito (2000x2000 pixel)
            child: SizedBox(
              width: 2000,
              height: 2000,
              child: Stack(
                children: [
                  // Disegniamo una griglia di sfondo per aiutare l'occhio
                  Positioned.fill(
                    child: CustomPaint(painter: GridPainter()),
                  ),
                  
                  // 🧱 DISEGNIAMO I MURI, LE PORTE E I TESTI
                  ...widget.mapElements.map((element) {
                    return Positioned(
                      left: element.positionX,
                      top: element.positionY,
                      // Chiamiamo il "Pennello" che abbiamo creato prima!
                      child: MapElementWidget(
                        element: element,
                        isEditMode: _isEditMode,
                        onPanUpdate: (details) {
                          // Muoviamo il muro in tempo reale!
                          ref.read(floorPlanControllerProvider.notifier)
                             .updateMapElementPositionLocal(element.id, details.delta.dx, details.delta.dy);
                        },
                        onPanEnd: () {
                          // Quando l'Owner alza il dito, chiamiamo il backend per salvare la posizione DEFINITIVA
                          ref.read(floorPlanControllerProvider.notifier)
                             .saveMapElementBackend(element.id);                        
                             },
                             onTap: () {
                               _showElementPropertiesDialog(context, ref, element);
                             },
                      ),
                    );
                  }).toList(),
                  
                  // (Qui sotto hai già il ciclo ...widget.resources.map((table) { ... }) )

                  // Cicliamo tutti i tavoli e li "appiccichiamo" al pavimento usando Positioned
                  ...widget.resources.map((table) {
                    return Positioned(
                      // Leggiamo X e Y dal modello del tavolo
                      left: table.positionX,
                      top: table.positionY,
                      
                      // Inseriamo il nostro widget indipendente (il mattoncino)
                      child: ResourceWidget(
                        resource: table,
                        isEditMode: _isEditMode,
                        
                        onTap: () {
                          // Cosa succede se clicco il tavolo? (Quando NON siamo in Edit Mode)
                          print("Cliccato il tavolo: ${table.name}");
                          // Qui poi potremo far aprire il carrello!
                        },
                        
                        onPanUpdate: (details) {
                          // COSA SUCCEDE MENTRE TRASCINO IL DITO?
                          // Diciamo a Riverpod: "Ehi, aggiorna la memoria di questo tavolo al volo!"
                          ref.read(floorPlanControllerProvider.notifier)
                             .updateResourcePositionLocal(table.id, details.delta.dx, details.delta.dy);
                        },
                        
                        onPanEnd: () {
                          // COSA SUCCEDE QUANDO ALZO IL DITO?
                          // Diciamo a Riverpod: "Ehi, salva questa posizione definitiva sul database!"
                          ref.read(floorPlanControllerProvider.notifier)
                             .saveResourcePositionBackend(table.id);
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- POPUP PROPRIETA' ELEMENTO (AUTOCAD) ---
  void _showElementPropertiesDialog(BuildContext context, WidgetRef ref, MapElementModel element) {
    // Variabili temporanee per gli slider
    double tempWidth = element.width;
    double tempHeight = element.height;
    double tempRotation = element.rotation;
    final textController = TextEditingController(text: element.text ?? "");

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder serve per far aggiornare gli slider in tempo reale senza chiudere il popup
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Modifica ${element.type}"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Se è un TESTO, mostriamo la casella di input!
                    if (element.type == 'TEXT') ...[
                      TextField(
                        controller: textController,
                        decoration: const InputDecoration(labelText: "Testo visualizzato", border: OutlineInputBorder()),
                        onChanged: (value) {
                          ref.read(floorPlanControllerProvider.notifier).updateMapElementProps(element.id, txt: value);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // SLIDER LARGHEZZA
                    const Text("Larghezza", style: TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      value: tempWidth,
                      min: 20, max: 800,
                      onChanged: (val) {
                        setStateDialog(() => tempWidth = val);
                        // Aggiorniamo la mappa in tempo reale dietro il popup!
                        ref.read(floorPlanControllerProvider.notifier).updateMapElementProps(element.id, w: val);
                      },
                    ),

                    // SLIDER ALTEZZA (Sui testi magari l'altezza fissa basta, ma sui muri serve)
                    const Text("Altezza", style: TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      value: tempHeight,
                      min: 10, max: 800,
                      onChanged: (val) {
                        setStateDialog(() => tempHeight = val);
                        ref.read(floorPlanControllerProvider.notifier).updateMapElementProps(element.id, h: val);
                      },
                    ),

                    // SLIDER ROTAZIONE (Da 0 a 360 gradi)
                    const Text("Rotazione (Gradi)", style: TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      value: tempRotation,
                      min: 0, max: 360,
                      onChanged: (val) {
                        setStateDialog(() => tempRotation = val);
                        ref.read(floorPlanControllerProvider.notifier).updateMapElementProps(element.id, rot: val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                // BOTTONE ELIMINA (ROSSO E CATTIVO)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  icon: const Icon(Icons.delete),
                  label: const Text("Elimina"),
                  onPressed: () {
                    ref.read(floorPlanControllerProvider.notifier).deleteMapElement(element.id);
                    Navigator.pop(context); // Chiude il popup
                  },
                ),
                // BOTTONE FINE
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Fatto"),
                ),
              ],
            );
          }
        );
      },
    );
  }
}

// Lo strumento per disegnare la griglia di sfondo
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;

  
}