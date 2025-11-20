import 'package:flutter/material.dart';

class LevelsPainter extends CustomPainter {
  LevelsPainter({
    required this.levelsHeight,
  });

  final Map<int, double> levelsHeight;

  @override
  void paint(Canvas canvas, Size size) {
    double top = 0;
    // Draw very wide to simulate infinite horizontal space
    const double extraWidth = 50000.0;

    const double extraHeight = 50000.0;
    final keys = levelsHeight.keys
        .toList(); // Assumes sorted by DiagramManager logic, but let's be safe?
    // DiagramManager sorts them. But Map iteration might not guarantee it if modified?
    // Actually DiagramManager creates a new Map in order.

    for (int i = 0; i < keys.length; i++) {
      final int level = keys[i];
      final double height = levelsHeight[level]!;

      double rectTop = top;
      double rectBottom = top + height;

      // First level extends up
      if (i == 0) {
        rectTop -= extraHeight;
      }

      // Last level extends down
      if (i == keys.length - 1) {
        rectBottom += extraHeight;
      }

      final Rect rect = Rect.fromLTRB(
          -extraWidth, rectTop, size.width + extraWidth, rectBottom);
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
    }
  }

  @override
  bool shouldRepaint(covariant LevelsPainter oldDelegate) {
    return oldDelegate.levelsHeight.length != levelsHeight.length;
  }
}
