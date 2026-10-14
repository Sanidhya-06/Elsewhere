/// App-wide constants. User-facing product name lives here so the brand is
/// defined in exactly one place.
class AppConstants {
  AppConstants._();

  static const String appName = 'Elsewhere';
  static const String tagline = 'Plan trips with friends, all in one place.';
  static const String version = '1.0.0';

  /// Supported currencies. All use two decimal places, so every amount in the
  /// app is stored as an integer count of minor units (paise, cents, pence).
  static const String defaultCurrency = 'INR';
  static const List<String> currencies = ['INR', 'USD', 'EUR', 'GBP'];

  static const List<String> expenseCategories = [
    'Stay',
    'Food',
    'Transport',
    'Activities',
    'Shopping',
    'Other',
  ];

  /// Invite codes avoid look-alike characters (0/O, 1/I).
  static const int inviteCodeLength = 8;
  static const String inviteCodeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Longest trip the planner will lay out day by day.
  static const int maxTripDays = 90;

  static const int maxNameLength = 80;
  static const int maxNoteLength = 500;
}
