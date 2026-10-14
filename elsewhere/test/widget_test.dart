import 'package:flutter_test/flutter_test.dart';

import 'package:elsewhere/app.dart';

void main() {
  testWidgets('Firebase setup fallback explains missing configuration',
      (tester) async {
    await tester.pumpWidget(
      const FirebaseSetupRequiredApp(message: 'Firebase options are missing.'),
    );

    expect(find.text('Connect Firebase to get going'), findsOneWidget);
    expect(find.text('Firebase options are missing.'), findsOneWidget);
  });
}
