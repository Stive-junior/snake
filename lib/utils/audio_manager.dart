import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verse/utils/constants.dart';

class AudioManager {
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static final AudioPlayer _musicPlayer = AudioPlayer();
  static bool _isMusicEnabled = true;
  static bool _isSfxEnabled = true;
  static const String _musicVolumeKey = 'musicVolume';
  static const String _sfxVolumeKey = 'sfxVolume';
  static const String _musicEnabledKey = 'musicEnabled';
  static const String _sfxEnabledKey = 'sfxEnabled';
  static double _currentMusicVolume = 1.0;
  static double _currentSfxVolume = 1.0;
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _currentMusicVolume = prefs.getDouble(_musicVolumeKey) ?? 1.0;
    _currentSfxVolume = prefs.getDouble(_sfxVolumeKey) ?? 1.0;
    _isMusicEnabled = prefs.getBool(_musicEnabledKey) ?? true;
    _isSfxEnabled = prefs.getBool(_sfxEnabledKey) ?? true;

    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.setVolume(_isMusicEnabled ? _currentMusicVolume : 0.0);
    await _sfxPlayer.setVolume(_isSfxEnabled ? _currentSfxVolume : 0.0);

    _isInitialized = true;
  }

  static Future<void> playSoundEffect(String soundPath) async {
    if (!_isSfxEnabled) return;
    try {
      await _sfxPlayer.stop();
      await _sfxPlayer.play(AssetSource(soundPath));
    } catch (e) {
      debugPrint('Error playing sound effect: $e');
    }
  }

  static Future<void> playBackgroundMusic() async {
    if (!_isMusicEnabled) return;
    try {
      await _musicPlayer.play(AssetSource(GameConstants.backgroundMusic));
    } catch (e) {
      debugPrint('Error playing background music: $e');
    }
  }

  static Future<void> pauseBackgroundMusic() async {
    await _musicPlayer.pause();
  }

  static Future<void> resumeBackgroundMusic() async {
    if (_isMusicEnabled) {
      await _musicPlayer.resume();
    }
  }

  static Future<void> stopBackgroundMusic() async {
    await _musicPlayer.stop();
  }

  // Volume control
  static Future<void> setMusicVolume(double volume) async {
    _currentMusicVolume = volume.clamp(0.0, 1.0);
    await _musicPlayer.setVolume(_isMusicEnabled ? _currentMusicVolume : 0.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_musicVolumeKey, _currentMusicVolume);
  }

  static Future<void> setSfxVolume(double volume) async {
    _currentSfxVolume = volume.clamp(0.0, 1.0);
    await _sfxPlayer.setVolume(_isSfxEnabled ? _currentSfxVolume : 0.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_sfxVolumeKey, _currentSfxVolume);
  }

  // Toggle methods
  static Future<void> toggleMusic(bool enabled) async {
    _isMusicEnabled = enabled;
    await _musicPlayer.setVolume(enabled ? _currentMusicVolume : 0.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicEnabledKey, enabled);

    if (enabled) {
      await resumeBackgroundMusic();
    } else {
      await pauseBackgroundMusic();
    }
  }

  static Future<void> toggleSfx(bool enabled) async {
    _isSfxEnabled = enabled;
    await _sfxPlayer.setVolume(enabled ? _currentSfxVolume : 0.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sfxEnabledKey, enabled);
  }

  // Getters
  static double getMusicVolume() => _currentMusicVolume;
  static double getSfxVolume() => _currentSfxVolume;
  static bool get isMusicEnabled => _isMusicEnabled;
  static bool get isSfxEnabled => _isSfxEnabled;

  static Future<void> dispose() async {
    await _sfxPlayer.dispose();
    await _musicPlayer.dispose();
    _isInitialized = false;
  }
}