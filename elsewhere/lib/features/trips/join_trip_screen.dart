import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/app_exception.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/ev_button.dart';
import '../../core/widgets/ev_misc.dart';
import '../../core/widgets/ev_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/trips_provider.dart';

/// Join a trip with an invite code.
class JoinTripScreen extends StatefulWidget {
  const JoinTripScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  State<JoinTripScreen> createState() => _JoinTripScreenState();
}

class _JoinTripScreenState extends State<JoinTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code =
      TextEditingController(text: widget.initialCode == null
          ? ''
          : Validators.normalizeInviteCode(widget.initialCode!));
  bool _submitting = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final trips = context.read<TripsProvider>();
    final code = Validators.normalizeInviteCode(_code.text);

    setState(() => _submitting = true);
    try {
      final tripId = await trips.joinTrip(code: code, user: user);
      if (!mounted) return;
      context.pushReplacement(AppRoutes.trip(tripId));
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showEvSnack(context, friendlyError(error), isError: true);
    }
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _leave,
        ),
        title: const Text('Join a trip'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EvSpace.screenH),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Got an invite?', style: text.headlineMedium),
                const SizedBox(height: EvSpace.s8),
                Text(
                  'Enter the ${AppConstants.inviteCodeLength}-character code the trip owner shared with you.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: EvSpace.s24),
                EvTextField(
                  controller: _code,
                  label: 'Invite code',
                  hint: 'ABCD2345',
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  autofocus: widget.initialCode == null,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9 -]')),
                    LengthLimitingTextInputFormatter(
                        AppConstants.inviteCodeLength + 2),
                  ],
                  validator: Validators.inviteCode,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: EvSpace.s24),
                EvButton.primary(
                  label: 'Join trip',
                  loading: _submitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
