import 'package:flutter/material.dart';

class LevelsPainter extends CustomPainter {
  LevelsPainter({
    required this.levelsHeight,
  });

  final Map<int, double> levelsHeight;

  @override
  void paint(Canvas canvas, Size size) {
    double top = 0;
    levelsHeight.forEach((int level, double height) {
      final Rect rect = Rect.fromLTWH(0, top, size.width, height);
      final Paint paint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFF2E2E2E), Color(0xFF222222)],
        ).createShader(rect);
      canvas.drawRect(rect, paint);
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: '$level',
          style: const TextStyle(color: Color(0xFF808080), fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final double textY = top + (height - textPainter.height) / 2;
      textPainter.paint(canvas, Offset(8, textY));

      top += height;
    });
  }

  @override
  bool shouldRepaint(covariant LevelsPainter oldDelegate) {
    return oldDelegate.levelsHeight.length != levelsHeight.length;
  }
}
