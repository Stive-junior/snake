// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:verse/theme/color_palette.dart';
import 'package:verse/theme/typography.dart';

class FuturisticButton extends StatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;

  const FuturisticButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
  });

  @override
  _FuturisticButtonState createState() => _FuturisticButtonState();
}

class _FuturisticButtonState extends State<FuturisticButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color:
              _isHovering
                  // ignore: deprecated_member_use
                  ? ColorPalette.secondaryColor.withOpacity(0.8)
                  : ColorPalette.surfaceColor,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color:
                _isHovering
                    ? ColorPalette.accentColor
                    : ColorPalette.primaryColor,
            width: 2.0,
          ),
          boxShadow:
              _isHovering
                  ? [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: ColorPalette.accentColor.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ]
                  : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10.0),
            onTap: widget.onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: ColorPalette.textColorPrimary),
                    const SizedBox(width: 10.0),
                  ],
                  Text(widget.text, style: AppTypography.button),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
