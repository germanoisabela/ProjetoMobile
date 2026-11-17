import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/point_2d.dart';
import 'plan_viewport.dart';

/// Desenha piso, grade, paredes, medidas e alças dos vértices.
class PlanPainter extends CustomPainter {
  final Plan plan;
  final PlanViewport viewport;
  final int? selectedWall;
  final int? draggedVertex;
  final bool showHandles;

  const PlanPainter({
    required this.plan,
    required this.viewport,
    this.selectedWall,
    this.draggedVertex,
    this.showHandles = true,
  });

  static const Color _selectedColor = Color(0xFFF9A825);
  static const double _labelDistance = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final List<Offset> points = plan.vertices
        .map(viewport.toCanvas)
        .toList(growable: false);
    if (points.length < 3) return;

    canvas.drawPath(
      Path()..addPolygon(points, true),
      Paint()..color = AppColors.highlight,
    );

    _drawGrid(canvas, size);

    for (int i = 0; i < points.length; i++) {
      canvas.drawLine(
        points[i],
        points[(i + 1) % points.length],
        Paint()
          ..color = i == selectedWall ? _selectedColor : AppColors.primary
          ..strokeWidth = i == selectedWall ? 11 : 8
          ..strokeCap = StrokeCap.round,
      );
    }

    final Offset center =
        points.fold<Offset>(Offset.zero, (sum, point) => sum + point) /
        points.length.toDouble();

    final walls = plan.walls;
    for (int i = 0; i < walls.length; i++) {
      final Offset start = points[i];
      final Offset end = points[(i + 1) % points.length];
      final Offset middle = (start + end) / 2;
      final Offset outward = middle - center;
      if (outward.distance == 0) continue;

      final Offset direction = outward / outward.distance;
      _drawLabel(
        canvas,
        '${formatDecimal(walls[i].lengthM)} m',
        middle + direction * _labelDistance,
        i == selectedWall ? _selectedColor : AppColors.primary,
      );
    }

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

  void _drawGrid(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = const Color(0xFFB7D3BA)
      ..strokeWidth = 1;
    final Point2D topLeft = viewport.toMeters(Offset.zero);
    final Point2D bottomRight = viewport.toMeters(
      Offset(size.width, size.height),
    );

    for (
      int meter = topLeft.x.ceil();
      meter <= bottomRight.x.floor();
      meter++
    ) {
      final double x = viewport.toCanvas(Point2D(meter.toDouble(), 0)).dx;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (
      int meter = topLeft.y.ceil();
      meter <= bottomRight.y.floor();
      meter++
    ) {
      final double y = viewport.toCanvas(Point2D(0, meter.toDouble())).dy;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset center, Color color) {
    final TextPainter textPainter = TextPainter(
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

    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant PlanPainter oldDelegate) {
    return oldDelegate.plan != plan ||
        oldDelegate.viewport != viewport ||
        oldDelegate.selectedWall != selectedWall ||
        oldDelegate.draggedVertex != draggedVertex ||
        oldDelegate.showHandles != showHandles;
  }
}
