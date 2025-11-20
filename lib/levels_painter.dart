import 'package:flutter/material.dart';

class LevelsPainter extends CustomPainter {
  LevelsPainter({
    required this.levelsHeight,
    required this.viewportTransform,
  });

  final Map<int, double> levelsHeight;
  final Matrix4 viewportTransform;

  @override
  void paint(Canvas canvas, Size size) {
    double top = 0;
    // Draw very wide to simulate infinite horizontal space
    const double extraWidth = 50000.0;

    const double extraHeight = 50000.0;
    final keys = levelsHeight.keys.toList();

    // Calculate sticky X position
    // Transform: x_screen = scale * x_world + tx
    // We want x_screen = 8 (padding)
    // x_world = (8 - tx) / scale
    final double scale = viewportTransform.getMaxScaleOnAxis();
    final double tx = viewportTransform.getTranslation().x;
    // Ensure text doesn't go off the left side of the diagram content (optional, but good for sanity)
    // Actually, we want it to stick to the screen edge, even if that's "before" the diagram starts visually.
    // But since we draw infinite background, it's fine.
    // We just need to make sure we don't draw it too far right if the user pans way left?
    // No, if user pans left (tx > 0), the diagram moves right. The left edge of screen is still 0.
    // So x_world will be negative. That's fine.

    final double stickyX = (8.0 - tx) / scale;

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
      textPainter.paint(canvas, Offset(stickyX, textY));

      top += height;
    }
  }

  @override
  bool shouldRepaint(covariant LevelsPainter oldDelegate) {
    return oldDelegate.levelsHeight.length != levelsHeight.length ||
        oldDelegate.viewportTransform != viewportTransform;
  }
}
