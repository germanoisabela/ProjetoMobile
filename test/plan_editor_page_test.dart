import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfloor/features/plan/domain/entities/plan.dart';
import 'package:smartfloor/features/plan/domain/entities/point_2d.dart';
import 'package:smartfloor/features/plan/presentation/pages/plan_editor_page.dart';
import 'package:smartfloor/features/plan/presentation/widgets/plan_painter.dart';
import 'package:smartfloor/features/home/data/repositories/mock_project_repository.dart';

void main() {
  testWidgets('shows plan metrics, drawing, and editor tools', (tester) async {
    final plan = Plan.fromRectangle(name: 'Sala', widthM: 3.5, lengthM: 2);

    await tester.pumpWidget(MaterialApp(home: PlanEditorPage(plan: plan)));
    await tester.pumpAndSettle();

    expect(find.text('Sala'), findsOneWidget);
    expect(find.text('7,00 m²'), findsOneWidget);
    expect(find.text('11,00 m'), findsOneWidget);
    expect(find.text('Paredes'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Toque numa parede ou arraste os cantos'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is PlanPainter,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Medir'));
    await tester.pumpAndSettle();
    expect(find.text('Toque no primeiro ponto da medição'), findsOneWidget);
  });

  testWidgets('saves the plan as a project and returns to Home',
      (tester) async {
    final repository = MockProjectRepository();
    final plan = Plan.fromRectangle(name: 'Sala', widthM: 3, lengthM: 2);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PlanEditorPage(
                      plan: plan,
                      projectRepository: repository,
                    ),
                  ),
                );
              },
              child: const Text('Abrir projeto'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir projeto'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Salvar projeto'));
    await tester.pumpAndSettle();

    expect(find.text('Abrir projeto'), findsOneWidget);
    final projects = await repository.getProjects();
    expect(projects, hasLength(1));
    expect(projects.single.name, 'Sala');
    expect(projects.single.areaM2, 6);
  });

  testWidgets('selects a wall and updates its length', (tester) async {
    final plan = Plan.fromRectangle(name: 'Sala', widthM: 3.5, lengthM: 2);

    await tester.pumpWidget(MaterialApp(home: PlanEditorPage(plan: plan)));
    await tester.pumpAndSettle();

    final Finder paintFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is PlanPainter,
    );
    final CustomPaint paint = tester.widget(paintFinder);
    final PlanPainter painter = paint.painter! as PlanPainter;
    final Offset wallCenter = painter.viewport.toCanvas(const Point2D(1.75, 0));
    final Offset globalWallCenter = tester.getTopLeft(paintFinder) + wallCenter;

    await tester.tapAt(globalWallCenter);
    await tester.pumpAndSettle();

    expect(find.text('Parede 1 • 3,50 m'), findsOneWidget);
    await tester.tap(find.text('Editar medida'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), '4,5');
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();

    expect(find.text('Parede 1 • 4,50 m'), findsOneWidget);
    expect(find.text('8,00 m²'), findsOneWidget);

    await tester.tap(find.byTooltip('Restaurar medidas originais'));
    await tester.pumpAndSettle();
    expect(find.text('7,00 m²'), findsOneWidget);

    final CustomPaint restoredPaint = tester.widget(paintFinder);
    final PlanPainter restoredPainter = restoredPaint.painter! as PlanPainter;
    final Offset corner = restoredPainter.viewport.toCanvas(
      const Point2D(0, 0),
    );
    final Offset globalCorner = tester.getTopLeft(paintFinder) + corner;
    final double dragDistance = restoredPainter.viewport.scale * 0.5;

    await tester.dragFrom(globalCorner, Offset(dragDistance, dragDistance));
    await tester.pumpAndSettle();

    expect(find.text('5,63 m²'), findsOneWidget);
    await tester.tap(find.byTooltip('Desfazer'));
    await tester.pumpAndSettle();
    expect(find.text('7,00 m²'), findsOneWidget);
    await tester.tap(find.byTooltip('Desfazer'));
    await tester.pumpAndSettle();
    expect(find.text('8,00 m²'), findsOneWidget);
  });

  testWidgets('measures between exact vertices and can start a new measure', (
    tester,
  ) async {
    final Plan plan = Plan.rectangle(name: 'Sala', widthM: 5, lengthM: 10);
    await tester.pumpWidget(MaterialApp(home: PlanEditorPage(plan: plan)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medir'));
    await tester.pumpAndSettle();

    final Finder paintFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is PlanPainter,
    );
    final PlanPainter painter =
        tester.widget<CustomPaint>(paintFinder).painter! as PlanPainter;
    final Offset canvasOrigin = tester.getTopLeft(paintFinder);
    await tester.tapAt(
      canvasOrigin + painter.viewport.toCanvas(const Point2D(0, 0)),
    );
    await tester.pump();
    await tester.tapAt(
      canvasOrigin + painter.viewport.toCanvas(const Point2D(5, 10)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Distância: 11,18 m'), findsOneWidget);
    expect(
      find.text('Horizontal 5,00 m  |  Vertical 10,00 m'),
      findsOneWidget,
    );
    final PlanPainter measuredPainter =
        tester.widget<CustomPaint>(paintFinder).painter! as PlanPainter;
    expect(measuredPainter.measureStart!.x, 0);
    expect(measuredPainter.measureStart!.y, 0);
    expect(measuredPainter.measureEnd!.x, 5);
    expect(measuredPainter.measureEnd!.y, 10);

    await tester.tap(find.byTooltip('Nova medição'));
    await tester.pumpAndSettle();
    expect(find.text('Toque no primeiro ponto da medição'), findsOneWidget);

    await tester.tapAt(
      canvasOrigin + painter.viewport.toCanvas(const Point2D(1.23, 1.37)),
    );
    await tester.pump();
    await tester.tapAt(
      canvasOrigin + painter.viewport.toCanvas(const Point2D(4.11, 4.24)),
    );
    await tester.pumpAndSettle();
    final PlanPainter snappedPainter =
        tester.widget<CustomPaint>(paintFinder).painter! as PlanPainter;
    expect(snappedPainter.measureStart!.x, closeTo(1.25, 1e-9));
    expect(snappedPainter.measureStart!.y, closeTo(1.35, 1e-9));
    expect(snappedPainter.measureEnd!.x, closeTo(4.1, 1e-9));
    expect(snappedPainter.measureEnd!.y, closeTo(4.25, 1e-9));
  });

  testWidgets('draws, removes, and undoes vertices', (tester) async {
    final Plan plan = Plan.rectangle(name: 'Sala', widthM: 4, lengthM: 3);
    await tester.pumpWidget(MaterialApp(home: PlanEditorPage(plan: plan)));
    await tester.pumpAndSettle();

    final Finder paintFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is PlanPainter,
    );
    PlanPainter painter =
        tester.widget<CustomPaint>(paintFinder).painter! as PlanPainter;
    Offset canvasOrigin = tester.getTopLeft(paintFinder);
    final Offset wallCenter =
        canvasOrigin + painter.viewport.toCanvas(const Point2D(2, 0));

    await tester.tap(find.text('Desenhar'));
    await tester.pumpAndSettle();
    await tester.tapAt(wallCenter);
    await tester.pumpAndSettle();

    painter = tester.widget<CustomPaint>(paintFinder).painter! as PlanPainter;
    expect(painter.plan.vertices, hasLength(5));
    expect(painter.plan.areaM2, closeTo(12, 1e-9));
    expect(painter.plan.perimeterM, closeTo(14, 1e-9));
    expect(find.byTooltip('Desfazer'), findsOneWidget);

    final Offset insertedVertex =
        canvasOrigin + painter.viewport.toCanvas(painter.plan.vertices[1]);
    await tester.tapAt(insertedVertex);
    await tester.pumpAndSettle();
    painter = tester.widget<CustomPaint>(paintFinder).painter! as PlanPainter;
    expect(painter.plan.vertices, hasLength(4));

    await tester.tap(find.byTooltip('Desfazer'));
    await tester.pumpAndSettle();
    painter = tester.widget<CustomPaint>(paintFinder).painter! as PlanPainter;
    expect(painter.plan.vertices, hasLength(5));

    await tester.tap(find.byTooltip('Desfazer'));
    await tester.pumpAndSettle();
    painter = tester.widget<CustomPaint>(paintFinder).painter! as PlanPainter;
    expect(painter.plan.vertices, hasLength(4));
  });

  testWidgets('drawing mode keeps at least three vertices', (tester) async {
    final Plan plan = Plan.rectangle(name: 'Sala', widthM: 4, lengthM: 3);
    await tester.pumpWidget(MaterialApp(home: PlanEditorPage(plan: plan)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desenhar'));
    await tester.pumpAndSettle();

    final Finder paintFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is PlanPainter,
    );
    PlanPainter painter =
        tester.widget<CustomPaint>(paintFinder).painter! as PlanPainter;
    final Offset canvasOrigin = tester.getTopLeft(paintFinder);
    final Offset wallCenter =
        canvasOrigin + painter.viewport.toCanvas(const Point2D(2, 0));
    await tester.tapAt(wallCenter);
    await tester.pumpAndSettle();

    painter = tester.widget<CustomPaint>(paintFinder).painter! as PlanPainter;
    for (final Point2D vertex
        in List<Point2D>.of(painter.plan.vertices).take(2)) {
      await tester.tapAt(
        canvasOrigin + painter.viewport.toCanvas(vertex),
      );
      await tester.pumpAndSettle();
      painter = tester.widget<CustomPaint>(paintFinder).painter! as PlanPainter;
    }

    expect(painter.plan.vertices, hasLength(3));
    await tester.tapAt(
      canvasOrigin + painter.viewport.toCanvas(painter.plan.vertices.first),
    );
    await tester.pumpAndSettle();
    expect(find.text('Uma planta precisa de pelo menos 3 cantos.'),
        findsOneWidget);
    expect(
      (tester.widget<CustomPaint>(paintFinder).painter! as PlanPainter)
          .plan
          .vertices,
      hasLength(3),
    );
  });
}
