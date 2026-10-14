import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/ev_avatar.dart';
import '../../core/widgets/ev_card.dart';
import '../../core/widgets/ev_misc.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/trip_cover.dart';
import '../../models/trip.dart';
import '../../providers/trip_workspace.dart';

/// Trip overview: a destination hero, the essentials, who is going, and
/// access to the planning tools.
class TripOverviewScreen extends StatelessWidget {
  const TripOverviewScreen({super.key});

  static String _status(Trip trip) {
    final today = EvDates.todayUtc();
    if (trip.hasEnded()) return 'Trip ended';
    if (trip.isOngoing()) return 'Happening now';
    final days = EvDates.daysBetween(today, trip.startDate);
    return days == 1 ? 'Starts tomorrow' : 'Starts in $days days';
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<TripWorkspace>();
    final trip = ws.trip;
    if (trip == null) return const EvLoading();
    final text = Theme.of(context).textTheme;
    final names = ws.members.map((m) => m.displayName).toList();

    final planned = ws.activities.length;
    final packingTotal = ws.packingItems.length;
    final budgetSummary = trip.hasBudget
        ? '${EvFormat.money(ws.totalSpent, trip.currency)} of ${EvFormat.money(trip.budgetMinor, trip.currency)}'
        : '${EvFormat.money(ws.totalSpent, trip.currency)} spent';

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            EvSpace.screenH, EvSpace.s12, EvSpace.screenH, EvSpace.s32),
        children: [
          TripCover(
            destination: trip.destination,
            imageUrl: trip.coverImageUrl,
            height: 220,
            radius: EvRadius.hero,
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(EvSpace.s8),
                child: Material(
                  color: EvColors.cream,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Back to your trips',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go(AppRoutes.home),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: EvSpace.s20),
          Semantics(
            header: true,
            child: Text(trip.destination, style: EvTypography.display(size: 34)),
          ),
          const SizedBox(height: EvSpace.s4),
          Text(trip.name, style: text.bodyLarge),
          const SizedBox(height: EvSpace.s16),
          Wrap(
            spacing: EvSpace.s8,
            runSpacing: EvSpace.s8,
            children: [
              EvTag(EvFormat.dateRange(trip.startDate, trip.endDate),
                  icon: Icons.calendar_today_outlined),
              EvTag(EvFormat.plural(trip.dayCount, 'day'),
                  icon: Icons.wb_sunny_outlined),
              EvTag(_status(trip),
                  icon: Icons.flag_outlined,
                  background: EvColors.terracottaSoft),
            ],
          ),
          const SizedBox(height: EvSpace.s32),
          EvSectionHeader(
            title: 'Travelling together',
            trailing: TextButton(
              onPressed: () => context.go(AppRoutes.members(trip.id)),
              child: const Text('Manage'),
            ),
          ),
          Row(
            children: [
              EvAvatarStack(names: names, size: 40, max: 5),
              const SizedBox(width: EvSpace.s12),
              Expanded(
                child: Text(
                  EvFormat.plural(ws.members.length, 'traveller'),
                  style: text.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: EvSpace.s32),
          const EvSectionHeader(title: 'Planning tools'),
          _ToolRow(
            icon: Icons.event_note_outlined,
            title: 'Itinerary',
            summary: planned == 0
                ? 'Nothing planned yet'
                : '${EvFormat.plural(planned, 'activity', 'activities')} across ${EvFormat.plural(trip.dayCount, 'day')}',
            onTap: () => context.go(AppRoutes.itinerary(trip.id)),
          ),
          const SizedBox(height: EvSpace.s8),
          _ToolRow(
            icon: Icons.checklist_outlined,
            title: 'Packing list',
            summary: packingTotal == 0
                ? 'No items yet'
                : '${ws.packedCount} of $packingTotal packed',
            onTap: () => context.go(AppRoutes.packing(trip.id)),
          ),
          const SizedBox(height: EvSpace.s8),
          _ToolRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Budget and expenses',
            summary: budgetSummary,
            onTap: () => context.go(AppRoutes.budget(trip.id)),
          ),
          const SizedBox(height: EvSpace.s8),
          _ToolRow(
            icon: Icons.group_outlined,
            title: 'Travellers and invites',
            summary: 'Invite code, members and roles',
            onTap: () => context.go(AppRoutes.members(trip.id)),
          ),
          if (ws.syncError != null) ...[
            const SizedBox(height: EvSpace.s16),
            EvInlineNotice(message: ws.syncError!),
          ],
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.icon,
    required this.title,
    required this.summary,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return EvCard(
      onTap: onTap,
      semanticLabel: '$title. $summary',
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: EvColors.sageSoft,
              borderRadius: BorderRadius.circular(EvRadius.chip),
            ),
            child: Icon(icon, color: EvColors.charcoal),
          ),
          const SizedBox(width: EvSpace.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                const SizedBox(height: 2),
                Text(summary, style: text.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: EvColors.mutedTextAccessible),
        ],
      ),
    );
  }
}
