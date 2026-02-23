import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/firebase_service.dart';

/// Application entry point
/// Initializes Firebase and launches the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  runApp(const ProviderScope(child: HostelAssistApp()));
}
