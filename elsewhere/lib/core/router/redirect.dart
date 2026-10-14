import '../../providers/auth_provider.dart';
import 'routes.dart';

/// Authentication-aware redirect logic, kept free of Flutter and GoRouter
/// types so it can be unit-tested directly.
///
/// Returns the location to redirect to, or null to stay where we are.
///
/// Rules:
///  * While the session is still being resolved, every location is sent to the
///    splash screen, remembering the original destination in `from`.
///  * Once resolved, the splash screen forwards to `from` (or the home screen)
///    when signed in and to the login screen otherwise.
///  * Signed-out users are sent to login (remembering `from`) for anything that
///    is not a public route.
///  * Signed-in users never see the login or password-reset screens.
///
/// This is a convenience for the interface only. Real authorization is
/// enforced by Firestore Security Rules.
String? resolveRedirect(Uri uri, AuthStatus status) {
  final path = uri.path;
  final from = _safeFrom(uri.queryParameters['from']);
  final isSplash = path == AppRoutes.splash;
  final isPublic =
      path == AppRoutes.login || path == AppRoutes.forgotPassword;

  switch (status) {
    case AuthStatus.unknown:
      if (isSplash) return null;
      return _withFrom(AppRoutes.splash, uri);

    case AuthStatus.unauthenticated:
      if (isPublic) return null;
      if (isSplash) {
        return from == null
            ? AppRoutes.login
            : '${AppRoutes.login}?from=${Uri.encodeQueryComponent(from)}';
      }
      return _withFrom(AppRoutes.login, uri);

    case AuthStatus.authenticated:
      if (isSplash || isPublic) return from ?? AppRoutes.home;
      return null;
  }
}

String _withFrom(String target, Uri uri) {
  final original = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
  final safe = _safeFrom(original);
  if (safe == null || safe == AppRoutes.splash) return target;
  return '$target?from=${Uri.encodeQueryComponent(safe)}';
}

/// Only in-app absolute paths are accepted as a post-login destination, and
/// never the public routes (to avoid redirect loops).
String? _safeFrom(String? value) {
  if (value == null || value.isEmpty) return null;
  if (!value.startsWith('/') || value.startsWith('//')) return null;
  final path = Uri.tryParse(value)?.path;
  if (path == null) return null;
  if (path == AppRoutes.login ||
      path == AppRoutes.forgotPassword ||
      path == AppRoutes.splash) {
    return null;
  }
  return value;
}
