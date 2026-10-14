import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/ev_avatar.dart';
import '../../core/widgets/ev_button.dart';
import '../../core/widgets/ev_card.dart';
import '../../core/widgets/ev_misc.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/trip_cover.dart';
import '../../models/trip.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trips_provider.dart';

/// Home dashboard: upcoming trips, the invitation entry point, and the
/// create-trip action.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static String _greeting(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final firstName =
        context.select<AuthProvider, String>((a) => a.user?.firstName ?? 'there');
    final trips = context.watch<TripsProvider>();
    final upcoming = trips.upcoming();
    final past = trips.past();

    Widget body;
    if (trips.loading) {
      body = const Padding(
        padding: EdgeInsets.only(top: EvSpace.s48),
        child: EvLoading(message: 'Loading your trips'),
      );
    } else if (trips.error != null) {
      body = EvErrorState(
        title: 'Could not load your trips',
        message: trips.error!,
        onRetry: trips.retry,
      );
    } else if (trips.trips.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.only(top: EvSpace.s24),
        child: EvEmptyState(
          icon: Icons.luggage_outlined,
          title: 'Your next trip starts here',
          message:
              'Create a trip and invite friends, or join one with an invite code.',
          actionLabel: 'Plan a trip',
          onAction: () => context.push(AppRoutes.createTrip),
        ),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EvButton.accent(
            label: 'Plan a new trip',
            icon: Icons.add,
            onPressed: () => context.push(AppRoutes.createTrip),
          ),
          const SizedBox(height: EvSpace.s32),
          if (upcoming.isNotEmpty) ...[
            const EvSectionHeader(title: 'Upcoming'),
            for (final trip in upcoming) ...[
              _TripCard(trip: trip),
              const SizedBox(height: EvSpace.s24),
            ],
          ] else
            Padding(
              padding: const EdgeInsets.only(bottom: EvSpace.s24),
              child: Text('No upcoming trips. Time to plan one!',
                  style: text.bodyMedium),
            ),
          if (past.isNotEmpty) ...[
            const EvSectionHeader(title: 'Past trips'),
            for (final trip in past) ...[
              _PastTripRow(trip: trip),
              const SizedBox(height: EvSpace.s8),
            ],
            const SizedBox(height: EvSpace.s16),
          ],
        ],
      );
    }

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            EvSpace.screenH, EvSpace.s24, EvSpace.screenH, EvSpace.s32),
        children: [
          Text(_greeting(DateTime.now()), style: text.bodyMedium),
          const SizedBox(height: EvSpace.s4),
          Semantics(
            header: true,
            child: Text(firstName, style: EvTypography.display(size: 34)),
          ),
          const SizedBox(height: EvSpace.s24),
          body,
          const SizedBox(height: EvSpace.s8),
          const _InvitationCard(),
        ],
      ),
    );
  }
}

/// Invitations are code-based: someone shares a code, the invitee enters it.
class _InvitationCard extends StatelessWidget {
  const _InvitationCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return EvCard(
      color: EvColors.sageSoft,
      borderColor: EvColors.sageSoft,
      onTap: () => context.push(AppRoutes.joinTrip),
      semanticLabel: 'Join a trip with an invite code',
      child: Row(
        children: [
          const Icon(Icons.mail_outline, color: EvColors.charcoal),
          const SizedBox(width: EvSpace.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invited to a trip?', style: text.titleMedium),
                const SizedBox(height: EvSpace.s4),
                Text('Enter the invite code a friend shared with you.',
                    style: text.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: EvColors.charcoal),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final count = trip.memberIds.length;
    return Semantics(
      button: true,
      label:
          '${trip.destination}, ${EvFormat.dateRange(trip.startDate, trip.endDate)}',
      child: InkWell(
        onTap: () => context.push(AppRoutes.trip(trip.id)),
        borderRadius: BorderRadius.circular(EvRadius.hero),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TripCover(
              destination: trip.destination,
              imageUrl: trip.coverImageUrl,
              height: 172,
              radius: EvRadius.hero,
            ),
            const SizedBox(height: EvSpace.s12),
            Text(trip.destination,
                style: EvTypography.display(size: 24, weight: FontWeight.w600)),
            const SizedBox(height: EvSpace.s4),
            Text(trip.name, style: text.bodyMedium),
            const SizedBox(height: EvSpace.s8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 16, color: EvColors.mutedTextAccessible),
                const SizedBox(width: EvSpace.s8),
                Expanded(
                  child: Text(
                    EvFormat.dateRange(trip.startDate, trip.endDate),
                    style: text.bodySmall,
                  ),
                ),
                EvAvatarStack(
                  names: const [],
                  seeds: trip.memberIds,
                  size: 28,
                  max: 3,
                ),
                const SizedBox(width: EvSpace.s8),
                Text(EvFormat.plural(count, 'traveller'),
                    style: text.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PastTripRow extends StatelessWidget {
  const _PastTripRow({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return EvCard(
      onTap: () => context.push(AppRoutes.trip(trip.id)),
      semanticLabel: '${trip.destination}, past trip',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip.destination, style: text.titleMedium),
                const SizedBox(height: EvSpace.s4),
                Text(EvFormat.dateRange(trip.startDate, trip.endDate),
                    style: text.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: EvColors.mutedTextAccessible),
        ],
      ),
    );
  }
}
