import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfloor/features/capture/domain/entities/capture_mode.dart';
import 'package:smartfloor/features/capture/domain/entities/captured_input.dart';
import 'package:smartfloor/features/capture/presentation/pages/capture_measures_page.dart';
import 'package:smartfloor/features/plan/presentation/pages/plan_editor_page.dart';

void main() {
  const input = CapturedInput(
    path: 'C:/planta.pdf',
    name: 'planta.pdf',
    mode: CaptureMode.imageOrPdf,
  );

  testWidgets('shows area estimate and opens the plan editor', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CaptureMeasuresPage(input: input)),
    );

    await tester.enterText(find.byType(TextFormField).at(1), '3,5');
    await tester.enterText(find.byType(TextFormField).at(2), '2');
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Área estimada: 7,00 m²'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Área estimada: 7,00 m²'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Continuar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.byType(PlanEditorPage), findsOneWidget);
    expect(find.text('Área'), findsOneWidget);
    expect(find.text('7,00 m²'), findsOneWidget);
    expect(find.text('11,00 m'), findsOneWidget);
    expect(find.text('Paredes'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('validates required fields and measure limits', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: CaptureMeasuresPage(input: input)),
    );

    await tester.scrollUntilVisible(
      find.text('Continuar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(find.text('Informe um número válido'), findsNWidgets(2));

    await tester.enterText(find.byType(TextFormField).at(1), '101');
    await tester.enterText(find.byType(TextFormField).at(2), '-1');
    await tester.scrollUntilVisible(
      find.text('Continuar'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Continuar'));
    await tester.pump();

    expect(find.text('Máximo de 100 m'), findsOneWidget);
    expect(find.text('Deve ser maior que zero'), findsOneWidget);
  });
}
