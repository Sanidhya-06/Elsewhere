import 'package:flutter_test/flutter_test.dart';
import 'package:elsewhere/core/router/redirect.dart';
import 'package:elsewhere/core/router/routes.dart';
import 'package:elsewhere/providers/auth_provider.dart';

void main() {
  group('resolveRedirect', () {
    test('unknown session is sent to splash', () {
      expect(resolveRedirect(Uri.parse('/home'), AuthStatus.unknown),
          '/?from=%2Fhome');
    });
    test('unknown session remembers nested destinations and query parameters',
        () {
      expect(
          resolveRedirect(
              Uri.parse('/trips/abc/budget?tab=food'), AuthStatus.unknown),
          '/?from=%2Ftrips%2Fabc%2Fbudget%3Ftab%3Dfood');
      expect(resolveRedirect(Uri.parse('/login'), AuthStatus.unknown),
          AppRoutes.splash);
    });
    test('signed-out splash goes to login', () {
      expect(resolveRedirect(Uri.parse('/'), AuthStatus.unauthenticated),
          AppRoutes.login);
    });
    test('signed-out protected page remembers destination', () {
      expect(
          resolveRedirect(Uri.parse('/trips/abc'), AuthStatus.unauthenticated),
          '/login?from=%2Ftrips%2Fabc');
    });
    test('authenticated users leave public routes for home', () {
      expect(resolveRedirect(Uri.parse('/login'), AuthStatus.authenticated),
          AppRoutes.home);
      expect(
          resolveRedirect(Uri.parse('/forgot-password?from=%2Ftrips%2Fabc'),
              AuthStatus.authenticated),
          '/trips/abc');
    });
    test('authenticated users remain on protected destinations', () {
      expect(
          resolveRedirect(
              Uri.parse('/trips/abc/budget'), AuthStatus.authenticated),
          isNull);
    });
    test('signed-out users may remain on public routes', () {
      expect(
          resolveRedirect(
              Uri.parse('/forgot-password'), AuthStatus.unauthenticated),
          isNull);
    });
    test('unsafe external redirect is ignored', () {
      expect(
          resolveRedirect(Uri.parse('/?from=https%3A%2F%2Fevil.example'),
              AuthStatus.unauthenticated),
          AppRoutes.login);
    });
  });
}
