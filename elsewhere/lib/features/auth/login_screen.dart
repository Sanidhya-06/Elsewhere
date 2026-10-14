import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/ev_button.dart';
import '../../core/widgets/ev_text_field.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/auth_provider.dart';
import 'brand_backdrop.dart';

/// Sign in and create account in one screen. After a successful sign-in the
/// router redirect carries the person to their destination.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignUp = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _setMode(bool signUp) {
    if (_isSignUp == signUp) return;
    context.read<AuthProvider>().clearError();
    setState(() => _isSignUp = signUp);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    if (_isSignUp) {
      await auth.signUp(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );
    } else {
      await auth.signIn(email: _email.text, password: _password.text);
    }
    // On success the router redirect navigates away; on failure the error is
    // shown inline below the form.
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final busy = context.select<AuthProvider, bool>((a) => a.busy);
    final error = context.select<AuthProvider, String?>((a) => a.errorMessage);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BrandBackdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
                EvSpace.s24, EvSpace.s32, EvSpace.s24, EvSpace.s32),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: EvSpace.s32),
                    Semantics(
                      header: true,
                      child: Text(AppConstants.appName,
                          style: EvTypography.display(size: 40)),
                    ),
                    const SizedBox(height: EvSpace.s8),
                    Text(AppConstants.tagline, style: text.bodyLarge),
                    const SizedBox(height: EvSpace.s40),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        showSelectedIcon: true,
                        segments: const [
                          ButtonSegment(value: false, label: Text('Sign in')),
                          ButtonSegment(
                              value: true, label: Text('Create account')),
                        ],
                        selected: {_isSignUp},
                        onSelectionChanged: busy
                            ? null
                            : (selection) => _setMode(selection.first),
                      ),
                    ),
                    const SizedBox(height: EvSpace.s24),
                    if (_isSignUp) ...[
                      EvTextField(
                        controller: _name,
                        label: 'Your name',
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: (v) => Validators.name(v, field: 'Name'),
                      ),
                      const SizedBox(height: EvSpace.s16),
                    ],
                    EvTextField(
                      controller: _email,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: Validators.email,
                    ),
                    const SizedBox(height: EvSpace.s16),
                    EvTextField(
                      controller: _password,
                      label: 'Password',
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      autofillHints: _isSignUp
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      onFieldSubmitted: (_) => busy ? null : _submit(),
                      validator: _isSignUp
                          ? Validators.password
                          : Validators.loginPassword,
                      helper: _isSignUp ? 'At least 8 characters.' : null,
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Show password' : 'Hide password',
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: busy
                              ? null
                              : () => context.push(AppRoutes.forgotPassword),
                          child: const Text('Forgot password?'),
                        ),
                      )
                    else
                      const SizedBox(height: EvSpace.s8),
                    if (error != null) ...[
                      const SizedBox(height: EvSpace.s8),
                      EvInlineNotice(message: error),
                    ],
                    const SizedBox(height: EvSpace.s24),
                    EvButton.primary(
                      label: _isSignUp ? 'Create account' : 'Sign in',
                      loading: busy,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
