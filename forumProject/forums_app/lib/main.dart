//22k-4156,22k-4574, 22k-4431,22k-4494
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:forums_app/app.dart';
import 'package:forums_app/core/di/injection.dart';


import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await setupDependencies();

  runApp(const ForumsApp());
}
