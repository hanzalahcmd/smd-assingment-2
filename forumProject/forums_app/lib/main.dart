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
