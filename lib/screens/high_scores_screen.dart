import 'package:flutter/material.dart';
import 'package:verse/theme/color_palette.dart';
import 'package:verse/theme/typography.dart';
import 'package:verse/utils/score_manager.dart';

class HighScoresScreen extends StatefulWidget {
  const HighScoresScreen({super.key});

  @override
  State<HighScoresScreen> createState() => _HighScoresScreenState();
}

class _HighScoresScreenState extends State<HighScoresScreen> {
  late Future<List<int>> _highScoresFuture;

  @override
  void initState() {
    super.initState();
    _highScoresFuture = ScoreManager.getHighScores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorPalette.backgroundColor,
      appBar: AppBar(
        title: Text('Meilleurs Scores', style: AppTypography.headlineSmall),
        centerTitle: true,
      ),
      body: FutureBuilder<List<int>>(
        future: _highScoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: ColorPalette.accentColor),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erreur lors du chargement des scores: ${snapshot.error}',
                style: AppTypography.bodyMedium.copyWith(
                  color: ColorPalette.errorColor,
                ),
              ),
            );
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final highScores = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: highScores.length,
              itemBuilder: (context, index) {
                return Card(
                  color: ColorPalette.surfaceColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star, color: ColorPalette.accentColor),
                            const SizedBox(width: 8.0),
                            Text(
                              '${index + 1}.',
                              style: AppTypography.bodyLarge.copyWith(
                                color: ColorPalette.textColorPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${highScores[index]}',
                          style: AppTypography.headlineSmall.copyWith(
                            color: ColorPalette.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(
              child: Text(
                'Aucun score enregistré pour le moment.',
                style: AppTypography.bodyLarge.copyWith(
                  color: ColorPalette.textColorSecondary,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
