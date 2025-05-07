import 'package:flutter/material.dart';
import 'package:verse/theme/color_palette.dart';
import 'package:verse/theme/typography.dart';
import 'package:verse/widgets/futuristic_button.dart';
import 'package:verse/screens/ar_game_screen.dart';
import 'package:verse/screens/main_menu_screen.dart';
import 'package:animate_do/animate_do.dart';

class GameOverScreen extends StatelessWidget {
  final int score;

  const GameOverScreen({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              FadeInDown(
                duration: const Duration(milliseconds: 800),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sentiment_very_dissatisfied_rounded,
                      size: 40,
                      color: ColorPalette.errorColor,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Partie Terminée !',
                      style: AppTypography.headlineLarge.copyWith(
                        color: ColorPalette.errorColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.sentiment_very_dissatisfied_rounded,
                      size: 40,
                      color: ColorPalette.errorColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              FadeIn(
                delay: const Duration(milliseconds: 500),
                duration: const Duration(milliseconds: 800),
                child: Text(
                  'Votre Score:',
                  style: AppTypography.headlineMedium.copyWith(
                    color: ColorPalette.textColorSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ZoomIn(
                delay: const Duration(milliseconds: 700),
                duration: const Duration(milliseconds: 800),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star_border,
                      size: 40,
                      color: ColorPalette.accentColor,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$score',
                      style: AppTypography.headlineLarge.copyWith(
                        color: ColorPalette.accentColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),
              FadeInUp(
                delay: const Duration(milliseconds: 900),
                duration: const Duration(milliseconds: 800),
                child: FuturisticButton(
                  text: 'Rejouer',
                  icon: Icons.replay_rounded,
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const ArGameScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              FadeInUp(
                delay: const Duration(milliseconds: 1100),
                duration: const Duration(milliseconds: 800),
                child: FuturisticButton(
                  text: 'Menu Principal',
                  icon: Icons.home_rounded,
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => MainMenuScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
