# Elsewhere: build status

This is a more complete project snapshot, but it remains **unverified** because Flutter was unavailable in the authoring environment.

## Written in this snapshot
- Project config: `pubspec.yaml`, `analysis_options.yaml`, `firebase.json`, `firestore.indexes.json`, `tool/setup.sh`
- Design system: tokens, theme, shared widgets, formatters, validators
- Models: users, trips, members, itinerary activities, packing items, expenses, settlements
- Repositories: Firebase auth, trips/invites, itinerary, packing, expenses
- Providers: auth, trips, trip workspace with live derived expense balances
- Routing: `main.dart`, `app.dart`, `lib/core/router/app_router.dart`, route constants and auth redirect helper
- Firebase options placeholder with a setup-required screen if configuration is missing
- Screens: splash, login, forgot password, home, create/join trip, trip overview, members, itinerary, add/edit activity, packing, budget, add expense, expense history, settlements, profile
- Firestore security rules for users, trips, memberships, invites, itinerary, packing, expenses, settlements
- Unit tests for expense calculations, validators, redirect logic, money parsing, and trip model basics
- README setup instructions and explicit verification status

## Required before the app can be considered runnable
1. Install Flutter (3.24 or newer) and run `flutter doctor`.
2. Run `flutterfire configure` and replace `lib/firebase_options.dart` with generated options.
3. Run `flutter pub get`, `flutter analyze`, and `flutter test`; fix any errors those commands report.
4. Validate `firestore.rules` using Firebase Emulator Suite tests, especially invite joining and membership changes.
5. Run on at least one target platform and manually test auth, trip creation/joining, itinerary, packing, expenses, and settlements.

**No compile, analyzer, test, emulator, or device run is claimed as passed.**
