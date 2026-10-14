import 'package:flutter_test/flutter_test.dart';
import 'package:elsewhere/core/constants/app_constants.dart';
import 'package:elsewhere/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('accepts valid name and rejects blank name', () {
      expect(Validators.name('Sam'), isNull);
      expect(Validators.name('  '), isNotNull);
      expect(Validators.name(' Sam '), isNull);
      expect(
          Validators.name(
              List.filled(AppConstants.maxNameLength + 1, 'x').join()),
          isNotNull);
    });
    test('validates email format', () {
      expect(Validators.email('sam@example.com'), isNull);
      expect(Validators.email('  sam@example.com  '), isNull);
      expect(Validators.email('sam@'), isNotNull);
      expect(Validators.email(null), isNotNull);
    });
    test('requires passwords to have eight characters', () {
      expect(Validators.password('12345678'), isNull);
      expect(Validators.password('123'), isNotNull);
      expect(Validators.loginPassword('x'), isNull);
      expect(Validators.loginPassword(''), isNotNull);
    });
    test('validates positive and optional amounts', () {
      expect(Validators.amount('1,250.50'), isNull);
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('12.345'), isNotNull);
      expect(Validators.optionalAmount(null), isNull);
      expect(Validators.optionalAmount('0'), isNull);
      expect(Validators.optionalAmount('bad'), isNotNull);
    });
    test('validates optional notes and HTTPS links', () {
      expect(Validators.note(null), isNull);
      expect(Validators.note('A short note'), isNull);
      expect(
          Validators.note(
              List.filled(AppConstants.maxNoteLength + 1, 'x').join()),
          isNotNull);
      expect(Validators.optionalHttpsUrl(''), isNull);
      expect(Validators.optionalHttpsUrl('https://example.com/path'), isNull);
      expect(Validators.optionalHttpsUrl('http://example.com'), isNotNull);
      expect(Validators.optionalHttpsUrl('https:///missing-host'), isNotNull);
    });
    test('normalizes invite codes and validates exact length', () {
      expect(Validators.normalizeInviteCode(' abcd-2345 '), 'ABCD2345');
      expect(Validators.inviteCode('ABCD2345'), isNull);
      expect(Validators.inviteCode('bad'), isNotNull);
    });
    test('validates date ranges', () {
      expect(Validators.dateRange(DateTime(2026, 1, 1), DateTime(2026, 1, 2)),
          isNull);
      expect(Validators.dateRange(DateTime(2026, 1, 2), DateTime(2026, 1, 1)),
          isNotNull);
      expect(Validators.dateRange(null, DateTime(2026, 1, 2)), isNotNull);
      expect(Validators.dateRange(DateTime(2026, 1, 1), null), isNotNull);
      expect(Validators.requiredDate(null), isNotNull);
      expect(Validators.requiredDate(DateTime(2026, 1, 1)), isNull);
      expect(
        Validators.dateRange(
          DateTime.utc(2026, 1, 1),
          DateTime.utc(2026, 1, AppConstants.maxTripDays + 1),
        ),
        isNotNull,
      );
    });
  });
}
