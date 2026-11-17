import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfloor/app.dart';

void main() {
  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('Home mostra saudação, atalho de captura e projetos', (
    WidgetTester tester,
  ) async {
    useTallScreen(tester);
    await tester.pumpWidget(const SmartFloorApp());

    expect(find.text('Olá, Rebeca!'), findsOneWidget);
    expect(find.text('Capturar novo ambiente'), findsOneWidget);
    expect(find.text('Casa da família'), findsOneWidget);
    expect(find.text('Apartamento'), findsOneWidget);
    expect(find.text('Escritório'), findsOneWidget);
  });

  testWidgets('tocar no atalho abre a tela de captura com as 3 opções', (
    WidgetTester tester,
  ) async {
    useTallScreen(tester);
    await tester.pumpWidget(const SmartFloorApp());

    await tester.tap(find.text('Capturar novo ambiente'));
    await tester.pumpAndSettle();

    expect(find.text('Etapa 1 de 4'), findsOneWidget);
    expect(find.text('Como você quer capturar seu ambiente?'), findsOneWidget);
    expect(find.text('Câmera'), findsOneWidget);
    expect(find.text('Imagem ou PDF'), findsOneWidget);
    expect(find.text('AR / LiDAR'), findsOneWidget);
  });

  testWidgets('a opção AR / LiDAR avisa que ainda não está disponível', (
    WidgetTester tester,
  ) async {
    useTallScreen(tester);
    await tester.pumpWidget(const SmartFloorApp());

    await tester.tap(find.text('Capturar novo ambiente'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('AR / LiDAR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Escaneamento AR / LiDAR: em breve!'), findsOneWidget);
  });
}
