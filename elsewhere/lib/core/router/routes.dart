/// Central route definitions. Path patterns are used when registering routes;
/// the builder methods produce concrete locations for navigation.
class AppRoutes {
  AppRoutes._();

  // Patterns.
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String createTrip = '/trips/create';
  static const String joinTrip = '/join';

  static const String tripPattern = '/trips/:tripId';
  static const String membersPattern = '/trips/:tripId/members';
  static const String itineraryPattern = '/trips/:tripId/itinerary';
  static const String newActivityPattern = '/trips/:tripId/activities/new';
  static const String editActivityPattern =
      '/trips/:tripId/activities/:activityId/edit';
  static const String packingPattern = '/trips/:tripId/packing';
  static const String budgetPattern = '/trips/:tripId/budget';
  static const String newExpensePattern = '/trips/:tripId/expenses/new';
  static const String expensesPattern = '/trips/:tripId/expenses';
  static const String settlementsPattern = '/trips/:tripId/settlements';

  // Concrete locations. Ids are encoded so they are always one path segment.
  static String _t(String tripId) => '/trips/${Uri.encodeComponent(tripId)}';

  static String trip(String tripId) => _t(tripId);
  static String members(String tripId) => '${_t(tripId)}/members';
  static String itinerary(String tripId) => '${_t(tripId)}/itinerary';
  static String newActivity(String tripId) => '${_t(tripId)}/activities/new';
  static String editActivity(String tripId, String activityId) =>
      '${_t(tripId)}/activities/${Uri.encodeComponent(activityId)}/edit';
  static String packing(String tripId) => '${_t(tripId)}/packing';
  static String budget(String tripId) => '${_t(tripId)}/budget';
  static String newExpense(String tripId) => '${_t(tripId)}/expenses/new';
  static String expenses(String tripId) => '${_t(tripId)}/expenses';
  static String settlements(String tripId) => '${_t(tripId)}/settlements';

  static String joinWithCode(String code) =>
      '$joinTrip?code=${Uri.encodeQueryComponent(code)}';

  /// Reserved first segment after `/trips/` that is not a trip id.
  static const String createSegment = 'create';

  /// Extracts the trip id from any `/trips/<id>/...` location, or null if the
  /// location is not inside a trip.
  static String? tripIdFromLocation(String location) {
    final segments = Uri.parse(location).pathSegments;
    if (segments.length < 2 || segments[0] != 'trips') return null;
    final id = segments[1];
    if (id.isEmpty || id == createSegment) return null;
    return id;
  }
}
