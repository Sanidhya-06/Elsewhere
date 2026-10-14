import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_exception.dart';
import '../../core/widgets/ev_avatar.dart';
import '../../core/widgets/ev_button.dart';
import '../../core/widgets/ev_card.dart';
import '../../core/widgets/ev_misc.dart';
import '../../models/trip_member.dart';
import '../../providers/trip_workspace.dart';

/// Invite and manage members: the invite code, who is on the trip, owner-only
/// removal, and leaving the trip.
class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  bool _regenerating = false;
  bool _leaving = false;

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    showEvSnack(context, '$label copied');
  }

  Future<void> _regenerate(TripWorkspace ws) async {
    final ok = await confirmDialog(
      context,
      title: 'Create a new invite code?',
      message:
          'The current code will stop working. People who already joined stay on the trip.',
      confirmLabel: 'Create new code',
    );
    if (!ok || !mounted) return;
    setState(() => _regenerating = true);
    try {
      await ws.regenerateInviteCode();
      if (!mounted) return;
      showEvSnack(context, 'New invite code created');
    } catch (error) {
      if (!mounted) return;
      showEvSnack(context, friendlyError(error), isError: true);
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  Future<void> _remove(TripWorkspace ws, TripMember member) async {
    final ok = await confirmDialog(
      context,
      title: 'Remove ${member.displayName}?',
      message:
          'They will lose access to this trip. Expenses they paid or shared stay in the budget.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ws.removeMember(member.userId);
      if (!mounted) return;
      showEvSnack(context, '${member.displayName} was removed');
    } catch (error) {
      if (!mounted) return;
      showEvSnack(context, friendlyError(error), isError: true);
    }
  }

  Future<void> _leave(TripWorkspace ws) async {
    if (_leaving) return;
    final ok = await confirmDialog(
      context,
      title: 'Leave this trip?',
      message:
          'You will lose access unless someone shares the invite code with you again.',
      confirmLabel: 'Leave trip',
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _leaving = true);
    try {
      await ws.leave();
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (error) {
      if (!mounted) return;
      setState(() => _leaving = false);
      showEvSnack(context, friendlyError(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<TripWorkspace>();
    final trip = ws.trip;
    if (trip == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final code = trip.inviteCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Travellers')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(EvSpace.screenH),
          children: [
            EvCard.warm(
              semanticLabel: 'Invite code $code',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invite friends', style: text.titleMedium),
                  const SizedBox(height: EvSpace.s4),
                  Text(
                    'Share this code. Friends enter it under "Invited to a trip?" on their home screen.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: EvSpace.s16),
                  Center(
                    child: SelectableText(
                      code.isEmpty ? '--------' : code,
                      style: text.headlineMedium?.copyWith(
                        letterSpacing: 6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: EvSpace.s16),
                  EvButton.primary(
                    label: 'Copy invite message',
                    icon: Icons.copy_outlined,
                    onPressed: code.isEmpty
                        ? null
                        : () => _copy(
                              'Invite message',
                              'Join "${trip.name}" on Elsewhere. Open the app, tap "Invited to a trip?" and enter the code $code.',
                            ),
                  ),
                  const SizedBox(height: EvSpace.s8),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed:
                              code.isEmpty ? null : () => _copy('Code', code),
                          child: const Text('Copy code only'),
                        ),
                      ),
                      if (ws.isOwner)
                        Expanded(
                          child: TextButton(
                            onPressed:
                                _regenerating ? null : () => _regenerate(ws),
                            child: Text(_regenerating
                                ? 'Working...'
                                : 'New code'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: EvSpace.s32),
            EvSectionHeader(title: 'On this trip (${ws.members.length})'),
            for (final member in ws.members) ...[
              _MemberRow(
                member: member,
                isYou: member.userId == ws.currentUserId,
                canRemove: ws.isOwner && member.userId != ws.currentUserId,
                onRemove: () => _remove(ws, member),
              ),
              const Divider(),
            ],
            const SizedBox(height: EvSpace.s24),
            if (ws.isOwner)
              Text(
                'You created this trip, so you stay on it as the owner.',
                style: text.bodySmall,
              )
            else
              OutlinedButton.icon(
                onPressed: _leaving ? null : () => _leave(ws),
                icon: const Icon(Icons.logout),
                label: Text(_leaving ? 'Leaving...' : 'Leave trip'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EvColors.error,
                  side: const BorderSide(color: EvColors.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.isYou,
    required this.canRemove,
    required this.onRemove,
  });

  final TripMember member;
  final bool isYou;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: EvSpace.s8),
      child: Row(
        children: [
          EvAvatar(name: member.displayName, size: 44),
          const SizedBox(width: EvSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isYou ? '${member.displayName} (you)' : member.displayName,
                    style: text.titleSmall),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: EvTag(member.isOwner ? 'Owner' : 'Member',
                      icon: member.isOwner ? Icons.star_outline : null),
                ),
              ],
            ),
          ),
          if (canRemove)
            IconButton(
              tooltip: 'Remove ${member.displayName}',
              icon: const Icon(Icons.person_remove_outlined),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
