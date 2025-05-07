import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verse/theme/color_palette.dart';
import 'package:verse/theme/typography.dart';
import 'package:verse/utils/audio_manager.dart';
import 'package:verse/utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _musicVolume;
  late double _sfxVolume;
  late bool _isMusicEnabled;
  late bool _isSfxEnabled;
  bool _showFps = false;
  static const String _showFpsKey = 'showFps';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _musicVolume = AudioManager.getMusicVolume();
      _sfxVolume = AudioManager.getSfxVolume();
      _isMusicEnabled = AudioManager.isMusicEnabled;
      _isSfxEnabled = AudioManager.isSfxEnabled;
      _showFps = prefs.getBool(_showFpsKey) ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showFpsKey, _showFps);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundColor,
      appBar: AppBar(
        title: Text('Paramètres', style: AppTypography.headlineSmall),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Audio
            _buildSectionTitle('Audio'),
            _buildMusicSettings(),
            const SizedBox(height: 20),
            _buildSfxSettings(),
            const SizedBox(height: 30),
            
            // Section Affichage
            _buildSectionTitle('Affichage'),
            _buildFpsToggle(),
            const SizedBox(height: 30),
            
            // Boutons de contrôle
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: AppTypography.headlineSmall.copyWith(
          color: ColorPalette.primaryColor,
        ),
      ),
    );
  }

  Widget _buildMusicSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                  value: _isMusicEnabled,
                  onChanged: (value) async {
                    await AudioManager.toggleMusic(value);
                    setState(() => _isMusicEnabled = value);
                  },
                  activeColor: ColorPalette.accentColor,
                ),
              ],
            ),
            if (_isMusicEnabled) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Volume',
                    style: AppTypography.bodyMedium.copyWith(
                      color: ColorPalette.textColorSecondary,
                    ),
                  ),
                  Text(
                    '${(_musicVolume * 100).round()}%',
                    style: AppTypography.bodyMedium.copyWith(
                      color: ColorPalette.accentColor,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _musicVolume,
                min: 0,
                max: 1,
                divisions: 10,
                activeColor: ColorPalette.accentColor,
                inactiveColor: ColorPalette.textColorSecondary.withOpacity(0.2),
                onChanged: (value) async {
                  await AudioManager.setMusicVolume(value);
                  setState(() => _musicVolume = value);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSfxSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Effets sonores',
                  style: AppTypography.bodyLarge.copyWith(
                    color: ColorPalette.textColorPrimary,
                  ),
                ),
                Switch(
                  value: _isSfxEnabled,
                  onChanged: (value) async {
                    await AudioManager.toggleSfx(value);
                    setState(() => _isSfxEnabled = value);
                  },
                  activeColor: ColorPalette.accentColor,
                ),
              ],
            ),
            if (_isSfxEnabled) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Volume',
                    style: AppTypography.bodyMedium.copyWith(
                      color: ColorPalette.textColorSecondary,
                    ),
                  ),
                  Text(
                    '${(_sfxVolume * 100).round()}%',
                    style: AppTypography.bodyMedium.copyWith(
                      color: ColorPalette.accentColor,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _sfxVolume,
                min: 0,
                max: 1,
                divisions: 10,
                activeColor: ColorPalette.accentColor,
                inactiveColor: ColorPalette.textColorSecondary.withOpacity(0.2),
                onChanged: (value) async {
                  await AudioManager.setSfxVolume(value);
                  await AudioManager.playSoundEffect(GameConstants.collisionSound);
                  setState(() => _sfxVolume = value);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFpsToggle() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Afficher les FPS',
              style: AppTypography.bodyLarge.copyWith(
                color: ColorPalette.textColorPrimary,
              ),
            ),
            Switch(
              value: _showFps,
              onChanged: (value) {
                setState(() => _showFps = value);
                _saveSettings();
              },
              activeColor: ColorPalette.accentColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorPalette.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Retour',
            style: AppTypography.button.copyWith(
              color: Colors.white,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _resetToDefaults,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorPalette.errorColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Réinitialiser',
            style: AppTypography.button.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _resetToDefaults() async {
    await AudioManager.setMusicVolume(1.0);
    await AudioManager.setSfxVolume(1.0);
    await AudioManager.toggleMusic(true);
    await AudioManager.toggleSfx(true);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showFpsKey, false);
    
    setState(() {
      _musicVolume = 1.0;
      _sfxVolume = 1.0;
      _isMusicEnabled = true;
      _isSfxEnabled = true;
      _showFps = false;
    });
    
    // Jouer un son de confirmation
    await AudioManager.playSoundEffect(GameConstants.collisionSound);
  }
}
