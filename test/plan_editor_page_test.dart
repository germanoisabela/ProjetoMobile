import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfloor/features/plan/domain/entities/plan.dart';
import 'package:smartfloor/features/plan/domain/entities/point_2d.dart';
import 'package:smartfloor/features/plan/presentation/pages/plan_editor_page.dart';
import 'package:smartfloor/features/plan/presentation/widgets/plan_painter.dart';

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
    await tester.pump();
    expect(find.text('Medir: em breve!'), findsOneWidget);
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
  });
}
