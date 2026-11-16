import 'dart:math' as math;

import 'point_2d.dart';

/// Uma parede representada pelo segmento entre dois pontos.
class Wall {
  final Point2D start;
  final Point2D end;

  const Wall({required this.start, required this.end});

  /// Comprimento da parede em metros.
  double get lengthM {
    final double dx = end.x - start.x;
    final double dy = end.y - start.y;
    return math.sqrt(dx * dx + dy * dy);
  }
}
