import 'point_2d.dart';

/// Uma parede representada pelo segmento entre dois pontos.
class Wall {
  final Point2D start;
  final Point2D end;

  const Wall({required this.start, required this.end});

  /// Comprimento da parede em metros.
  double get lengthM => start.distanceTo(end);

  /// Ponto do segmento mais próximo de [point].
  Point2D closestPointTo(Point2D point) {
    final double dx = end.x - start.x;
    final double dy = end.y - start.y;
    final double lengthSquared = dx * dx + dy * dy;
    if (lengthSquared == 0) return start;

    final double t =
        (((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared)
            .clamp(0.0, 1.0)
            .toDouble();
    return Point2D(start.x + dx * t, start.y + dy * t);
  }

  /// Ponto a [distanceM] metros do início do segmento.
  Point2D pointAtDistance(double distanceM) {
    final double length = lengthM;
    if (length == 0) return start;

    final double ratio = distanceM / length;
    return Point2D(
      start.x + (end.x - start.x) * ratio,
      start.y + (end.y - start.y) * ratio,
    );
  }
}
