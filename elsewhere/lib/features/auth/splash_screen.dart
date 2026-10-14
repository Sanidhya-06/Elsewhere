import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../providers/auth_provider.dart';
import 'brand_backdrop.dart';

/// Shown while the saved session is being checked. The router leaves this
/// screen as soon as [AuthProvider] resolves the session.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _slowTimer;
  bool _slow = false;

  @override
  void initState() {
    super.initState();
    _slowTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final error = context.select<AuthProvider, String?>((a) => a.errorMessage);
    return Scaffold(
      body: BrandBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: EvSpace.s24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 3),
                Semantics(
                  header: true,
                  child: Text(
                    AppConstants.appName,
                    style: EvTypography.display(size: 44),
                  ),
                ),
                const SizedBox(height: EvSpace.s12),
                Text(AppConstants.tagline, style: text.bodyLarge),
                const SizedBox(height: EvSpace.s32),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    semanticsLabel: 'Checking your session',
                  ),
                ),
                if (_slow || error != null) ...[
                  const SizedBox(height: EvSpace.s16),
                  Text(
                    error ??
                        'This is taking longer than usual. Check your connection.',
                    style: text.bodySmall,
                  ),
                ],
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
