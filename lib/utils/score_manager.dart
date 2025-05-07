import 'package:shared_preferences/shared_preferences.dart';
import 'package:verse/utils/constants.dart';

class ScoreManager {
  static Future<List<int>> getHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    final scoresStringList =
        prefs.getStringList(GameConstants.highScoresKey) ?? [];
    return scoresStringList.map(int.parse).toList()
      ..sort((a, b) => b.compareTo(a))
      ..take(GameConstants.maxHighScores).toList();
  }

  static Future<void> saveScore(int newScore) async {
    final prefs = await SharedPreferences.getInstance();
    final highScores = await getHighScores();

    highScores.add(newScore);
    highScores.sort((a, b) => b.compareTo(a));

    final topScores = highScores.take(GameConstants.maxHighScores).toList();

    final scoresStringList =
        topScores.map((score) => score.toString()).toList();

    await prefs.setStringList(GameConstants.highScoresKey, scoresStringList);
  }

  static Future<void> clearHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(GameConstants.highScoresKey);
  }
}
