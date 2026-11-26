import 'point_2d.dart';
import 'wall.dart';

/// Planta baixa de um ambiente, com vértices ordenados ao longo do contorno.
class Plan {
  final String name;
  final List<Point2D> vertices;

  Plan({required this.name, required List<Point2D> vertices})
      : vertices = List.unmodifiable(vertices);

  /// Atalho para criar uma planta retangular.
  factory Plan.rectangle({
    required String name,
    required double widthM,
    required double lengthM,
  }) {
    return Plan(
      name: name,
      vertices: [
        const Point2D(0, 0),
        Point2D(widthM, 0),
        Point2D(widthM, lengthM),
        Point2D(0, lengthM),
      ],
    );
  }

  /// Compatibilidade com os fluxos que já usam este nome.
  factory Plan.fromRectangle({
    required String name,
    required double widthM,
    required double lengthM,
  }) =>
      Plan.rectangle(name: name, widthM: widthM, lengthM: lengthM);

  Plan copyWith({String? name, List<Point2D>? vertices}) {
    return Plan(name: name ?? this.name, vertices: vertices ?? this.vertices);
  }

  Plan moveVertex(int index, Point2D to) {
    final List<Point2D> updated = List.of(vertices);
    updated[index] = to;
    return copyWith(vertices: updated);
  }

  Plan withWallLength(int wallIndex, double newLengthM) {
    final Wall wall = walls[wallIndex];
    final double currentLength = wall.lengthM;
    if (currentLength == 0 || !newLengthM.isFinite || newLengthM <= 0) {
      return this;
    }

    final double factor = newLengthM / currentLength;
    final Point2D newEnd = Point2D(
      wall.start.x + (wall.end.x - wall.start.x) * factor,
      wall.start.y + (wall.end.y - wall.start.y) * factor,
    );

    return moveVertex((wallIndex + 1) % vertices.length, newEnd);
  }

  /// Insere um vértice após o início da parede indicada.
  Plan insertVertexOnWall(int wallIndex, Point2D point) {
    if (wallIndex < 0 || wallIndex >= vertices.length) {
      throw RangeError.index(wallIndex, walls, 'wallIndex');
    }

    final List<Point2D> updated = [
      ...vertices.sublist(0, wallIndex + 1),
      point,
      ...vertices.sublist(wallIndex + 1),
    ];
    return copyWith(vertices: updated);
  }

  /// Remove um vértice, preservando o mínimo de três pontos da planta.
  Plan removeVertex(int index) {
    if (index < 0 || index >= vertices.length) {
      throw RangeError.index(index, vertices, 'index');
    }
    if (vertices.length <= 3) return this;

    final List<Point2D> updated = List.of(vertices)..removeAt(index);
    return copyWith(vertices: updated);
  }

  /// Retorna se [point] está dentro deste polígono.
  bool containsPoint(Point2D point) {
    if (vertices.length < 3) return false;
    bool inside = false;
    for (int i = 0, j = vertices.length - 1; i < vertices.length; j = i++) {
      final Point2D a = vertices[i];
      final Point2D b = vertices[j];
      final double cross =
          (point.x - a.x) * (b.y - a.y) - (point.y - a.y) * (b.x - a.x);
      final double dot =
          (point.x - a.x) * (point.x - b.x) + (point.y - a.y) * (point.y - b.y);
      if (cross.abs() <= 1e-8 && dot <= 1e-8) return true;
      final bool crosses = (a.y > point.y) != (b.y > point.y) &&
          point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x;
      if (crosses) inside = !inside;
    }
    return inside;
  }

  /// Centro geométrico do polígono; usa a média dos vértices se a área for zero.
  Point2D get centroid {
    double twiceArea = 0;
    double cx = 0;
    double cy = 0;
    for (int i = 0; i < vertices.length; i++) {
      final Point2D a = vertices[i];
      final Point2D b = vertices[(i + 1) % vertices.length];
      final double cross = a.x * b.y - b.x * a.y;
      twiceArea += cross;
      cx += (a.x + b.x) * cross;
      cy += (a.y + b.y) * cross;
    }

    if (twiceArea.abs() < 1e-9) {
      final double x = vertices.fold(0.0, (sum, point) => sum + point.x);
      final double y = vertices.fold(0.0, (sum, point) => sum + point.y);
      return Point2D(x / vertices.length, y / vertices.length);
    }
    return Point2D(cx / (3 * twiceArea), cy / (3 * twiceArea));
  }

  /// Paredes que ligam cada vértice ao seguinte, fechando o contorno.
  List<Wall> get walls {
    return [
      for (int i = 0; i < vertices.length; i++)
        Wall(start: vertices[i], end: vertices[(i + 1) % vertices.length]),
    ];
  }

  /// Área em metros quadrados, calculada pela fórmula do cadarço.
  double get areaM2 {
    double sum = 0;
    for (int i = 0; i < vertices.length; i++) {
      final Point2D current = vertices[i];
      final Point2D next = vertices[(i + 1) % vertices.length];
      sum += current.x * next.y - next.x * current.y;
    }
    return sum.abs() / 2;
  }

  /// Perímetro em metros, somando os comprimentos das paredes.
  double get perimeterM {
    return walls.fold(0, (total, wall) => total + wall.lengthM);
  }

  // ---------- Retângulo envolvente (menor retângulo que contém a planta) ----------
  double get minX => vertices.map((v) => v.x).reduce((a, b) => a < b ? a : b);
  double get maxX => vertices.map((v) => v.x).reduce((a, b) => a > b ? a : b);
  double get minY => vertices.map((v) => v.y).reduce((a, b) => a < b ? a : b);
  double get maxY => vertices.map((v) => v.y).reduce((a, b) => a > b ? a : b);

  /// Largura e altura totais ocupadas pela planta, em metros.
  double get boundingWidthM => maxX - minX;
  double get boundingHeightM => maxY - minY;
}
