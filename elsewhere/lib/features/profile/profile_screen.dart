import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/ev_avatar.dart';
import '../../core/widgets/ev_button.dart';
import '../../core/widgets/ev_card.dart';
import '../../core/widgets/ev_misc.dart';
import '../../core/widgets/ev_text_field.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trips_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: context.read<AuthProvider>().user?.displayName ?? '');
  bool _saving = false;
  @override
  void dispose() { _name.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.uid;
    if (uid == null) return;
    final newName = _name.text.trim();
    if (newName == auth.user?.displayName) { showEvSnack(context, 'Your name is already up to date'); return; }
    setState(() => _saving = true);
    final ok = await auth.updateDisplayName(newName);
    if (!mounted) return;
    if (!ok) { setState(() => _saving = false); showEvSnack(context, auth.errorMessage ?? 'Could not update your name. Try again.', isError: true); return; }
    final synced = await context.read<TripsProvider>().syncDisplayName(uid, newName);
    if (!mounted) return;
    setState(() => _saving = false);
    showEvSnack(context, synced ? 'Name updated' : 'Profile updated, but some trips may still show your old name.', isError: !synced);
  }

  Future<void> _signOut() async {
    final ok = await confirmDialog(context, title: 'Sign out of ${AppConstants.appName}?', message: 'You can sign back in any time with your email and password.', confirmLabel: 'Sign out');
    if (!ok || !mounted) return;
    final auth = context.read<AuthProvider>();
    if (!await auth.signOut() && mounted) showEvSnack(context, auth.errorMessage ?? 'Could not sign out. Try again.', isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final user = context.select<AuthProvider, ({String name, String email})?>((a) => a.user == null ? null : (name: a.user!.displayName, email: a.user!.email));
    if (user == null) return const EvLoading();
    return SafeArea(bottom: false, child: ListView(padding: const EdgeInsets.fromLTRB(EvSpace.screenH, EvSpace.s24, EvSpace.screenH, EvSpace.s32), children: [
      Semantics(header: true, child: Text('Profile', style: text.headlineMedium)), const SizedBox(height: EvSpace.s24),
      Row(children: [EvAvatar(name: user.name, size: 64), const SizedBox(width: EvSpace.s16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user.name, style: text.titleLarge), const SizedBox(height: 2), Text(user.email, style: text.bodyMedium)]))]),
      const SizedBox(height: EvSpace.s32), const EvSectionHeader(title: 'Your details'),
      Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [EvTextField(controller: _name, label: 'Display name', helper: 'This is the name your friends see on trips.', textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.done, maxLength: AppConstants.maxNameLength, onFieldSubmitted: (_) => _save(), validator: (v) => Validators.name(v, field: 'Name')), const SizedBox(height: EvSpace.s12), EvButton.primary(label: 'Save name', loading: _saving, onPressed: _save)])),
      const SizedBox(height: EvSpace.s32), EvCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('About ${AppConstants.appName}', style: text.titleMedium), const SizedBox(height: EvSpace.s4), Text(AppConstants.tagline, style: text.bodyMedium), const SizedBox(height: EvSpace.s8), Text('Version ${AppConstants.version}', style: text.bodySmall)])),
      const SizedBox(height: EvSpace.s24), OutlinedButton.icon(onPressed: _saving ? null : _signOut, icon: const Icon(Icons.logout), label: const Text('Sign out')),
    ]));
  }
}
