import 'package:flutter/material.dart';
import 'package:verse/theme/color_palette.dart';
import 'package:verse/theme/typography.dart';
import 'package:verse/screens/ar_game_screen.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  final List<Map<String, dynamic>> _tutorialData = [
    {
      'title': 'Bienvenue dans Snakegame !',
      'content':
          'Glissez votre doigt sur l\'écran pour diriger le serpent dans le monde réel capturé par votre caméra.',
      'imagePath': 'assets/images/tutorial_swipe.png',
    },
    {
      'title': 'Mangez pour grandir',
      'content':
          'Guidez le serpent vers la nourriture lumineuse qui apparaît dans votre environnement pour le faire grandir et augmenter votre score.',
      'imagePath': 'assets/images/tutorial_eat.png',
    },
    {
      'title': 'Attention aux collisions !',
      'content':
          'Évitez de heurter les bords de l\'espace de jeu virtuel ou votre propre corps. Une collision mettra fin à votre aventure.',
      'imagePath': 'assets/images/tutorial_collide.png',
    },
    {
      'title': 'Explorez les paramètres',
      'content':
          'Personnalisez votre expérience en ajustant le thème visuel, la sensibilité des contrôles et le volume des effets sonores depuis le menu principal.',
      'icon': Icons.settings_rounded,
    },
    {
      'title': 'Prêt à l\'immersion !',
      'content':
          'Retournez au menu principal, activez votre caméra et plongez dans le monde fascinant de Snakegame !',
      'icon': Icons.play_arrow_rounded,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundColor,
      appBar: AppBar(
        title: Text('Tutoriel', style: AppTypography.headlineSmall),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _tutorialData.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final data = _tutorialData[index];
                return _buildTutorialPage(
                  title: data['title'],
                  content: data['content'],
                  imagePath: data['imagePath'],
                  icon: data['icon'],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  ElevatedButton(
                    style: _previousButtonStyle(),
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text('Précédent'),
                  ),
                const Spacer(),
                if (_currentPage < _tutorialData.length - 1)
                  ElevatedButton(
                    style: _nextButtonStyle(),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text('Suivant'),
                  ),
                if (_currentPage == _tutorialData.length - 1) ...[
                  const Spacer(),
                  ElevatedButton(
                    style: _startGameButtonStyle(),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => ArGameScreen()),
                      );
                    },
                    child: const Text('Commencer'),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildPageIndicator(),
            ),
          ),
          if (_currentPage == _tutorialData.length - 1)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                style: _returnMenuButtonStyle(),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Retour au Menu'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTutorialPage({
    String? title,
    String? content,
    String? imagePath,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (title != null)
            Text(
              title,
              style: AppTypography.headlineMedium.copyWith(
                color: ColorPalette.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 20),
          if (content != null)
            Text(
              content,
              style: AppTypography.bodyLarge.copyWith(
                color: ColorPalette.textColorSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          if (imagePath != null) ...[
            const SizedBox(height: 30),
            Image.asset(imagePath, height: 150),
          ],
          if (icon != null) ...[
            const SizedBox(height: 30),
            Icon(icon, size: 80, color: ColorPalette.accentColor),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildPageIndicator() {
    final List<Widget> indicators = [];
    for (int i = 0; i < _tutorialData.length; i++) {
      indicators.add(_currentPage == i ? _indicator(true) : _indicator(false));
    }
    return indicators;
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 8.0,
      width: isActive ? 24.0 : 16.0,
      decoration: BoxDecoration(
        color:
            isActive
                ? ColorPalette.accentColor
                : ColorPalette.textColorSecondary,
        borderRadius: BorderRadius.circular(12.0),
      ),
    );
  }

  ButtonStyle _previousButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: ColorPalette.surfaceColor,
      foregroundColor: ColorPalette.primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: ColorPalette.primaryColor),
      ),
    );
  }

  ButtonStyle _nextButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: ColorPalette.primaryColor,
      foregroundColor: ColorPalette.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    );
  }

  ButtonStyle _startGameButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: ColorPalette.accentColor,
      foregroundColor: ColorPalette.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    );
  }

  ButtonStyle _returnMenuButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: ColorPalette.surfaceColor,
      foregroundColor: ColorPalette.textColorPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: ColorPalette.textColorSecondary),
      ),
    );
  }
}
