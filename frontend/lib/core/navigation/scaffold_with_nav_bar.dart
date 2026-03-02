import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  /// La "shell" contiene lo stato della navigazione e le pagine figlie
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // La pagina corrente viene visualizzata qui
      body: navigationShell,
      // Usiamo un widget separato per la BottomNavBar per pulizia
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
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
    navigationShell.goBranch(
      index,
      // Supporta la navigazione alla pagina iniziale del ramo se già selezionato
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}