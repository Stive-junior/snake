import 'package:flutter/material.dart';
import 'package:verse/widgets/futuristic_button.dart';
import 'package:verse/theme/color_palette.dart';
import 'package:verse/theme/typography.dart';
import 'package:verse/screens/ar_game_screen.dart';
import 'package:verse/screens/settings_screen.dart';
import 'package:verse/screens/high_scores_screen.dart';
import 'package:verse/screens/tutorial_screen.dart';
import 'package:verse/utils/audio_manager.dart';

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
                  const SizedBox(height: 40.0),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: ColorPalette.surfaceColor.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'À propos de SnakeVerse',
                    style: AppTypography.headlineSmall.copyWith(
                      color: ColorPalette.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Version: 1.0.0',
                    style: AppTypography.bodySmall.copyWith(
                      color: ColorPalette.textColorSecondary,
                    ),
                  ),
                  Text(
                    'Développé par Groupe 4',
                    style: AppTypography.bodySmall.copyWith(
                      color: ColorPalette.textColorSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Copyright © 2025. Tous droits réservés.',
                    style: AppTypography.caption.copyWith(
                      color: ColorPalette.textColorHint,
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
