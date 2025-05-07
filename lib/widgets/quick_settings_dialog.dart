import 'package:flutter/material.dart';
import 'package:verse/theme/color_palette.dart';
import 'package:verse/theme/typography.dart';
import 'package:verse/utils/audio_manager.dart';

import '../utils/constants.dart';

class QuickSettingsDialog extends StatelessWidget {
  const QuickSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorPalette.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      title: Text(
        'Réglages Rapides',
        style: AppTypography.headlineSmall.copyWith(
          color: ColorPalette.primaryColor,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section Musique
            _buildMusicSection(),
            const SizedBox(height: 24),
            // Section Effets Sonores
            _buildSfxSection(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Fermer',
            style: AppTypography.button.copyWith(
              color: ColorPalette.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMusicSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Musique',
              style: AppTypography.bodyLarge.copyWith(
                color: ColorPalette.textColorPrimary,
              ),
            ),
            Switch(
              value: AudioManager.isMusicEnabled,
              onChanged: (value) => AudioManager.toggleMusic(value),
              activeColor: ColorPalette.accentColor,
            ),
          ],
        ),
        if (AudioManager.isMusicEnabled) ...[
          const SizedBox(height: 8),
          Text(
            'Volume: ${(AudioManager.getMusicVolume() * 100).round()}%',
            style: AppTypography.bodyMedium.copyWith(
              color: ColorPalette.textColorSecondary,
            ),
          ),
          Slider(
            value: AudioManager.getMusicVolume(),
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: '${(AudioManager.getMusicVolume() * 100).round()}%',
            activeColor: ColorPalette.accentColor,
            inactiveColor: ColorPalette.textColorSecondary.withOpacity(0.2),
            onChanged: (value) => AudioManager.setMusicVolume(value),
          ),
        ],
      ],
    );
  }

  Widget _buildSfxSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Effets Sonores',
              style: AppTypography.bodyLarge.copyWith(
                color: ColorPalette.textColorPrimary,
              ),
            ),
            Switch(
              value: AudioManager.isSfxEnabled,
              onChanged: (value) => AudioManager.toggleSfx(value),
              activeColor: ColorPalette.accentColor,
            ),
          ],
        ),
        if (AudioManager.isSfxEnabled) ...[
          const SizedBox(height: 8),
          Text(
            'Volume: ${(AudioManager.getSfxVolume() * 100).round()}%',
            style: AppTypography.bodyMedium.copyWith(
              color: ColorPalette.textColorSecondary,
            ),
          ),
          Slider(
            value: AudioManager.getSfxVolume(),
            min: 0.0,
            max: 1.0,
            divisions: 10,
            label: '${(AudioManager.getSfxVolume() * 100).round()}%',
            activeColor: ColorPalette.accentColor,
            inactiveColor: ColorPalette.textColorSecondary.withOpacity(0.2),
            onChanged: (value) async {
              await AudioManager.setSfxVolume(value);
              await AudioManager.playSoundEffect(GameConstants.collisionSound);
            },
          ),
        ],
      ],
    );
  }
}
