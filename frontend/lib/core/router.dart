import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import 'navigation/scaffold_with_nav_bar.dart'; 

final _rootNavigatorKey = GlobalKey<NavigatorState>();

// 1. IL ROUTER PROVIDER
final routerProvider = Provider<GoRouter>((ref) {

  // 2. L'ASCOLTO dello stato di autenticazione
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/home',
    navigatorKey: _rootNavigatorKey,
    
    // 3. REDIRECT (Il Buttafuori)
    redirect: (context, state) {
      final user = authState.value;
      final isLoggedIn = user != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }

      return null;
    },
    
    routes: [
      // Rotta pubblica per il Login
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // La "Shell" con la BottomNavBar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(
            navigationShell: navigationShell,
          );
        },
        branches: [
          // Ramo 1: HOME
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const Center(child: Text('Home - Dashboard Live')),
              ),
            ],
          ),

          // Ramo 2: CALENDARIO
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const Center(child: Text('Calendario - Mappa Tavoli')),
              ),
            ],
          ),

          // Ramo 3: ATTIVITÀ (CASSA)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/activity',
                builder: (context, state) => const Center(child: Text('Attività - Conti Aperti')),
              ),
            ],
          ),

          // Ramo 4: GESTIONE
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/management',
                builder: (context, state) => const Center(child: Text('Gestione - Risorse')),
              ),
            ],
          ),

          // Ramo 5: IMPOSTAZIONI
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const Center(child: Text('Impostazioni')),
              ),
            ],
          ),
        ],
      ),
    ],
  ); // Chiusura GoRouter
}); // Chiusura Provider