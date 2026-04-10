// lib/features/navigation/scaffold_with_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 📡 1. IMPORTIAMO L'ANTENNA E L'AUTENTICAZIONE
import '../../core/socket_service.dart'; 
import '../../features/auth/presentation/auth_controller.dart'; 

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).value;
      
      if (user != null && user.tenantId != null) {
        ref.read(socketServiceProvider).connect(user.tenantId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        destinations: const [
          NavigationDestination(label: 'Home', icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home)),
          NavigationDestination(label: 'Calendario', icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month)),
          NavigationDestination(label: 'Attività', icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long)),
          NavigationDestination(label: 'Gestione', icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people)),
          NavigationDestination(label: 'Impostazioni', icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings)),
          
          // 📊 IL NUOVO BOTTONE DELLE STATISTICHE (Indice 5)
          NavigationDestination(label: 'Statistiche', icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart)),
        ],
        onDestinationSelected: (index) => _onTap(context, index),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}