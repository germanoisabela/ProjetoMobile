import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartfloor/app.dart';

void main() {
  void useTallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> openHome(WidgetTester tester) async {
    await tester.tap(find.text('Começar agora'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'rebeca@email.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
  }

  testWidgets('login oferece acesso e cadastro', (
    WidgetTester tester,
  ) async {
    useTallScreen(tester);
    await tester.pumpWidget(const SmartFloorApp());

    await tester.tap(find.text('Começar agora'));
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo de volta!'), findsOneWidget);
    expect(find.text('Digite seu e-mail'), findsOneWidget);
    expect(find.text('Digite sua senha'), findsOneWidget);
    expect(find.text('Continuar com Google'), findsOneWidget);
    expect(find.text('Cadastre-se'), findsOneWidget);
  });

  testWidgets('cadastre-se abre a tela de cadastro', (
    WidgetTester tester,
  ) async {
    useTallScreen(tester);
    await tester.pumpWidget(const SmartFloorApp());

    await tester.tap(find.text('Começar agora'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cadastre-se'));
    await tester.pumpAndSettle();

    expect(find.text('Faça o seu cadastro'), findsOneWidget);
    expect(find.text('Nome'), findsOneWidget);
    expect(find.text('Confirmar senha'), findsAtLeastNWidgets(1));
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('a tela inicial apresenta a proposta do SmartFloor', (
    WidgetTester tester,
  ) async {
    useTallScreen(tester);
    await tester.pumpWidget(const SmartFloorApp());

    expect(find.text('SmartFloor'), findsOneWidget);
    expect(find.text('Transforme espaços em novos planos.'), findsOneWidget);
    expect(find.text('Capturar ambiente'), findsOneWidget);
    expect(find.text('Imagem ou PDF'), findsOneWidget);
    expect(find.text('Plantas'), findsOneWidget);
    expect(find.text('Saiba mais'), findsOneWidget);
  });

  testWidgets('Saiba mais explica os recursos do aplicativo', (
    WidgetTester tester,
  ) async {
    useTallScreen(tester);
    await tester.pumpWidget(const SmartFloorApp());

    await tester.tap(find.text('Saiba mais'));
    await tester.pumpAndSettle();

    expect(find.text('Planeje seu espaço'), findsOneWidget);
    expect(find.text('Entendi'), findsOneWidget);
  });

  testWidgets('Home mostra saudação, atalho de captura e projetos', (
    WidgetTester tester,
  ) async {
    useTallScreen(tester);
    await tester.pumpWidget(const SmartFloorApp());
    await openHome(tester);

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
    await openHome(tester);

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
    await openHome(tester);

    await tester.tap(find.text('Capturar novo ambiente'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('AR / LiDAR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Escaneamento AR / LiDAR: em breve!'), findsOneWidget);
  });
}
