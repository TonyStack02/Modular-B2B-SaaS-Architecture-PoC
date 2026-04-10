import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/presentation/register_screen.dart';
import 'package:frontend/features/booking/presentation/calendar_screen.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/dashboard/presentation/home_screen.dart'; 
import '../features/catalog/presentation/catalog_screen.dart';
import '../features/pos/presentation/pos_screen.dart';
import '../features/floor_plan/presentation/floor_plan_screen.dart';
import 'navigation/scaffold_with_nav_bar.dart'; 
import '../features/hr/presentation/management_screen.dart';
import '../features/hr/presentation/add_employee_screen.dart';
import '../features/crm/presentation/add_customer_screen.dart';
import '../features/activity/presentation/activity_screen.dart'; 
import '../features/analytics/presentation/analytics_screen.dart';

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

      // 1. DEFINIAMO LE "ZONE SICURE": 
      // Qui aggiungiamo tutte le rotte accessibili senza essere loggati.
      final isAuthPath = state.matchedLocation == '/login' || 
                         state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthPath) {
        return '/login';
      }

      if (isLoggedIn && isAuthPath) {
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

      // Rotta pubblica per la Registrazione
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
    
      //Il nostro Menu (Protetta in automatico dal redirect!)
      GoRoute(
        path: '/catalog',
        builder: (context, state) => const CatalogScreen(),
      ),

      GoRoute(
        path: '/floor-plan',
        builder: (context, state) => const FloorPlanScreen(),
      ),

      // La Cassa (POS)
      GoRoute(
        path: '/pos/:resourceId',
        builder: (context, state) {
          // Estraiamo l'ID dall'URL e lo passiamo alla pagina!
          final resourceId = state.pathParameters['resourceId']!;
          return PosScreen(resourceId: resourceId);
        }
      ),

      GoRoute(
        path: '/add-employee',
        builder: (context, state) => const AddEmployeeScreen(),
      ),

      GoRoute(
        path: '/add-customer',
        builder: (context, state) => const AddCustomerScreen(),
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
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Ramo 2: CALENDARIO
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),

          // Ramo 3: ATTIVITÀ (CASSA)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/activity',
                builder: (context, state) => const ActivityScreen(),
              ),
            ],
          ),

          // Ramo 4: GESTIONE
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/management',
                builder: (context, state) => const ManagementScreen(),
              ),
              
            ],
          ),

          // Ramo 5: IMPOSTAZIONI
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Impostazioni Generali', style: TextStyle(fontSize: 20)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      // Il tasto per l'Owner per disegnare la mappa e spostare i tavoli
                      onPressed: () => context.push('/floor-plan'),
                      child: const Text('Disegna Mappa Ristorante 🗺️'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 📊 NUOVO RAMO 6: STATISTICHE E ANALYTICS
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics', // Il percorso URL
                // Ricordati di importare in cima al file: import '../features/analytics/presentation/analytics_screen.dart';
                builder: (context, state) => const AnalyticsScreen(), 
              ),
            ],
          ),
        ],
      ),
    ],
  ); // Chiusura GoRouter
}); // Chiusura Provider