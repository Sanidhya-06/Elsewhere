import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';

/// The global navigation for the signed-in app: Trips and Profile. Trip
/// workspaces have their own separate navigation (see TripShell).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  int get _index => location.startsWith(AppRoutes.profile) ? 1 : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) =>
            context.go(i == 0 ? AppRoutes.home : AppRoutes.profile),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.luggage_outlined),
            selectedIcon: Icon(Icons.luggage),
            label: 'Trips',
            tooltip: 'Your trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
            tooltip: 'Profile and settings',
          ),
        ],
      ),
    );
  }
}
