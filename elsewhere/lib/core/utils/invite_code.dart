import 'dart:math';

import '../constants/app_constants.dart';

/// Generates invitation codes with a cryptographically secure random source.
class InviteCodes {
  InviteCodes._();

  static String generate([Random? random]) {
    final rng = random ?? Random.secure();
    const alphabet = AppConstants.inviteCodeAlphabet;
    return List.generate(
      AppConstants.inviteCodeLength,
      (_) => alphabet[rng.nextInt(alphabet.length)],
    ).join();
  }
}
