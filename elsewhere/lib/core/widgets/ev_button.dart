import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

enum _EvButtonKind { primary, accent, secondary }

/// The app's button. Three kinds, matching the design spec:
///  * primary   - charcoal with cream text (default call to action)
///  * accent    - deep terracotta with white text (one per screen, sparingly)
///  * secondary - sage with charcoal text
///
/// While [loading] is true the button keeps its look, shows a spinner and
/// ignores taps, which prevents duplicate submissions.
class EvButton extends StatelessWidget {
  const EvButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.expanded = true,
  }) : _kind = _EvButtonKind.primary;

  const EvButton.accent({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.expanded = true,
  }) : _kind = _EvButtonKind.accent;

  const EvButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.expanded = true,
  }) : _kind = _EvButtonKind.secondary;

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expanded;
  final _EvButtonKind _kind;

  @override
  Widget build(BuildContext context) {
    late final Color background;
    late final Color foreground;
    switch (_kind) {
      case _EvButtonKind.primary:
        background = EvColors.charcoal;
        foreground = EvColors.cream;
      case _EvButtonKind.accent:
        background = EvColors.terracottaDeep;
        foreground = EvColors.white;
      case _EvButtonKind.secondary:
        background = EvColors.sage;
        foreground = EvColors.charcoal;
    }

    final VoidCallback? effective =
        loading ? () {} : onPressed; // loading: swallow taps, keep styling

    final content = loading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: foreground,
              semanticsLabel: 'Loading',
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: EvSpace.s8),
              ],
              Flexible(
                child: Text(label, textAlign: TextAlign.center),
              ),
            ],
          );

    final button = FilledButton(
      onPressed: effective,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: EvColors.sand,
        disabledForegroundColor: EvColors.mutedTextAccessible,
      ),
      child: content,
    );

    return expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
