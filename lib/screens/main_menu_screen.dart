import 'package:flutter/material.dart';
import 'package:verse/screens/game_screen.dart';
import 'package:verse/screens/game_screen_2.dart';
import 'package:verse/widgets/futuristic_button.dart';
import 'package:verse/theme/color_palette.dart';
import 'package:verse/theme/typography.dart';
import 'package:verse/screens/ar_game_screen.dart';
import 'package:verse/screens/settings_screen.dart';
import 'package:verse/screens/high_scores_screen.dart';
import 'package:verse/screens/tutorial_screen.dart';
import 'package:verse/utils/audio_manager.dart';
import 'package:verse/screens/test.dart'; // Import the test screen

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    AudioManager.playBackgroundMusic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundColor,
      appBar: AppBar(
        title: Text('Snake Verse', style: AppTypography.headlineSmall),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Bienvenue dans',
                    style: AppTypography.headlineMedium.copyWith(
                      color: ColorPalette.textColorSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'SnakeVerse',
                    style: AppTypography.headlineLarge.copyWith(
                      color: ColorPalette.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60.0),
                  FuturisticButton(
                    text: 'Jouer',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => ArGameScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16.0),
                  FuturisticButton(
                    text: 'Paramètres',
                    icon: Icons.settings_rounded,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16.0),
                  FuturisticButton(
                    text: 'Meilleurs Scores',
                    icon: Icons.leaderboard_rounded,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => HighScoresScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16.0),
                  FuturisticButton(
                    text: 'Tutoriel',
                    icon: Icons.school_rounded,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TutorialScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16.0),
                  FuturisticButton(
                    text: 'Test',
                    icon: Icons.bug_report,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => GameScreen_2(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40.0),
                ],
              ),
            ),
          ),
          // Improved Footer
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Increased padding
              decoration: BoxDecoration(
                color: ColorPalette.surfaceColor.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24.0), // More rounded corners
                  topRight: Radius.circular(24.0),
                ),
                boxShadow: [       // Added shadow for better separation
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'À propos de SnakeVerse',
                    style: AppTypography.headlineSmall.copyWith(
                      color: ColorPalette.primaryColor,
                      fontWeight: FontWeight.w600, // Make the title bold
                    ),
                  ),
                  const SizedBox(height: 12.0), // Increased spacing
                  Text(
                    'Version: 1.0.0',
                    style: AppTypography.bodySmall.copyWith(
                      color: ColorPalette.textColorSecondary,
                      fontStyle: FontStyle.italic, // Added italic style
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Développé par Groupe 4',
                    style: AppTypography.bodySmall.copyWith(
                      color: ColorPalette.textColorSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12.0), // Increased spacing
                  Text(
                    'Copyright © 2025. Tous droits réservés.',
                    style: AppTypography.caption.copyWith(
                      color: ColorPalette.textColorHint,
                      fontSize: 10, // Reduced font size
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
