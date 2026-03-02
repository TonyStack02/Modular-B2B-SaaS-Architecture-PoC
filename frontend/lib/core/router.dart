import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'navigation/scaffold_with_nav_bar.dart'; 

// Importiamo le pagine 
// Per ora useremo dei placeholder
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: '/home',
  navigatorKey: _rootNavigatorKey,
  routes: [
    // La "Shell" è la cornice che contiene la BottomNavBar
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        // Restituiamo il widget che disegna la barra e il contenuto
        return ScaffoldWithNavBar(
          navigationShell: navigationShell
        );
      },

      branches: [
        // Ramo 1: HOME
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder:(context, state) => const Center(child: Text('Home - Dashboard Live'),),
            ),
          ],
        ),

        // Ramo 2: CALENDARIO
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calendar',
              builder: (context, state) => const Center(child: Text('Calendario - Mappa Tavoli'),),
            ),
          ],
        ),

        // Ramo 3: ATTIVITÀ (CASSA)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/activity',
              builder: (context, state) => Center(child: Text('Attività - Conti Aperti')),
            ),
          ],
        ),

        // Ramo 4: GESTIONE
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/management',
              builder: (context, state) => Center(child: Text('Gestione - Risorse'),),
            ),
          ]
        ),

        // Ramo 5: IMPOSTAZIONI
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => Center(child: Text('Impostazioni')),),
          ]
        )

      ],
    ),
  ],
);
