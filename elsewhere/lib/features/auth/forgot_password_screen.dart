import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/ev_button.dart';
import '../../core/widgets/ev_text_field.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/auth_provider.dart';

/// Password recovery: sends a reset link to the entered email address.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok =
        await context.read<AuthProvider>().sendPasswordReset(_email.text);
    if (!mounted) return;
    if (ok) setState(() => _sent = true);
  }

  void _leave() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final busy = context.select<AuthProvider, bool>((a) => a.busy);
    final error = context.select<AuthProvider, String?>((a) => a.errorMessage);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _leave,
        ),
        title: const Text('Reset password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(EvSpace.s24),
          child: _sent
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const EvInlineNotice(
                      isError: false,
                      message:
                          'If an account exists for that email, a reset link is on its way. Check your inbox and spam folder.',
                    ),
                    const SizedBox(height: EvSpace.s24),
                    EvButton.primary(
                        label: 'Back to sign in', onPressed: _leave),
                  ],
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter the email you signed up with and we will send you a link to choose a new password.',
                        style: text.bodyLarge,
                      ),
                      const SizedBox(height: EvSpace.s24),
                      EvTextField(
                        controller: _email,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        validator: Validators.email,
                        onFieldSubmitted: (_) => busy ? null : _submit(),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: EvSpace.s16),
                        EvInlineNotice(message: error),
                      ],
                      const SizedBox(height: EvSpace.s24),
                      EvButton.primary(
                        label: 'Send reset link',
                        loading: busy,
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
