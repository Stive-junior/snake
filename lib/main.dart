import 'package:flutter/material.dart';
import 'package:verse/theme/app_theme.dart';
import 'package:verse/screens/splash_screen.dart';

void main() {
  runApp(const SnakeVerseApp());
}

class SnakeVerseApp extends StatelessWidget {
  const SnakeVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnakeVerse',
      theme: AppTheme.darkTheme,
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
