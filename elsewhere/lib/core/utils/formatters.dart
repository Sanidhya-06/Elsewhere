import 'package:intl/intl.dart';

/// Display formatting and parsing helpers. Money is always an integer count
/// of minor units.
class EvFormat {
  EvFormat._();

  static const Map<String, String> _symbols = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
  };

  static String currencySymbol(String currency) =>
      _symbols[currency] ?? '$currency ';

  /// Formats [minor] units, e.g. 123456 INR -> "₹1,234.56".
  static String money(int minor, String currency, {bool showPlus = false}) {
    final sign = minor < 0 ? '-' : (showPlus && minor > 0 ? '+' : '');
    final abs = minor.abs();
    final whole = NumberFormat('#,##0').format(abs ~/ 100);
    final cents = (abs % 100).toString().padLeft(2, '0');
    return '$sign${currencySymbol(currency)}$whole.$cents';
  }

  /// Parses user input such as "1,200.50" into minor units. Returns null for
  /// anything that is not a plain amount with at most two decimals.
  static int? parseMinor(String input) {
    final cleaned = input.trim().replaceAll(',', '').replaceAll(' ', '');
    final match = RegExp(r'^(\d{1,9})(?:\.(\d{1,2}))?$').firstMatch(cleaned);
    if (match == null) return null;
    final whole = int.parse(match.group(1)!);
    final fraction = (match.group(2) ?? '').padRight(2, '0');
    return whole * 100 + int.parse(fraction);
  }

  /// Editable text for an amount, e.g. 12050 -> "120.50".
  static String minorToInput(int minor) {
    final whole = minor ~/ 100;
    final cents = (minor % 100).toString().padLeft(2, '0');
    return '$whole.$cents';
  }

  static String date(DateTime d) => DateFormat('d MMM yyyy').format(d);

  static String dayLong(DateTime d) => DateFormat('EEE, d MMM').format(d);

  static String month(DateTime d) => DateFormat('MMMM yyyy').format(d);

  /// "3-9 Mar 2026", "28 Feb - 4 Mar 2026" or a single date.
  static String dateRange(DateTime start, DateTime end) {
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return date(start);
    }
    if (start.year == end.year && start.month == end.month) {
      return '${start.day}–${DateFormat('d MMM yyyy').format(end)}';
    }
    if (start.year == end.year) {
      return '${DateFormat('d MMM').format(start)} – ${date(end)}';
    }
    return '${date(start)} – ${date(end)}';
  }

  /// Converts "HH:mm" to a friendly 12-hour time. Returns the input unchanged
  /// if it cannot be parsed.
  static String time(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return hhmm;
    return DateFormat('h:mm a').format(DateTime(2000, 1, 1, h, m));
  }

  static String initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  static String plural(int count, String singular, [String? plural]) =>
      '$count ${count == 1 ? singular : (plural ?? '${singular}s')}';
}
