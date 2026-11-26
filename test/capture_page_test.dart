import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfloor/features/capture/domain/entities/capture_mode.dart';
import 'package:smartfloor/features/capture/domain/entities/captured_input.dart';
import 'package:smartfloor/features/capture/domain/repositories/capture_repository.dart';
import 'package:smartfloor/features/capture/presentation/pages/capture_page.dart';
import 'package:smartfloor/features/plan/presentation/pages/floor_plan_editor_page.dart';

class FakeCaptureRepository implements CaptureRepository {
  final CapturedInput? input;
  CaptureMode? requestedMode;

  FakeCaptureRepository(this.input);

  @override
  Future<CapturedInput?> pickFromCamera() async {
    requestedMode = CaptureMode.camera;
    return input;
  }

  @override
  Future<CapturedInput?> pickImageOrPdf() async {
    requestedMode = CaptureMode.imageOrPdf;
    return input;
  }
}

void main() {
  testWidgets('importing a PDF opens its preview', (tester) async {
    const input = CapturedInput(
      path: 'C:/planta.pdf',
      name: 'planta.pdf',
      mode: CaptureMode.imageOrPdf,
    );
    final repository = FakeCaptureRepository(input);

    await tester.pumpWidget(
      MaterialApp(home: CapturePage(repository: repository)),
    );
    await tester.tap(find.text('Imagem ou PDF'));
    await tester.pumpAndSettle();

    expect(repository.requestedMode, CaptureMode.imageOrPdf);
    expect(find.text('Confira o arquivo'), findsOneWidget);
    expect(find.text('planta.pdf'), findsOneWidget);
    expect(find.text('Planta em PDF'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.byType(FloorPlanEditorPage), findsOneWidget);
  });

  testWidgets('canceling a capture stays on the selection page', (
    tester,
  ) async {
    final repository = FakeCaptureRepository(null);

    await tester.pumpWidget(
      MaterialApp(home: CapturePage(repository: repository)),
    );
    await tester.tap(find.text('Câmera'));
    await tester.pumpAndSettle();

    expect(repository.requestedMode, CaptureMode.camera);
    expect(find.text('Confira o arquivo'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
