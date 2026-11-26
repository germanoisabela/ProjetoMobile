import 'package:flutter_test/flutter_test.dart';
import 'package:smartfloor/features/plan/domain/entities/floor_plan.dart';
import 'package:smartfloor/features/plan/domain/entities/plan.dart';
import 'package:smartfloor/features/plan/domain/entities/point_2d.dart';
import 'package:smartfloor/features/rules/domain/entities/floor_plan_site_analysis.dart';

void main() {
  group('FloorPlan', () {
    test('sums the area of all rooms', () {
      final FloorPlan floorPlan = FloorPlan(
        name: 'Casa',
        rooms: [
          Plan.rectangle(name: 'Sala', widthM: 4, lengthM: 3),
          Plan(
            name: 'Quarto',
            vertices: const [
              Point2D(4, 0),
              Point2D(7, 0),
              Point2D(7, 3),
              Point2D(4, 3),
            ],
          ),
        ],
      );

      expect(floorPlan.builtAreaM2, 21);
      expect(floorPlan.buildingBoundingBox()!.areaM2, 21);
    });

    test('moves matching room vertices together', () {
      final FloorPlan floorPlan = FloorPlan(
        name: 'Casa',
        rooms: [
          Plan(
            name: 'Sala',
            vertices: const [
              Point2D(0, 0),
              Point2D(3, 0),
              Point2D(3, 3),
              Point2D(0, 3),
            ],
          ),
          Plan(
            name: 'Quarto',
            vertices: const [
              Point2D(3, 0),
              Point2D(6, 0),
              Point2D(6, 3),
              Point2D(3, 3),
            ],
          ),
        ],
      );

      final List<VertexRef> matching =
          floorPlan.roomVerticesAt(const Point2D(3, 0));
      final FloorPlan moved =
          floorPlan.moveVertices(matching, const Point2D(3.5, 0));

      expect(moved.rooms[0].vertices[1].x, 3.5);
      expect(moved.rooms[1].vertices[0].x, 3.5);
    });

    test('resizes a wall while preserving shared corners', () {
      final FloorPlan floorPlan = FloorPlan(
        name: 'Casa',
        rooms: [
          Plan(
            name: 'Sala',
            vertices: const [
              Point2D(0, 0),
              Point2D(3, 0),
              Point2D(3, 3),
              Point2D(0, 3),
            ],
          ),
          Plan(
            name: 'Quarto',
            vertices: const [
              Point2D(3, 0),
              Point2D(6, 0),
              Point2D(6, 3),
              Point2D(3, 3),
            ],
          ),
        ],
      );

      final FloorPlan resized = floorPlan.setRoomWallLength(0, 0, 4);

      expect(resized.rooms[0].vertices[1].x, 4);
      expect(resized.rooms[0].vertices[1].y, 0);
      expect(resized.rooms[1].vertices[0].x, 4);
      expect(resized.rooms[1].vertices[0].y, 0);
    });
  });

  test('adapts lot and building bounds to rectangular rule inputs', () {
    final FloorPlan floorPlan = FloorPlan(
      name: 'Casa',
      lot: Plan(
        name: 'Terreno',
        vertices: const [
          Point2D(-2, -1),
          Point2D(18, -1),
          Point2D(18, 19),
          Point2D(-2, 19),
        ],
      ),
      rooms: [
        Plan(
          name: 'Sala',
          vertices: const [
            Point2D(1, 3),
            Point2D(5, 3),
            Point2D(5, 8),
            Point2D(1, 8),
          ],
        ),
      ],
    );

    final FloorPlanSiteAnalysis analysis =
        FloorPlanSiteAnalysis.fromFloorPlan(floorPlan);

    expect(analysis.site.widthM, 20);
    expect(analysis.site.lengthM, 20);
    expect(analysis.site.leftSetbackM, 3);
    expect(analysis.site.frontSetbackM, 11);
    expect(analysis.building.boundingWidthM, 4);
    expect(analysis.building.boundingHeightM, 5);
  });

  test('contains points on polygon edges and rejects degenerate polygons', () {
    final Plan rectangle = Plan.rectangle(
      name: 'Terreno',
      widthM: 5,
      lengthM: 4,
    );

    expect(rectangle.containsPoint(const Point2D(0, 2)), isTrue);
    expect(rectangle.containsPoint(const Point2D(2, 2)), isTrue);
    expect(rectangle.containsPoint(const Point2D(6, 2)), isFalse);
    expect(
      Plan(name: 'Vazio', vertices: const []).containsPoint(
        const Point2D(0, 0),
      ),
      isFalse,
    );
  });
}
