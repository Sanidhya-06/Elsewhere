import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/routes.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trip_workspace.dart';
import '../../repositories/expense_repository.dart';
import '../../repositories/itinerary_repository.dart';
import '../../repositories/packing_repository.dart';
import '../../repositories/trip_repository.dart';

/// The workspace for one trip. It owns the live [TripWorkspace] state for as
/// long as the user is anywhere inside `/trips/:tripId/...`, shows the
/// trip-specific bottom navigation, and refuses to show any trip content until
/// the server has confirmed the user can read the trip.
class TripShell extends StatelessWidget {
  const TripShell({
    super.key,
    required this.tripId,
    required this.location,
    required this.child,
  });

  final String tripId;
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final uid = context.select<AuthProvider, String?>((a) => a.user?.uid);
    if (uid == null) {
      return const Scaffold(body: EvLoading());
    }
    return ChangeNotifierProvider<TripWorkspace>(
      key: ValueKey('trip-$tripId-$uid'),
      create: (ctx) => TripWorkspace(
        tripId: tripId,
        currentUserId: uid,
        trips: ctx.read<TripRepository>(),
        itinerary: ctx.read<ItineraryRepository>(),
        packing: ctx.read<PackingRepository>(),
        expenses: ctx.read<ExpenseRepository>(),
      ),
      child: _TripShellView(tripId: tripId, location: location, child: child),
    );
  }
}

class _TripShellView extends StatelessWidget {
  const _TripShellView({
    required this.tripId,
    required this.location,
    required this.child,
  });

  final String tripId;
  final String location;
  final Widget child;

  String get _path => Uri.parse(location).path;

  /// Add/edit forms cover the workspace navigation.
  bool get _isForm =>
      _path.contains('/activities/') || _path.endsWith('/expenses/new');

  int get _index {
    final p = _path;
    if (p.contains('/itinerary') || p.contains('/activities')) return 1;
    if (p.contains('/packing')) return 2;
    if (p.contains('/budget') ||
        p.contains('/expenses') ||
        p.contains('/settlements')) {
      return 3;
    }
    if (p.contains('/members')) return 4;
    return 0;
  }

  void _goTab(BuildContext context, int i) {
    final target = switch (i) {
      1 => AppRoutes.itinerary(tripId),
      2 => AppRoutes.packing(tripId),
      3 => AppRoutes.budget(tripId),
      4 => AppRoutes.members(tripId),
      _ => AppRoutes.trip(tripId),
    };
    if (target != location) context.go(target);
  }

  /// Back from a tab returns to the trip overview; back from the overview
  /// returns to the trips list. Pushed pages (forms, history) are popped by
  /// the nested navigator before this is ever called.
  void _onBack(BuildContext context) {
    if (_path == AppRoutes.trip(tripId)) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.trip(tripId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<TripWorkspace>();

    final Widget body;
    if (ws.accessError != null) {
      body = Scaffold(
        body: SafeArea(
          child: EvErrorState(
            title: 'Trip unavailable',
            message: ws.accessError!,
            retryLabel: 'Back to your trips',
            onRetry: () => context.go(AppRoutes.home),
          ),
        ),
      );
    } else if (!ws.isReady) {
      body = const Scaffold(body: EvLoading(message: 'Opening trip'));
    } else {
      body = child;
    }

    final showNav = ws.isReady && ws.accessError == null && !_isForm;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack(context);
      },
      child: Scaffold(
        body: body,
        bottomNavigationBar: showNav
            ? NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (i) => _goTab(context, i),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.explore_outlined),
                    selectedIcon: Icon(Icons.explore),
                    label: 'Trip',
                    tooltip: 'Trip overview',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.event_note_outlined),
                    selectedIcon: Icon(Icons.event_note),
                    label: 'Itinerary',
                    tooltip: 'Itinerary',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.checklist_outlined),
                    selectedIcon: Icon(Icons.checklist),
                    label: 'Packing',
                    tooltip: 'Packing list',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.account_balance_wallet_outlined),
                    selectedIcon: Icon(Icons.account_balance_wallet),
                    label: 'Budget',
                    tooltip: 'Budget and expenses',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.group_outlined),
                    selectedIcon: Icon(Icons.group),
                    label: 'People',
                    tooltip: 'Travellers',
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
