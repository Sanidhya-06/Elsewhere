import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const ElsewhereApp());
  } catch (error, stack) {
    // Keep the app launchable before a developer has connected Firebase.
    runApp(FirebaseSetupRequiredApp(message: error.toString()));
    debugPrint('Firebase initialisation failed: $error\n$stack');
  }
}
