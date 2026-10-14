import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/main_shell.dart';
import '../../features/itinerary/activity_form_screen.dart';
import '../../features/itinerary/itinerary_screen.dart';
import '../../features/trips/create_trip_screen.dart';
import '../../features/trips/join_trip_screen.dart';
import '../../features/trips/members_screen.dart';
import '../../features/trips/trip_overview_screen.dart';
import '../../features/trips/trip_shell.dart';
import '../../features/packing/packing_screen.dart';
import '../../features/expenses/add_expense_screen.dart';
import '../../features/expenses/budget_screen.dart';
import '../../features/expenses/expense_history_screen.dart';
import '../../features/expenses/settlements_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../providers/auth_provider.dart';
import 'redirect.dart';
import 'routes.dart';

/// Owns GoRouter and refreshes its auth guard whenever the session changes.
class AppRouter {
  AppRouter({required AuthProvider auth}) : _auth = auth {
    _refresh = _RouterRefresh(auth);
    router = GoRouter(
      initialLocation: AppRoutes.splash,
      debugLogDiagnostics: kDebugMode,
      refreshListenable: _refresh,
      redirect: (context, state) => resolveRedirect(state.uri, _auth.status),
      routes: [
        GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
        GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
        GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordScreen()),
        GoRoute(path: AppRoutes.home, builder: (_, state) => _global(state.uri.path, const HomeScreen())),
        GoRoute(path: AppRoutes.profile, builder: (_, state) => _global(state.uri.path, const ProfileScreen())),
        GoRoute(path: AppRoutes.createTrip, builder: (_, state) => _global(state.uri.path, const CreateTripScreen())),
        GoRoute(path: AppRoutes.joinTrip, builder: (_, state) => _global(state.uri.path, JoinTripScreen(initialCode: state.uri.queryParameters['code']))),
        GoRoute(path: AppRoutes.tripPattern, builder: (_, state) => _trip(state, const TripOverviewScreen())),
        GoRoute(path: AppRoutes.membersPattern, builder: (_, state) => _trip(state, const MembersScreen())),
        GoRoute(path: AppRoutes.itineraryPattern, builder: (_, state) => _trip(state, const ItineraryScreen())),
        GoRoute(path: AppRoutes.newActivityPattern, builder: (_, state) => _trip(state, const ActivityFormScreen())),
        GoRoute(path: AppRoutes.editActivityPattern, builder: (_, state) => _trip(state, ActivityFormScreen(activityId: state.pathParameters['activityId']))),
        GoRoute(path: AppRoutes.packingPattern, builder: (_, state) => _trip(state, PackingScreen(tripId: state.pathParameters['tripId']!))),
        GoRoute(path: AppRoutes.budgetPattern, builder: (_, state) => _trip(state, BudgetScreen(tripId: state.pathParameters['tripId']!))),
        GoRoute(path: AppRoutes.newExpensePattern, builder: (_, state) => _trip(state, AddExpenseScreen(tripId: state.pathParameters['tripId']!))),
        GoRoute(path: AppRoutes.expensesPattern, builder: (_, state) => _trip(state, ExpenseHistoryScreen(tripId: state.pathParameters['tripId']!))),
        GoRoute(path: AppRoutes.settlementsPattern, builder: (_, state) => _trip(state, SettlementsScreen(tripId: state.pathParameters['tripId']!))),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Page not found.\n${state.error ?? state.uri}', textAlign: TextAlign.center),
        )),
      ),
    );
  }

  final AuthProvider _auth;
  late final _RouterRefresh _refresh;
  late final GoRouter router;

  Widget _global(String location, Widget child) => MainShell(location: location, child: child);

  Widget _trip(GoRouterState state, Widget child) => TripShell(
        tripId: state.pathParameters['tripId']!,
        location: state.uri.path,
        child: child,
      );

  void dispose() {
    router.dispose();
    _refresh.dispose();
  }
}

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._auth) { _auth.addListener(notifyListeners); }
  final AuthProvider _auth;
  @override
  void dispose() {
    _auth.removeListener(notifyListeners);
    super.dispose();
  }
}
