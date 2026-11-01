// ============================================================
// lib/main.dart
// ============================================================
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/auth/login_screen.dart';

void main() {
  runApp(const SkinSavvyApp());
}

class SkinSavvyApp extends StatelessWidget {
  const SkinSavvyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkinSavvy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}