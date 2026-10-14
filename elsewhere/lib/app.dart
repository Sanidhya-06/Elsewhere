import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_tokens.dart';
import 'core/router/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/trips_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/expense_repository.dart';
import 'repositories/itinerary_repository.dart';
import 'repositories/packing_repository.dart';
import 'repositories/trip_repository.dart';

class ElsewhereApp extends StatefulWidget {
  const ElsewhereApp({super.key});

  @override
  State<ElsewhereApp> createState() => _ElsewhereAppState();
}

class _ElsewhereAppState extends State<ElsewhereApp> {
  late final AuthProvider _auth;
  late final TripsProvider _trips;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    final db = FirebaseFirestore.instance;
    final authRepository = FirebaseAuthRepository(FirebaseAuth.instance, db);
    _auth = AuthProvider(authRepository);
    _trips = TripsProvider(FirestoreTripRepository(db));
    _auth.addListener(_syncTripsUser);
    _syncTripsUser();
    _appRouter = AppRouter(auth: _auth);
  }

  void _syncTripsUser() => _trips.bindUser(_auth.user?.uid);

  @override
  void dispose() {
    _auth.removeListener(_syncTripsUser);
    _appRouter.dispose();
    _auth.dispose();
    _trips.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: _auth),
          ChangeNotifierProvider<TripsProvider>.value(value: _trips),
          Provider<TripRepository>.value(
              value: FirestoreTripRepository(FirebaseFirestore.instance)),
          Provider<ItineraryRepository>.value(
              value: FirestoreItineraryRepository(FirebaseFirestore.instance)),
          Provider<PackingRepository>.value(
              value: FirestorePackingRepository(FirebaseFirestore.instance)),
          Provider<ExpenseRepository>.value(
              value: FirestoreExpenseRepository(FirebaseFirestore.instance)),
        ],
        child: MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: buildEvTheme(),
          routerConfig: _appRouter.router,
        ),
      );
}

/// Visible, actionable fallback instead of a cryptic startup crash.
class FirebaseSetupRequiredApp extends StatelessWidget {
  const FirebaseSetupRequiredApp({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: buildEvTheme(),
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(EvSpace.s24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Elsewhere', style: EvTypography.display(size: 40)),
                      const SizedBox(height: EvSpace.s16),
                      Text('Connect Firebase to get going',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: EvSpace.s12),
                      const Text(
                          'This project contains placeholder Firebase options. From the project root, run `flutterfire configure`, then replace lib/firebase_options.dart with the generated configuration.'),
                      const SizedBox(height: EvSpace.s16),
                      SelectableText(message,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
