import '../constants/app_constants.dart';
import 'formatters.dart';

/// Reusable form validators. Each returns an error message, or null if valid.
class Validators {
  Validators._();

  static final RegExp _email =
      RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$');

  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    return null;
  }

  static String? name(String? value, {String field = 'Name'}) {
    final missing = required(value, field: field);
    if (missing != null) return missing;
    if (value!.trim().length > AppConstants.maxNameLength) {
      return '$field must be ${AppConstants.maxNameLength} characters or fewer.';
    }
    return null;
  }

  static String? email(String? value) {
    final missing = required(value, field: 'Email');
    if (missing != null) return missing;
    if (!_email.hasMatch(value!.trim())) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Use at least 8 characters.';
    return null;
  }

  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    return null;
  }

  /// A positive amount, e.g. an expense.
  static String? amount(String? value, {String field = 'Amount'}) {
    final missing = required(value, field: field);
    if (missing != null) return missing;
    final minor = EvFormat.parseMinor(value!);
    if (minor == null) {
      return 'Enter a number with up to 2 decimals, like 1200.50.';
    }
    if (minor <= 0) return '$field must be greater than zero.';
    return null;
  }

  /// An optional amount that may be blank or zero, e.g. activity cost.
  static String? optionalAmount(String? value, {String field = 'Amount'}) {
    if (value == null || value.trim().isEmpty) return null;
    if (EvFormat.parseMinor(value) == null) {
      return 'Enter a number with up to 2 decimals, like 1200.50.';
    }
    return null;
  }

  static String? note(String? value) {
    if (value != null && value.length > AppConstants.maxNoteLength) {
      return 'Keep notes under ${AppConstants.maxNoteLength} characters.';
    }
    return null;
  }

  static String? optionalHttpsUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return 'Use a link that starts with https://';
    }
    if (value.trim().length > 500) return 'That link is too long.';
    return null;
  }

  /// Validates a trip date range and returns the first problem found.
  static String? dateRange(DateTime? start, DateTime? end) {
    if (start == null) return 'Choose a start date.';
    if (end == null) return 'Choose an end date.';
    if (end.isBefore(start)) return 'The end date cannot be before the start.';
    final days = end.difference(start).inDays + 1;
    if (days > AppConstants.maxTripDays) {
      return 'Trips can span at most ${AppConstants.maxTripDays} days.';
    }
    return null;
  }

  static String? requiredDate(DateTime? value, {String field = 'Date'}) {
    if (value == null) return 'Choose a date.';
    return null;
  }

  /// Normalizes user input to the canonical invite code form.
  static String normalizeInviteCode(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  static String? inviteCode(String? value) {
    final missing = required(value, field: 'Invite code');
    if (missing != null) return missing;
    final code = normalizeInviteCode(value!);
    final valid = RegExp(
        '^[${AppConstants.inviteCodeAlphabet}]{${AppConstants.inviteCodeLength}}\$');
    if (!valid.hasMatch(code)) {
      return 'Invite codes are ${AppConstants.inviteCodeLength} letters and numbers.';
    }
    return null;
  }
}
