import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'ev_button.dart';

/// Loading, empty and error states share one visual language.
class EvLoading extends StatelessWidget {
  const EvLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              semanticsLabel: 'Loading',
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: EvSpace.s16),
            Text(message!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class EvEmptyState extends StatelessWidget {
  const EvEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.explore_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EvSpace.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: EvColors.sageSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: EvColors.charcoal),
            ),
            const SizedBox(height: EvSpace.s20),
            Text(title, style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: EvSpace.s8),
            Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: EvSpace.s24),
              EvButton.primary(
                label: actionLabel!,
                onPressed: onAction,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EvErrorState extends StatelessWidget {
  const EvErrorState({
    super.key,
    required this.message,
    this.title = 'Something went wrong',
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EvSpace.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: EvColors.terracottaSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  size: 32, color: EvColors.error),
            ),
            const SizedBox(height: EvSpace.s20),
            Text(title, style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: EvSpace.s8),
            Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: EvSpace.s24),
              EvButton.primary(
                label: retryLabel,
                onPressed: onRetry,
                expanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small inline banner for non-fatal problems (e.g. a sync error).
class EvInlineNotice extends StatelessWidget {
  const EvInlineNotice({super.key, required this.message, this.isError = true});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EvSpace.s12),
      decoration: BoxDecoration(
        color: isError ? EvColors.terracottaSoft : EvColors.sageSoft,
        borderRadius: BorderRadius.circular(EvRadius.chip),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            size: 20,
            color: isError ? EvColors.error : EvColors.charcoal,
          ),
          const SizedBox(width: EvSpace.s8),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
