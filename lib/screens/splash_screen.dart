import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:verse/theme/color_palette.dart';
import 'package:verse/theme/typography.dart';
import 'package:verse/screens/main_menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _opacityAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('fonts/logo.jpg', height: 150),
              SizedBox(height: 30),
              Text(
                'SNAKE',
                style: AppTypography.headlineLarge.copyWith(
                  color: ColorPalette.primaryColor,
                ),
              ),
              AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'game',
                    textStyle: AppTypography.headlineLarge.copyWith(
                      color: ColorPalette.secondaryColor,
                    ),
                    speed: const Duration(milliseconds: 200),
                  ),
                ],
                totalRepeatCount: 1,
                pause: const Duration(milliseconds: 500),
              ),
              SizedBox(height: 20),
              Text(
                'Un jeu de serpent en réalité augmentée',
                style: AppTypography.bodyMedium.copyWith(
                  color: ColorPalette.textColorSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              DefaultTextStyle(
                style: AppTypography.bodySmall.copyWith(
                  color: ColorPalette.accentColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Chargement des dimensions '),
                    AnimatedTextKit(
                      animatedTexts: [
                        RotateAnimatedText(
                          '3D',
                          duration: const Duration(milliseconds: 500),
                        ),
                        RotateAnimatedText(
                          'AR',
                          duration: const Duration(milliseconds: 500),
                        ),
                        RotateAnimatedText(
                          'du jeu...',
                          duration: const Duration(milliseconds: 500),
                        ),
                      ],
                      totalRepeatCount: 1,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50),

              /// **Ajout du bouton "Continuer" pour aller à l'écran principal**
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => MainMenuScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorPalette.primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Continuer',
                  style: AppTypography.bodyLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
