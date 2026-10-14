import 'package:flutter/material.dart';

/// Design tokens for Elsewhere, taken from the design specification.
///
/// Colors marked "derived" are not in the spec palette. They exist only to
/// meet WCAG contrast for text or to provide a soft tint of a spec color, and
/// are documented in the README under "Design decisions".
class EvColors {
  EvColors._();

  // Spec palette.
  static const Color terracotta = Color(0xFFC77F68);
  static const Color sage = Color(0xFF9EAD91);
  static const Color cream = Color(0xFFF5F0E6);
  static const Color sand = Color(0xFFE5D6C5);
  static const Color charcoal = Color(0xFF33352D);
  static const Color mutedText = Color(0xFF77766D);
  static const Color border = Color(0xFFE3DDD2);
  static const Color white = Color(0xFFFFFFFF);

  // Derived: terracotta darkened so white text reaches >= 4.5:1 on it.
  static const Color terracottaDeep = Color(0xFFA85D47);
  // Derived: muted text darkened so it reaches >= 4.5:1 on cream (the spec
  // muted text is about 4.0:1 on cream, 4.6:1 on white).
  static const Color mutedTextAccessible = Color(0xFF66655C);
  // Derived: soft tints of sage and terracotta for quiet surfaces.
  static const Color sageSoft = Color(0xFFE4E9DE);
  static const Color terracottaSoft = Color(0xFFF0DDD5);
  // Derived: error color with >= 4.5:1 contrast on cream and white.
  static const Color error = Color(0xFFA6402F);
}

/// 4 px spacing scale.
class EvSpace {
  EvSpace._();

  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;

  /// Standard horizontal screen padding (spec: 20-24 px).
  static const double screenH = 20;

  /// Standard card padding (spec: 16-20 px).
  static const double cardPad = 16;

  /// Minimum touch target (spec: about 48 x 48).
  static const double touch = 48;
}

/// Corner radii (spec section 4).
class EvRadius {
  EvRadius._();

  static const double hero = 28;
  static const double card = 20;
  static const double input = 16;
  static const double button = 16;
  static const double chip = 12;
  static const double sheet = 28;
  static const double small = 8;
}
