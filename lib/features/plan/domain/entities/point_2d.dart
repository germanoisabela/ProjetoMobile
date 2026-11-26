import 'dart:math' as math;

/// Um ponto no plano 2D, com coordenadas em metros.
class Point2D {
  final double x;
  final double y;

  const Point2D(this.x, this.y);

  /// Arredonda as coordenadas para o múltiplo mais próximo de [stepM].
  Point2D snapTo(double stepM) {
    if (!stepM.isFinite || stepM <= 0) {
      throw ArgumentError.value(stepM, 'stepM', 'Deve ser maior que zero.');
    }

    return Point2D((x / stepM).round() * stepM, (y / stepM).round() * stepM);
  }

  /// Distância em linha reta até [other], em metros.
  double distanceTo(Point2D other) {
    final double dx = other.x - x;
    final double dy = other.y - y;
    return math.sqrt(dx * dx + dy * dy);
  }
}
