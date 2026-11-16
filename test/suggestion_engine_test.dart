import 'package:flutter_test/flutter_test.dart';
import 'package:smartfloor/features/plan/domain/entities/plan.dart';
import 'package:smartfloor/features/rules/domain/entities/building_alert.dart';
import 'package:smartfloor/features/rules/domain/entities/rule_settings.dart';
import 'package:smartfloor/features/rules/domain/entities/site.dart';
import 'package:smartfloor/features/rules/domain/services/building_rule_checker.dart';
import 'package:smartfloor/features/rules/domain/services/suggestion_engine.dart';

void main() {
  // Construção de 4 m x 3 m (12 m²).
  final Plan plan = Plan.rectangle(name: 'Teste', widthM: 4, lengthM: 3);
  const SuggestionEngine engine = SuggestionEngine();
  const BuildingRuleChecker checker = BuildingRuleChecker();
  const RuleSettings noSettings = RuleSettings();

  test('sem sugestões quando a posição já é válida', () {
    const site = Site(
      widthM: 10,
      lengthM: 20,
      frontSetbackM: 5,
      leftSetbackM: 3,
    );
    expect(engine.suggest(plan: plan, site: site, settings: noSettings), isEmpty);
  });

  test('sugere deslocar 0,5 m para a direita quando a esquerda tem 1 m', () {
    const site = Site(
      widthM: 10,
      lengthM: 20,
      frontSetbackM: 5,
      leftSetbackM: 1,
    );
    final suggestions =
        engine.suggest(plan: plan, site: site, settings: noSettings);

    expect(suggestions.length, 1);
    expect(suggestions.first.canApply, isTrue);
    expect(suggestions.first.adjustedSite!.leftSetbackM, closeTo(1.5, 0.001));
  });

  test('aplicar a sugestão elimina os avisos', () {
    const site = Site(
      widthM: 10,
      lengthM: 20,
      frontSetbackM: 5,
      leftSetbackM: 1,
    );
    final suggestion =
        engine.suggest(plan: plan, site: site, settings: noSettings).first;

    final alerts = checker.check(
      plan: plan,
      site: suggestion.adjustedSite!,
      settings: noSettings,
    );
    final problems =
        alerts.where((a) => a.severity != AlertSeverity.info).length;
    expect(problems, 0);
  });

  test('terreno estreito: sugere reduzir a largura, sem aplicar sozinho', () {
    // Sobram só 2 m de largura, e seriam necessários 3 m (1,5 + 1,5).
    const site = Site(
      widthM: 6,
      lengthM: 20,
      frontSetbackM: 5,
      leftSetbackM: 1,
    );
    final suggestions =
        engine.suggest(plan: plan, site: site, settings: noSettings);

    expect(suggestions.length, 1);
    expect(suggestions.first.canApply, isFalse);
  });

  test('sugere aproximar da rua quando a construção passa dos fundos', () {
    // Frente a 18 m: sobra espaço no terreno, mas a construção sai pelos fundos.
    const site = Site(
      widthM: 10,
      lengthM: 20,
      frontSetbackM: 18,
      leftSetbackM: 3,
    );
    final suggestions =
        engine.suggest(plan: plan, site: site, settings: noSettings);

    expect(suggestions.length, 1);
    // Faixa válida para a frente: de 0 até 20 - 3 - 1,5 = 15,5.
    expect(suggestions.first.adjustedSite!.frontSetbackM, closeTo(15.5, 0.001));
  });

  test('sugere reduzir a área quando a taxa de ocupação passa do limite', () {
    // 12 m² em 200 m² = 6%; limite de 5% = 10 m², logo excedem 2 m².
    const site = Site(
      widthM: 10,
      lengthM: 20,
      frontSetbackM: 5,
      leftSetbackM: 3,
    );
    final suggestions = engine.suggest(
      plan: plan,
      site: site,
      settings: const RuleSettings(maxOccupancyPercent: 5),
    );

    expect(suggestions.length, 1);
    expect(suggestions.first.canApply, isFalse);
  });
}
