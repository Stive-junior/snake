import 'package:flutter/material.dart';
import 'package:verse/theme/color_palette.dart';
import 'package:verse/theme/typography.dart';
import 'package:verse/widgets/futuristic_button.dart';
import 'package:verse/screens/main_menu_screen.dart';
import 'package:verse/widgets/quick_settings_dialog.dart';

class PauseScreen extends StatelessWidget {
  final VoidCallback onResume;

  const PauseScreen({super.key, required this.onResume});

  void _showQuickSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const QuickSettingsDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ignore: deprecated_member_use
      backgroundColor: ColorPalette.backgroundColor.withOpacity(0.8),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'Pause',
                style: AppTypography.headlineLarge.copyWith(
                  color: ColorPalette.primaryColor,
                ),
              ),
              const SizedBox(height: 40),
              FuturisticButton(
                text: 'Reprendre',
                icon: Icons.play_arrow_rounded,
                onPressed: onResume,
              ),
              const SizedBox(height: 20),
              FuturisticButton(
                text: 'Réglages Rapides',
                icon: Icons.settings_rounded,
                onPressed: () => _showQuickSettings(context),
              ),
              const SizedBox(height: 20),
              FuturisticButton(
                text: 'Menu Principal',
                icon: Icons.home_rounded,
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => MainMenuScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
