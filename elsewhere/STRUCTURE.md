# Elsewhere project structure

- [x] `lib/main.dart`: Firebase startup and safe setup fallback
- [x] `lib/app.dart`: theme, providers, router-backed app shell
- [x] `lib/firebase_options.dart`: placeholder options, intentionally requires FlutterFire setup
- [x] `lib/core/router/app_router.dart`: GoRouter routes and auth refresh
- [x] `lib/core/router/routes.dart`: canonical route paths and location helpers
- [x] `lib/core/router/redirect.dart`: auth redirect decisions
- [x] `lib/features/auth/`: splash, login/sign-up, forgot password
- [x] `lib/features/home/`: trips dashboard and global navigation
- [x] `lib/features/trips/`: create/join, overview, members, trip shell
- [x] `lib/features/itinerary/`: itinerary and add/edit activity
- [x] `lib/features/packing/packing_screen.dart`: shared packing checklist
- [x] `lib/features/expenses/`: budget, add expense, history, settlements
- [x] `lib/features/profile/profile_screen.dart`: display name and sign-out
- [x] `lib/models/`: user, trip, membership, activity, packing, expense, settlement
- [x] `lib/repositories/`: Firebase data access
- [x] `lib/providers/`: authentication, trip list, trip workspace
- [x] `lib/services/expense_calculator.dart`: deterministic splitting and settle-up math
- [x] `firestore.rules`: baseline access rules for app collections
- [x] `test/`: unit tests for calculations, validators, redirects, and model/formatting basics
- [x] `README.md`: setup and verification instructions

## Route map

| Route | Screen |
|---|---|
| `/` | Splash / session resolution |
| `/login` | Sign in and create account |
| `/forgot-password` | Password reset |
| `/home` | Trips dashboard |
| `/profile` | Profile and settings |
| `/trips/create` | Create trip |
| `/join?code=...` | Join trip |
| `/trips/:tripId` | Trip overview |
| `/trips/:tripId/members` | Trip members |
| `/trips/:tripId/itinerary` | Itinerary |
| `/trips/:tripId/activities/new` | Add activity |
| `/trips/:tripId/activities/:activityId/edit` | Edit activity |
| `/trips/:tripId/packing` | Packing checklist |
| `/trips/:tripId/budget` | Budget dashboard |
| `/trips/:tripId/expenses/new` | Add expense |
| `/trips/:tripId/expenses` | Expense history |
| `/trips/:tripId/settlements` | Split and settlement summary |

## Verification status

Written, not compiled. Flutter and Dart were not available in the authoring environment. See `STATUS.md` for the required next steps.
