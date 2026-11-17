import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:smartfloor/features/plan/domain/entities/plan.dart';
import 'package:smartfloor/features/plan/domain/entities/point_2d.dart';

void main() {
  final Plan plan = Plan.rectangle(name: 'Teste', widthM: 4, lengthM: 3);

  test('retângulo 4x3 tem área 12, perímetro 14 e 4 paredes', () {
    expect(plan.areaM2, closeTo(12, 1e-9));
    expect(plan.perimeterM, closeTo(14, 1e-9));
    expect(plan.walls.length, 4);
  });

  test('retângulo envolvente tem 4 m de largura e 3 m de altura', () {
    expect(plan.boundingWidthM, closeTo(4, 1e-9));
    expect(plan.boundingHeightM, closeTo(3, 1e-9));
  });

  test('triângulo 3-4-5 tem área 6 e perímetro 12', () {
    final Plan triangle = Plan(
      name: 'Triângulo',
      vertices: [const Point2D(0, 0), const Point2D(4, 0), const Point2D(0, 3)],
    );

    expect(triangle.areaM2, closeTo(6, 1e-9));
    expect(triangle.perimeterM, closeTo(12, 1e-9));
  });

  test('moveVertex devolve uma planta nova e não altera a original', () {
    final Plan moved = plan.moveVertex(1, const Point2D(5, 0));

    expect(plan.vertices[1].x, 4);
    expect(moved.vertices[1].x, 5);
    expect(moved.areaM2, closeTo(13.5, 1e-9));
  });

  test('withWallLength estica a parede 0 para 5 m', () {
    final Plan changed = plan.withWallLength(0, 5);

    expect(changed.walls[0].lengthM, closeTo(5, 1e-9));
    expect(changed.areaM2, closeTo(13.5, 1e-9));
    expect(changed.walls[1].lengthM, closeTo(math.sqrt(10), 1e-9));
  });

  test('withWallLength ignora medidas inválidas', () {
    expect(identical(plan.withWallLength(0, 0), plan), isTrue);
    expect(identical(plan.withWallLength(0, -2), plan), isTrue);
  });

  test('snapTo arredonda para múltiplos de 5 cm', () {
    final Point2D snapped = const Point2D(1.23, 2.38).snapTo(0.05);

    expect(snapped.x, closeTo(1.25, 1e-9));
    expect(snapped.y, closeTo(2.40, 1e-9));
  });
}
