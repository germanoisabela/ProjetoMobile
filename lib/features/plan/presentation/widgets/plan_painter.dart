import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/point_2d.dart';
import '../../domain/entities/wall.dart';
import 'plan_viewport.dart';

/// Desenha a planta, suas cotas, alças e a medição ativa.
class PlanPainter extends CustomPainter {
  final Plan plan;
  final PlanViewport viewport;
  final int? selectedWall;
  final int? draggedVertex;
  final bool showHandles;
  final Point2D? measureStart;
  final Point2D? measureEnd;

  const PlanPainter({
    required this.plan,
    required this.viewport,
    this.selectedWall,
    this.draggedVertex,
    this.showHandles = true,
    this.measureStart,
    this.measureEnd,
  });

  static const Color _selectedColor = Color(0xFFF9A825);
  static const Color _measureColor = Color(0xFF1565C0);
  static const double _labelGap = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final List<Wall> walls = plan.walls;
    final List<Offset> points = plan.vertices.map(viewport.toCanvas).toList();
    if (points.length < 3) return;

    canvas.drawPath(
      Path()..addPolygon(points, true),
      Paint()..color = AppColors.highlight,
    );
    _drawGrid(canvas, size);

    for (int i = 0; i < points.length; i++) {
      final bool selected = i == selectedWall;
      canvas.drawLine(
        points[i],
        points[(i + 1) % points.length],
        Paint()
          ..color = selected ? _selectedColor : AppColors.primary
          ..strokeWidth = selected ? 11 : 8
          ..strokeCap = StrokeCap.round,
      );
    }

    final Offset center =
        points.fold<Offset>(Offset.zero, (sum, point) => sum + point) /
            points.length.toDouble();
    for (int i = 0; i < walls.length; i++) {
      final Offset middle = (points[i] + points[(i + 1) % points.length]) / 2;
      final Offset outward = middle - center;
      if (outward.distance == 0) continue;

      final Offset direction = outward / outward.distance;
      final TextPainter label = _layoutText(
        '${formatDecimal(walls[i].lengthM)} m',
        i == selectedWall ? _selectedColor : AppColors.primary,
      );
      final double halfExtent = direction.dx.abs() * label.width / 2 +
          direction.dy.abs() * label.height / 2;
      _paintText(
        canvas,
        label,
        middle + direction * (_labelGap + halfExtent),
      );
    }

    _drawMeasurement(canvas);
    if (showHandles) {
      for (int i = 0; i < points.length; i++) {
        final bool dragged = i == draggedVertex;
        final double radius = dragged ? 14 : 9;
        canvas.drawCircle(points[i], radius, Paint()..color = Colors.white);
        canvas.drawCircle(
          points[i],
          radius,
          Paint()
            ..color = dragged ? _selectedColor : AppColors.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
    }
  }

  void _drawMeasurement(Canvas canvas) {
    final Point2D? start = measureStart;
    if (start == null) return;

    final Offset a = viewport.toCanvas(start);
    final Paint markerPaint = Paint()..color = _measureColor;
    final Point2D? end = measureEnd;
    if (end != null) {
      final Offset b = viewport.toCanvas(end);
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = _measureColor
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(b, 6, markerPaint);
      final TextPainter label = _layoutText(
        '${formatDecimal(start.distanceTo(end))} m',
        _measureColor,
      );
      _paintText(
        canvas,
        label,
        (a + b) / 2 + const Offset(0, -18),
        withBackground: true,
      );
    }
    canvas.drawCircle(a, 6, markerPaint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = const Color(0xFFB7D3BA)
      ..strokeWidth = 1;
    final Point2D topLeft = viewport.toMeters(Offset.zero);
    final Point2D bottomRight =
        viewport.toMeters(Offset(size.width, size.height));

    for (int meter = topLeft.x.ceil();
        meter <= bottomRight.x.floor();
        meter++) {
      final double x = viewport.toCanvas(Point2D(meter.toDouble(), 0)).dx;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (int meter = topLeft.y.ceil();
        meter <= bottomRight.y.floor();
        meter++) {
      final double y = viewport.toCanvas(Point2D(0, meter.toDouble())).dy;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  TextPainter _layoutText(String text, Color color) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  void _paintText(
    Canvas canvas,
    TextPainter textPainter,
    Offset center, {
    bool withBackground = false,
  }) {
    final Offset topLeft =
        center - Offset(textPainter.width / 2, textPainter.height / 2);
    if (withBackground) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          (topLeft & textPainter.size).inflate(3),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xE6FFFFFF),
      );
    }
    textPainter.paint(canvas, topLeft);
  }

  @override
  bool shouldRepaint(covariant PlanPainter oldDelegate) {
    return oldDelegate.plan != plan ||
        oldDelegate.viewport != viewport ||
        oldDelegate.selectedWall != selectedWall ||
        oldDelegate.draggedVertex != draggedVertex ||
        oldDelegate.showHandles != showHandles ||
        oldDelegate.measureStart != measureStart ||
        oldDelegate.measureEnd != measureEnd;
  }
}
