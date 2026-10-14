import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Section heading with an optional trailing action.
class EvSectionHeader extends StatelessWidget {
  const EvSectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EvSpace.s12),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A small understated label, e.g. a member role or a status.
class EvTag extends StatelessWidget {
  const EvTag(
    this.label, {
    super.key,
    this.icon,
    this.background = EvColors.sageSoft,
  });

  final String label;
  final IconData? icon;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(EvRadius.chip - 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: EvColors.charcoal),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: EvColors.charcoal),
          ),
        ],
      ),
    );
  }
}

/// Shows a floating snack bar. Errors stay a little longer.
void showEvSnack(BuildContext context, String message, {bool isError = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: EvColors.cream,
            size: 20,
          ),
          const SizedBox(width: EvSpace.s12),
          Expanded(child: Text(message)),
        ],
      ),
      duration: Duration(seconds: isError ? 6 : 3),
    ),
  );
}

/// Asks the user to confirm an action. Returns true only if confirmed.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: EvColors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EvRadius.card + 4),
      ),
      title: Text(title, style: Theme.of(ctx).textTheme.titleLarge),
      content: Text(message, style: Theme.of(ctx).textTheme.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(
            foregroundColor:
                destructive ? EvColors.error : EvColors.charcoal,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
