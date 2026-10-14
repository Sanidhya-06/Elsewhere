# Elsewhere

Elsewhere is a collaborative travel companion for planning trips with friends. This repository snapshot contains the Flutter client, Firebase repositories, trip planning screens, shared expense calculations, and Firestore security rules.

## Stack

- Flutter and Dart
- Firebase Authentication
- Cloud Firestore
- Provider for app state
- GoRouter for declarative navigation and auth redirects

## Requirements

- Flutter SDK `>=3.24.0`
- Dart SDK `>=3.5.0 <4.0.0`
- A Firebase project with Email/Password authentication enabled and Cloud Firestore created
- FlutterFire CLI for platform configuration

## Setup

1. Install Flutter and verify it is available:
   ```bash
   flutter doctor
   ```
2. Install the FlutterFire CLI if it is not installed:
   ```bash
   dart pub global activate flutterfire_cli
   ```
3. From this project directory, configure Firebase for the platforms you intend to run:
   ```bash
   flutterfire configure
   ```
   Replace `lib/firebase_options.dart` with the generated file. The checked-in file contains deliberate placeholders and is not a real Firebase configuration. Until this is done, the app shows a setup-required screen rather than trying to use fake credentials.
4. In Firebase Console, enable **Authentication → Sign-in method → Email/Password** and create a Cloud Firestore database.
5. Deploy Firestore rules and indexes:
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```
6. Fetch dependencies and run the app:
   ```bash
   flutter pub get
   flutter run
   ```

## Checks

Run these after installing Flutter:

```bash
flutter analyze
flutter test
```

**Verification status:** these commands have not been run in the authoring environment because Flutter was unavailable. The included tests are written but not yet verified by a Flutter runtime. Do not treat this snapshot as a compiled or production-validated build.

## Project map

```text
lib/
  main.dart                    Firebase startup and setup fallback
  app.dart                     Theme, providers, MaterialApp.router
  firebase_options.dart        FlutterFire configuration placeholder
  core/
    router/                    Route constants, auth redirect, GoRouter
    theme/                     Elsewhere design tokens and theme
    widgets/                   Shared UI primitives
    utils/                     Validation, date, formatting helpers
  features/
    auth/                      Splash, login, password reset
    home/                      Trips list and global navigation
    trips/                     Create/join trip, overview, members
    itinerary/                 Itinerary and activity editor
    packing/                   Shared packing checklist
    expenses/                  Budget, expense entry/history, settlements
    profile/                   Profile and sign-out
  models/                      Firestore data models
  providers/                   Auth, trips, trip workspace state
  repositories/                Firebase data access
  services/                    Expense split and settlement calculations
test/                           Unit tests
firestore.rules                 Firestore authorization rules
firestore.indexes.json          Firestore composite indexes
```

## Data and security notes

- Monetary values are stored as integer minor units (paise/cents) to avoid floating-point rounding.
- Expense shares are stored when the expense is created so future changes to split logic do not rewrite past expenses.
- Firestore rules are the actual authorization boundary. Router redirects are UX only.
- Invite codes are readable by authenticated users who know the code; listing invite documents is denied.
- Review rules against your final Firestore schema and run the Firebase Emulator Suite security-rules tests before production deployment.

## Current limitations

- Firebase configuration is intentionally incomplete until `flutterfire configure` is run.
- This project snapshot has not been compiled, analysed, or executed in a Flutter environment.
- Automated tests cover pure calculations, format parsing, validators, model basics, and redirect decisions. They do not replace integration tests against the Firebase Emulator Suite.
