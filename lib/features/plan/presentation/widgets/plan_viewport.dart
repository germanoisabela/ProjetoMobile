import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../domain/entities/plan.dart';
import '../../domain/entities/point_2d.dart';

/// Converte coordenadas do modelo em metros para pixels na tela e vice-versa.
class PlanViewport {
  final double scale;
  final Offset origin;

  const PlanViewport({required this.scale, required this.origin});

  /// Calcula uma escala centralizada, deixando espaço para a planta crescer.
  factory PlanViewport.fit({
    required Plan plan,
    required Size canvasSize,
    double margin = 64,
    double growth = 1.4,
  }) {
    if (!growth.isFinite || growth <= 0) {
      throw ArgumentError.value(growth, 'growth', 'Deve ser maior que zero.');
    }

    if (plan.vertices.isEmpty) {
      return PlanViewport(
        scale: 1,
        origin: Offset(canvasSize.width / 2, canvasSize.height / 2),
      );
    }

    double minX = plan.vertices.first.x;
    double maxX = minX;
    double minY = plan.vertices.first.y;
    double maxY = minY;
    for (final Point2D vertex in plan.vertices) {
      minX = math.min(minX, vertex.x);
      maxX = math.max(maxX, vertex.x);
      minY = math.min(minY, vertex.y);
      maxY = math.max(maxY, vertex.y);
    }

    final double planWidth = math.max(maxX - minX, 0.1);
    final double planHeight = math.max(maxY - minY, 0.1);
    final double availableWidth = math.max(canvasSize.width - 2 * margin, 1);
    final double availableHeight = math.max(canvasSize.height - 2 * margin, 1);
    final double scale = math.min(
      availableWidth / (planWidth * growth),
      availableHeight / (planHeight * growth),
    );
    final double centerX = (minX + maxX) / 2;
    final double centerY = (minY + maxY) / 2;

    return PlanViewport(
      scale: scale,
      origin: Offset(
        canvasSize.width / 2 - centerX * scale,
        canvasSize.height / 2 - centerY * scale,
      ),
    );
  }

  Offset toCanvas(Point2D point) {
    return Offset(origin.dx + point.x * scale, origin.dy + point.y * scale);
  }

  Point2D toMeters(Offset point) {
    return Point2D(
      (point.dx - origin.dx) / scale,
      (point.dy - origin.dy) / scale,
    );
  }
}
