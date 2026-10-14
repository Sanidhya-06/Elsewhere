import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/ev_card.dart';
import '../../core/widgets/state_views.dart';
import '../../models/activity.dart';
import '../../models/trip.dart';
import '../../providers/trip_workspace.dart';

/// The itinerary, grouped by trip day with a restrained timeline.
class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<TripWorkspace>();
    final trip = ws.trip;
    if (trip == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: const Text('Itinerary')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newActivity(trip.id)),
        icon: const Icon(Icons.add),
        label: const Text('Add activity'),
        tooltip: 'Add an activity',
      ),
      body: SafeArea(
        bottom: false,
        child: _body(context, ws, trip),
      ),
    );
  }

  Widget _body(BuildContext context, TripWorkspace ws, Trip trip) {
    if (!ws.activitiesLoaded && ws.syncError == null) {
      return const EvLoading();
    }
    if (!ws.activitiesLoaded && ws.syncError != null) {
      return EvErrorState(
        title: 'Itinerary unavailable',
        message: ws.syncError!,
      );
    }

    // One section per trip day, plus any activity dates outside the range.
    final byDay = <DateTime, List<Activity>>{
      for (final day in trip.days) day: <Activity>[],
    };
    for (final a in ws.activities) {
      byDay.putIfAbsent(a.date, () => <Activity>[]).add(a);
    }
    final days = byDay.keys.toList()..sort();
    for (final list in byDay.values) {
      list.sort((a, b) => a.sortKey.compareTo(b.sortKey));
    }

    if (ws.activities.isEmpty) {
      return EvEmptyState(
        icon: Icons.event_note_outlined,
        title: 'Nothing planned yet',
        message:
            'Add the first activity and everyone on the trip will see it straight away.',
        actionLabel: 'Add an activity',
        onAction: () => context.push(AppRoutes.newActivity(trip.id)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          EvSpace.screenH, EvSpace.s8, EvSpace.screenH, 96),
      itemCount: days.length,
      itemBuilder: (context, i) {
        final day = days[i];
        final index = EvDates.daysBetween(trip.startDate, day);
        final inRange = index >= 0 && index < trip.dayCount;
        return _DaySection(
          title: inRange ? 'Day ${index + 1}' : 'Outside trip dates',
          subtitle: EvFormat.dayLong(day),
          activities: byDay[day]!,
          trip: trip,
        );
      },
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.title,
    required this.subtitle,
    required this.activities,
    required this.trip,
  });

  final String title;
  final String subtitle;
  final List<Activity> activities;
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: EvSpace.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(title, style: text.titleLarge),
                const SizedBox(width: EvSpace.s8),
                Text(subtitle, style: text.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: EvSpace.s12),
          if (activities.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text('Nothing planned for this day.',
                  style: text.bodySmall),
            )
          else
            for (var i = 0; i < activities.length; i++)
              _TimelineRow(
                activity: activities[i],
                trip: trip,
                isLast: i == activities.length - 1,
              ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.activity,
    required this.trip,
    required this.isLast,
  });

  final Activity activity;
  final Trip trip;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final time = activity.time == null ? 'Any time' : EvFormat.time(activity.time!);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(top: EvSpace.s12),
              child: Text(time, style: text.labelMedium),
            ),
          ),
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: EvSpace.s16),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: EvColors.cream,
                    shape: BoxShape.circle,
                    border: Border.all(color: EvColors.charcoal, width: 1.5),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 1,
                    color: isLast ? Colors.transparent : EvColors.border,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: EvSpace.s8),
              child: EvCard(
                onTap: () =>
                    context.push(AppRoutes.editActivity(trip.id, activity.id)),
                semanticLabel: '${activity.title}, $time. Tap to edit.',
                padding: const EdgeInsets.all(EvSpace.s12),
                radius: EvRadius.card - 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity.title, style: text.titleSmall),
                    if (activity.location.isNotEmpty) ...[
                      const SizedBox(height: EvSpace.s4),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 16, color: EvColors.mutedTextAccessible),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(activity.location,
                                style: text.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ],
                    if (activity.costMinor > 0) ...[
                      const SizedBox(height: EvSpace.s4),
                      Text(
                        'Est. ${EvFormat.money(activity.costMinor, trip.currency)}',
                        style: text.bodySmall,
                      ),
                    ],
                    if (activity.notes.isNotEmpty) ...[
                      const SizedBox(height: EvSpace.s8),
                      Text(activity.notes,
                          style: text.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
