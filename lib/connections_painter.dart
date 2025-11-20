import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'entities/connection.dart';
import 'entities/builders/i_level_builder.dart'; // for kNodeWidth, kNodeHeight

class ConnectionsPainter extends CustomPainter {
  ConnectionsPainter({
    required this.connections,
    required this.nodePositions,
  });

  final List<Connection> connections;
  final Map<String, Offset> nodePositions;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final connection in connections) {
      final fromPos = nodePositions[connection.fromSubscriberId];
      final toPos = nodePositions[connection.toSubscriberId];

      if (fromPos == null || toPos == null) continue;

      // Node centers
      final fromCenter =
          Offset(fromPos.dx + kNodeWidth / 2, fromPos.dy + kNodeHeight / 2);
      final toCenter =
          Offset(toPos.dx + kNodeWidth / 2, toPos.dy + kNodeHeight / 2);

      // Calculate angle from Source to Target
      final double angle =
          math.atan2(toCenter.dy - fromCenter.dy, toCenter.dx - fromCenter.dx);

      // Calculate intersection points on the boundaries
      final Offset startPoint = _getBoundaryIntersection(fromCenter, angle);
      // For target, the incoming angle is opposite (angle + pi), but we want the point on the target boundary
      // that corresponds to the ray coming FROM source.
      // The ray hits the target at the point defined by 'angle' relative to source?
      // No, relative to Target center, the intersection is at (angle + pi).
      final Offset endBoundary =
          _getBoundaryIntersection(toCenter, angle + math.pi);

      // Apply gap to end point
      final double gap = 5.0;
      final Offset endPoint = Offset(
        endBoundary.dx - gap * math.cos(angle),
        endBoundary.dy - gap * math.sin(angle),
      );

      // Draw straight line
      canvas.drawLine(startPoint, endPoint, paint);

      // Draw arrow head
      _drawArrowHead(canvas, endPoint, angle, paint);

      // Draw label at center
      final Offset midPoint = Offset(
        (startPoint.dx + endPoint.dx) / 2,
        (startPoint.dy + endPoint.dy) / 2,
      );
      _drawLabel(canvas, midPoint, connection.count.toString());
    }
  }

  Offset _getBoundaryIntersection(Offset center, double angle) {
    final double halfWidth = kNodeWidth / 2;
    final double halfHeight = kNodeHeight / 2;

    // Ray: x = center.x + t * cos(angle)
    //      y = center.y + t * sin(angle)

    // We need to find t such that x is on boundary or y is on boundary.
    // Boundary x: center.x +/- halfWidth
    // Boundary y: center.y +/- halfHeight

    final double cos = math.cos(angle);
    final double sin = math.sin(angle);

    // Avoid division by zero
    final double tX =
        (cos.abs() < 1e-6) ? double.infinity : halfWidth / cos.abs();
    final double tY =
        (sin.abs() < 1e-6) ? double.infinity : halfHeight / sin.abs();

    final double t = math.min(tX, tY);

    return Offset(
      center.dx + t * cos,
      center.dy + t * sin,
    );
  }

  void _drawArrowHead(Canvas canvas, Offset tip, double angle, Paint paint) {
    final double arrowSize = 10.0;
    final path = Path();

    path.moveTo(tip.dx, tip.dy);
    path.lineTo(
      tip.dx - arrowSize * math.cos(angle - math.pi / 6),
      tip.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    path.lineTo(
      tip.dx - arrowSize * math.cos(angle + math.pi / 6),
      tip.dy - arrowSize * math.sin(angle + math.pi / 6),
    );
    path.close();

    canvas.drawPath(path, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
  }

  void _drawLabel(Canvas canvas, Offset center, String text) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.black,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.white.withOpacity(0.7),
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final offset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    );

    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant ConnectionsPainter oldDelegate) {
    return oldDelegate.connections != connections ||
        oldDelegate.nodePositions != nodePositions;
  }
}
