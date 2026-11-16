import 'package:flutter_test/flutter_test.dart';
import 'package:smartfloor/features/plan/domain/entities/plan.dart';
import 'package:smartfloor/features/rules/domain/entities/building_alert.dart';
import 'package:smartfloor/features/rules/domain/entities/rule_settings.dart';
import 'package:smartfloor/features/rules/domain/entities/site.dart';
import 'package:smartfloor/features/rules/domain/services/building_rule_checker.dart';

/// Conta quantos alertas de uma gravidade existem na lista.
int _count(List<BuildingAlert> alerts, AlertSeverity severity) {
  return alerts.where((a) => a.severity == severity).length;
}

void main() {
  // Construção de 4 m x 3 m (12 m²), usada em todos os testes.
  final Plan plan = Plan.rectangle(name: 'Teste', widthM: 4, lengthM: 3);
  const BuildingRuleChecker checker = BuildingRuleChecker();

  test('avisa quando a lateral esquerda fica a menos de 1,5 m do vizinho', () {
    // Terreno 10x20, frente a 5 m, esquerda a 1 m. Direita = 5 m, fundos = 12 m.
    const site = Site(
      widthM: 10,
      lengthM: 20,
      frontSetbackM: 5,
      leftSetbackM: 1,
    );
    final alerts =
        checker.check(plan: plan, site: site, settings: const RuleSettings());

    expect(_count(alerts, AlertSeverity.warning), 1);
    expect(_count(alerts, AlertSeverity.error), 0);
  });

  test('sem avisos quando todas as divisas têm 1,5 m ou mais', () {
    // Esquerda = 3 m, direita = 3 m, fundos = 12 m.
    const site = Site(
      widthM: 10,
      lengthM: 20,
      frontSetbackM: 5,
      leftSetbackM: 3,
    );
    final alerts =
        checker.check(plan: plan, site: site, settings: const RuleSettings());

    expect(_count(alerts, AlertSeverity.warning), 0);
    expect(_count(alerts, AlertSeverity.error), 0);
  });

  test('erro quando a construção ultrapassa o terreno', () {
    // Terreno com 3 m de largura não comporta 4 m + 1 m de afastamento.
    const site = Site(
      widthM: 3,
      lengthM: 20,
      frontSetbackM: 5,
      leftSetbackM: 1,
    );
    final alerts =
        checker.check(plan: plan, site: site, settings: const RuleSettings());

    expect(alerts.length, 1);
    expect(alerts.first.severity, AlertSeverity.error);
  });

  test('erro quando a taxa de ocupação passa do limite informado', () {
    // 12 m² em 200 m² = 6%. Limite informado de 5%.
    const site = Site(
      widthM: 10,
      lengthM: 20,
      frontSetbackM: 5,
      leftSetbackM: 3,
    );
    final alerts = checker.check(
      plan: plan,
      site: site,
      settings: const RuleSettings(maxOccupancyPercent: 5),
    );

    expect(_count(alerts, AlertSeverity.error), 1);
  });
}
