import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 📡 1. IMPORTIAMO L'ANTENNA E L'AUTENTICAZIONE
import '../../core/socket_service.dart'; 
import '../../features/auth/presentation/auth_controller.dart'; 

// 2. TRASFORMATO IN ConsumerStatefulWidget
class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  
  @override
  void initState() {
    super.initState();
    // 🚀 3. APPENA SI APRE L'APP, ACCENDIAMO L'ANTENNA!
    // Usiamo addPostFrameCallback per aspettare che Flutter abbia finito di disegnare lo schermo la prima volta
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).value;
      
      // Se l'utente è loggato e ha un ristorante associato, accendiamo il WebSocket!
      if (user != null && user.tenantId != null) {
        ref.read(socketServiceProvider).connect(user.tenantId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // La pagina corrente viene visualizzata qui (nota il 'widget.' aggiunto)
      body: widget.navigationShell,
      
      // Usiamo un widget separato per la BottomNavBar per pulizia
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        // Usiamo le destinazioni basate sui tuoi mockup
        destinations: const [
          NavigationDestination(label: 'Home', icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home)),
          NavigationDestination(label: 'Calendario', icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month)),
          NavigationDestination(label: 'Attività', icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long)),
          NavigationDestination(label: 'Gestione', icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people)),
          NavigationDestination(label: 'Impostazioni', icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings)),
        ],
        onDestinationSelected: (index) => _onTap(context, index),
      ),
    );
  }

  /// Cambia ramo della navigazione senza perdere lo stato delle pagine
  void _onTap(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      // Supporta la navigazione alla pagina iniziale del ramo se già selezionato
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}