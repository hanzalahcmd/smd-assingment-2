import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:forums_app/core/di/injection.dart';
import 'package:forums_app/core/theme/app_theme.dart';
import 'package:forums_app/features/auth/bloc/auth_bloc.dart';
import 'package:forums_app/features/auth/screens/login_screen.dart';
import 'package:forums_app/features/forum/screens/home_screen.dart';

class ForumsApp extends StatelessWidget {
  const ForumsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(authRepository: sl())
        ..add(const AuthCheckRequested()),
      child: MaterialApp(
        title: 'UniForums',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthInitial || state is AuthLoading) {
              return const _SplashScreen();
            }
            if (state is AuthAuthenticated) {
              return const HomeScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.forum_rounded, color: cs.primary, size: 36),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(color: cs.primary),
          ],
        ),
      ),
    );
  }
}
