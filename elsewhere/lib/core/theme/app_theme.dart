import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// Typography. Manrope for the interface; Fraunces (a warm editorial serif)
/// only for intentional display moments such as destination names.
class EvTypography {
  EvTypography._();

  static TextTheme textTheme() {
    final base = GoogleFonts.manropeTextTheme();
    const ink = EvColors.charcoal;
    return base.copyWith(
      // Hero heading 32-38, bold.
      displaySmall: base.displaySmall?.copyWith(
          fontSize: 34, fontWeight: FontWeight.w700, color: ink, height: 1.15),
      // Screen heading 25-30, semibold.
      headlineMedium: base.headlineMedium?.copyWith(
          fontSize: 28, fontWeight: FontWeight.w600, color: ink, height: 1.2),
      // Section heading 18-21, semibold.
      titleLarge: base.titleLarge?.copyWith(
          fontSize: 20, fontWeight: FontWeight.w600, color: ink, height: 1.3),
      // Card title 15-17, semibold.
      titleMedium: base.titleMedium?.copyWith(
          fontSize: 16, fontWeight: FontWeight.w600, color: ink, height: 1.35),
      titleSmall: base.titleSmall?.copyWith(
          fontSize: 15, fontWeight: FontWeight.w600, color: ink, height: 1.35),
      // Body 14-16, regular.
      bodyLarge: base.bodyLarge?.copyWith(
          fontSize: 16, fontWeight: FontWeight.w400, color: ink, height: 1.5),
      bodyMedium: base.bodyMedium?.copyWith(
          fontSize: 14, fontWeight: FontWeight.w400, color: ink, height: 1.5),
      // Metadata 12-13, regular.
      bodySmall: base.bodySmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: EvColors.mutedTextAccessible,
          height: 1.45),
      // Buttons and small labels.
      labelLarge: base.labelLarge?.copyWith(
          fontSize: 15, fontWeight: FontWeight.w600, color: ink),
      labelMedium: base.labelMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: EvColors.mutedTextAccessible),
      labelSmall: base.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: EvColors.mutedTextAccessible),
    );
  }

  /// Editorial serif for hero headings and destination names.
  static TextStyle display({
    double size = 34,
    Color color = EvColors.charcoal,
    FontWeight weight = FontWeight.w700,
  }) {
    return GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.15,
    );
  }
}

/// Shared input decoration. Built here (rather than through the ThemeData
/// input theme) so that every field in the app is styled from one place and
/// stays independent of Flutter theme API changes between versions.
InputDecoration evInputDecoration({
  String? label,
  String? hint,
  String? helper,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? counterText,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(EvRadius.input),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    helperMaxLines: 2,
    counterText: counterText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: EvColors.white,
    contentPadding:
        const EdgeInsets.symmetric(horizontal: EvSpace.s16, vertical: 16),
    border: border(EvColors.border),
    enabledBorder: border(EvColors.border),
    disabledBorder: border(EvColors.border),
    focusedBorder: border(EvColors.charcoal, 1.5),
    errorBorder: border(EvColors.error),
    focusedErrorBorder: border(EvColors.error, 1.5),
    labelStyle: const TextStyle(color: EvColors.mutedTextAccessible),
    floatingLabelStyle: const TextStyle(color: EvColors.charcoal),
    hintStyle: const TextStyle(color: EvColors.mutedTextAccessible),
    helperStyle: const TextStyle(color: EvColors.mutedTextAccessible),
    errorStyle: const TextStyle(color: EvColors.error),
    errorMaxLines: 3,
  );
}

ThemeData buildEvTheme() {
  final text = EvTypography.textTheme();

  const scheme = ColorScheme.light(
    primary: EvColors.charcoal,
    onPrimary: EvColors.cream,
    primaryContainer: EvColors.sand,
    onPrimaryContainer: EvColors.charcoal,
    secondary: EvColors.sage,
    onSecondary: EvColors.charcoal,
    secondaryContainer: EvColors.sageSoft,
    onSecondaryContainer: EvColors.charcoal,
    tertiary: EvColors.terracottaDeep,
    onTertiary: EvColors.white,
    tertiaryContainer: EvColors.terracottaSoft,
    onTertiaryContainer: EvColors.charcoal,
    error: EvColors.error,
    onError: EvColors.white,
    surface: EvColors.white,
    onSurface: EvColors.charcoal,
    onSurfaceVariant: EvColors.mutedTextAccessible,
    outline: EvColors.border,
    outlineVariant: EvColors.border,
  );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(EvRadius.button),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: EvColors.cream,
    canvasColor: EvColors.cream,
    textTheme: text,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: EvColors.cream,
      foregroundColor: EvColors.charcoal,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
    ),
    dividerTheme: const DividerThemeData(
      color: EvColors.border,
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(EvSpace.touch, 52),
        padding: const EdgeInsets.symmetric(horizontal: EvSpace.s24),
        shape: buttonShape,
        textStyle: text.labelLarge,
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(EvSpace.touch, 52),
        padding: const EdgeInsets.symmetric(horizontal: EvSpace.s24),
        shape: buttonShape,
        foregroundColor: EvColors.charcoal,
        side: const BorderSide(color: EvColors.charcoal, width: 1),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(EvSpace.touch, EvSpace.touch),
        foregroundColor: EvColors.charcoal,
        textStyle: text.labelLarge,
        shape: buttonShape,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(EvSpace.touch, EvSpace.touch),
        foregroundColor: EvColors.charcoal,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: EvColors.terracottaDeep,
      foregroundColor: EvColors.white,
      elevation: 2,
      highlightElevation: 2,
      extendedTextStyle: text.labelLarge?.copyWith(color: EvColors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EvRadius.button + 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: EvColors.cream,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: EvColors.sageSoft,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EvRadius.chip),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return text.labelMedium?.copyWith(
          color: selected ? EvColors.charcoal : EvColors.mutedTextAccessible,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected ? EvColors.charcoal : EvColors.mutedTextAccessible,
        );
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? EvColors.sage
            : Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(EvColors.charcoal),
      side: const BorderSide(color: EvColors.mutedTextAccessible, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: EvColors.white,
      selectedColor: EvColors.sage,
      disabledColor: EvColors.sand,
      checkmarkColor: EvColors.charcoal,
      side: const BorderSide(color: EvColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EvRadius.chip),
      ),
      labelStyle: text.bodyMedium,
      secondaryLabelStyle: text.bodyMedium,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: EvColors.charcoal,
      contentTextStyle: text.bodyMedium?.copyWith(color: EvColors.cream),
      actionTextColor: EvColors.sand,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EvRadius.input),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: EvColors.white,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EvRadius.sheet),
        ),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: EvColors.terracottaDeep,
      linearTrackColor: EvColors.sand,
      circularTrackColor: EvColors.sand,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: EvColors.white,
        foregroundColor: EvColors.charcoal,
        selectedBackgroundColor: EvColors.sage,
        selectedForegroundColor: EvColors.charcoal,
        side: const BorderSide(color: EvColors.border),
        textStyle: text.labelLarge,
        minimumSize: const Size(EvSpace.touch, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EvRadius.button),
        ),
      ),
    ),
  );
}
