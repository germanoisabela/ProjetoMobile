import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/floor_plan.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/point_2d.dart';
import 'plan_underlay.dart';
import 'plan_viewport.dart';

/// Desenha a imagem de referência, o terreno, cômodos, cotas e ferramentas.
class FloorPlanPainter extends CustomPainter {
  final FloorPlan plan;
  final PlanViewport viewport;
  final PlanUnderlay? underlay;
  final int? selectedRoom;
  final int? selectedWall;
  final Point2D? draggedPoint;
  final List<Point2D> draft;
  final bool draftIsLot;
  final Point2D? measureStart;
  final Point2D? measureEnd;
  final Point2D? calibrateStart;
  final Point2D? calibrateEnd;
  final bool showHandles;
  final bool showAllDimensions;

  const FloorPlanPainter({
    required this.plan,
    required this.viewport,
    this.underlay,
    this.selectedRoom,
    this.selectedWall,
    this.draggedPoint,
    this.draft = const [],
    this.draftIsLot = false,
    this.measureStart,
    this.measureEnd,
    this.calibrateStart,
    this.calibrateEnd,
    this.showHandles = true,
    this.showAllDimensions = false,
  });

  static const Color _selectedColor = Color(0xFFF9A825);
  static const Color _measureColor = Color(0xFF1565C0);
  static const Color _calibrateColor = Color(0xFFD81B60);
  static const Color _lotColor = Color(0xFF8D6E63);
  static const List<Color> _roomColors = [
    Color(0xFFA5D6A7),
    Color(0xFFFFCC80),
    Color(0xFF90CAF9),
    Color(0xFFF48FB1),
    Color(0xFFCE93D8),
    Color(0xFFFFF59D),
    Color(0xFF80CBC4),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _drawUnderlay(canvas);
    if (underlay == null) _drawGrid(canvas, size);
    _drawLot(canvas);
    _drawRooms(canvas);
    _drawDraft(canvas);
    _drawTwoPointLine(
      canvas,
      calibrateStart,
      calibrateEnd,
      _calibrateColor,
      withLabel: false,
    );
    _drawTwoPointLine(
      canvas,
      measureStart,
      measureEnd,
      _measureColor,
      withLabel: true,
    );
    if (showHandles) _drawHandles(canvas);
  }

  void _drawUnderlay(Canvas canvas) {
    final PlanUnderlay? image = underlay;
    if (image == null) return;
    final Offset topLeft = viewport.toCanvas(image.origin);
    canvas.drawImageRect(
      image.image,
      Rect.fromLTWH(
        0,
        0,
        image.image.width.toDouble(),
        image.image.height.toDouble(),
      ),
      Rect.fromLTWH(
        topLeft.dx,
        topLeft.dy,
        image.widthM * viewport.scale,
        image.heightM * viewport.scale,
      ),
      Paint()
        ..filterQuality = FilterQuality.medium
        ..colorFilter = const ColorFilter.mode(
          Color(0xCCFFFFFF),
          BlendMode.modulate,
        ),
    );
  }

  void _drawGrid(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFB7D3BA)
      ..strokeWidth = 1;
    final Point2D topLeft = viewport.toMeters(Offset.zero);
    final Point2D bottomRight =
        viewport.toMeters(Offset(size.width, size.height));
    for (int meter = topLeft.x.ceil();
        meter <= bottomRight.x.floor();
        meter++) {
      final double x = viewport.toCanvas(Point2D(meter.toDouble(), 0)).dx;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (int meter = topLeft.y.ceil();
        meter <= bottomRight.y.floor();
        meter++) {
      final double y = viewport.toCanvas(Point2D(0, meter.toDouble())).dy;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawLot(Canvas canvas) {
    final Plan? lot = plan.lot;
    if (lot == null || lot.vertices.length < 3) return;
    final Path path = _pathOf(lot);
    canvas.drawPath(path, Paint()..color = const Color(0x168D6E63));
    canvas.drawPath(
      path,
      Paint()
        ..color = _lotColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawRooms(Canvas canvas) {
    for (int roomIndex = 0; roomIndex < plan.rooms.length; roomIndex++) {
      final bool selected = roomIndex == selectedRoom;
      canvas.drawPath(
        _pathOf(plan.rooms[roomIndex]),
        Paint()
          ..color = _roomColors[roomIndex % _roomColors.length]
              .withAlpha(selected ? 200 : 140),
      );
    }

    for (int roomIndex = 0; roomIndex < plan.rooms.length; roomIndex++) {
      final Plan room = plan.rooms[roomIndex];
      final List<Offset> points = room.vertices.map(viewport.toCanvas).toList();
      for (int wallIndex = 0; wallIndex < points.length; wallIndex++) {
        final bool selected =
            roomIndex == selectedRoom && wallIndex == selectedWall;
        canvas.drawLine(
          points[wallIndex],
          points[(wallIndex + 1) % points.length],
          Paint()
            ..color = selected ? _selectedColor : AppColors.primary
            ..strokeWidth = selected ? 9 : (roomIndex == selectedRoom ? 7 : 5)
            ..strokeCap = StrokeCap.round,
        );
      }
      _drawRoomLabel(canvas, room);
      if (showAllDimensions || roomIndex == selectedRoom) {
        _drawDimensions(canvas, room, roomIndex == selectedRoom);
      }
    }
  }

  void _drawRoomLabel(Canvas canvas, Plan room) {
    final TextPainter label = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${room.name}\n',
            style: const TextStyle(
              color: Color(0xFF1B1B1B),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: '${formatDecimal(room.areaM2)} m²',
            style: const TextStyle(color: Color(0xFF424242), fontSize: 11),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    _paintText(canvas, label, viewport.toCanvas(room.centroid));
  }

  void _drawDimensions(Canvas canvas, Plan room, bool isSelected) {
    final List<Offset> points = room.vertices.map(viewport.toCanvas).toList();
    final Offset center = viewport.toCanvas(room.centroid);
    for (int index = 0; index < room.walls.length; index++) {
      final Offset middle =
          (points[index] + points[(index + 1) % points.length]) / 2;
      final Offset outward = middle - center;
      if (outward.distance == 0) continue;
      final Offset direction = outward / outward.distance;
      final bool selected = isSelected && index == selectedWall;
      final TextPainter label = _layoutText(
        '${formatDecimal(room.walls[index].lengthM)} m',
        selected ? _selectedColor : const Color(0xFF263238),
        fontSize: 11.5,
      );
      final double halfExtent = direction.dx.abs() * label.width / 2 +
          direction.dy.abs() * label.height / 2;
      _paintText(
        canvas,
        label,
        middle + direction * (12 + halfExtent),
        withBackground: true,
      );
    }
  }

  void _drawDraft(Canvas canvas) {
    if (draft.isEmpty) return;
    final Color color = draftIsLot ? _lotColor : AppColors.primary;
    final List<Offset> points = draft.map(viewport.toCanvas).toList();
    final Paint line = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (int index = 0; index < points.length - 1; index++) {
      canvas.drawLine(points[index], points[index + 1], line);
    }
    for (final Offset point in points) {
      canvas.drawCircle(point, 5, Paint()..color = color);
    }
    if (points.length >= 3) {
      canvas.drawCircle(
        points.first,
        12,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawTwoPointLine(
    Canvas canvas,
    Point2D? start,
    Point2D? end,
    Color color, {
    required bool withLabel,
  }) {
    if (start == null) return;
    final Offset a = viewport.toCanvas(start);
    final Paint marker = Paint()..color = color;
    if (end != null) {
      final Offset b = viewport.toCanvas(end);
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(b, 6, marker);
      if (withLabel) {
        final TextPainter label = _layoutText(
          '${formatDecimal(start.distanceTo(end))} m',
          color,
        );
        _paintText(
          canvas,
          label,
          (a + b) / 2 + const Offset(0, -18),
          withBackground: true,
        );
      }
    }
    canvas.drawCircle(a, 6, marker);
  }

  void _drawHandles(Canvas canvas) {
    final Plan? lot = plan.lot;
    if (lot != null) {
      for (final Point2D vertex in lot.vertices) {
        _drawHandle(canvas, viewport.toCanvas(vertex), _lotColor, 6);
      }
    }
    for (final Plan room in plan.rooms) {
      for (final Point2D vertex in room.vertices) {
        _drawHandle(canvas, viewport.toCanvas(vertex), AppColors.primary, 7);
      }
    }
    final Point2D? dragged = draggedPoint;
    if (dragged != null) {
      _drawHandle(canvas, viewport.toCanvas(dragged), _selectedColor, 12);
    }
  }

  void _drawHandle(Canvas canvas, Offset center, Color color, double radius) {
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  Path _pathOf(Plan polygon) => Path()
    ..addPolygon(polygon.vertices.map(viewport.toCanvas).toList(), true);

  TextPainter _layoutText(String text, Color color, {double fontSize = 13}) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
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
          (topLeft & textPainter.size).inflate(2),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xCCFFFFFF),
      );
    }
    textPainter.paint(canvas, topLeft);
  }

  @override
  bool shouldRepaint(covariant FloorPlanPainter oldDelegate) => true;
}
