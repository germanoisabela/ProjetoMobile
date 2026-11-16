import 'package:flutter_test/flutter_test.dart';
import 'package:smartfloor/features/plan/domain/entities/point_2d.dart';
import 'package:smartfloor/features/plan/domain/entities/plan.dart';

void main() {
  group('Plan.fromRectangle', () {
    final plan = Plan.fromRectangle(name: 'Sala', widthM: 3.5, lengthM: 2);

    test('creates four corners and four walls', () {
      expect(plan.name, 'Sala');
      expect(plan.vertices, hasLength(4));
      expect(plan.walls, hasLength(4));
    });

    test('calculates area and perimeter in meters', () {
      expect(plan.areaM2, 7);
      expect(plan.perimeterM, 11);
    });
  });

  test('calculates area for a polygon regardless of winding direction', () {
    final plan = Plan(
      name: 'Triângulo',
      vertices: const [Point2D(0, 0), Point2D(4, 0), Point2D(0, 3)],
    );

    expect(plan.areaM2, 6);
  });

  test('snaps points to a measurement increment', () {
    final Point2D snapped = const Point2D(1.23, 2.26).snapTo(0.05);

    expect(snapped.x, closeTo(1.25, 1e-10));
    expect(snapped.y, closeTo(2.25, 1e-10));
  });

  test('creates new plans when moving vertices or changing wall lengths', () {
    final Plan original = Plan.rectangle(name: 'Sala', widthM: 3, lengthM: 2);
    final Plan moved = original.moveVertex(1, const Point2D(4, 0));

    expect(original.vertices[1].x, 3);
    expect(moved.vertices[1].x, 4);
    expect(original.walls[0].lengthM, 3);
    expect(moved.withWallLength(0, 5).walls[0].lengthM, 5);
  });

  test('keeps its vertex list immutable', () {
    final vertices = <Point2D>[const Point2D(0, 0)];
    final plan = Plan(name: 'Sala', vertices: vertices);
    vertices[0] = const Point2D(1, 1);

    expect(plan.vertices.single.x, 0);
    expect(plan.vertices.single.y, 0);
    expect(
      () => plan.vertices.add(const Point2D(2, 2)),
      throwsUnsupportedError,
    );
  });
}
