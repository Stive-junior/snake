import 'package:flutter/material.dart';
import 'package:verse/theme/color_palette.dart';
import 'package:verse/theme/typography.dart';

class ScoreDisplay extends StatelessWidget {
  final int score;

  const ScoreDisplay({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: ColorPalette.surfaceColor.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: ColorPalette.accentColor.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_border, color: ColorPalette.accentColor),
          const SizedBox(width: 8.0),
          Text(
            'Score: $score',
            style: AppTypography.bodyLarge.copyWith(
              color: ColorPalette.textColorPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
