import '../../../../core/utils/formatters.dart';
import '../../../plan/domain/entities/plan.dart';
import '../entities/building_alert.dart';
import '../entities/rule_settings.dart';
import '../entities/site.dart';

/// Um lado do terreno, com a distância da construção até ele.
/// Classe privada (começa com "_"): só este arquivo usa.
class _Side {
  final String name; // "esquerda", "direita", "fundos", "frente"
  final double distanceM; // distância da construção até a divisa
  final bool isNeighbor; // true = divisa com vizinho; false = rua
  final double minSetbackM; // recuo mínimo do município (0 = não verificar)

  const _Side({
    required this.name,
    required this.distanceM,
    required this.isNeighbor,
    required this.minSetbackM,
  });
}

/// Aplica as regras construtivas e devolve a lista de alertas.
///
/// É uma classe de DOMÍNIO: não tem nada de Flutter. Por isso dá para
/// testá-la sozinha, sem abrir o app (veja a pasta test/).
class BuildingRuleChecker {
  const BuildingRuleChecker();

  /// Distância citada no Art. 1.301 do Código Civil (metro e meio).
  static const double civilCodeDistanceM = 1.5;

  /// Tolerância para erros de arredondamento (1 milímetro).
  static const double _epsilon = 0.001;

  List<BuildingAlert> check({
    required Plan plan,
    required Site site,
    required RuleSettings settings,
    double? occupiedAreaM2,
  }) {
    final List<_Side> sides = [
      _Side(
        name: 'esquerda',
        distanceM: site.leftSetbackM,
        isNeighbor: true,
        minSetbackM: settings.minSideSetbackM,
      ),
      _Side(
        name: 'direita',
        distanceM: site.rightSetbackM(plan),
        isNeighbor: true,
        minSetbackM: settings.minSideSetbackM,
      ),
      _Side(
        name: 'fundos',
        distanceM: site.rearSetbackM(plan),
        isNeighbor: true,
        minSetbackM: settings.minRearSetbackM,
      ),
      _Side(
        name: 'frente',
        distanceM: site.frontSetbackM,
        isNeighbor: false,
        minSetbackM: settings.minFrontSetbackM,
      ),
    ];

    final List<BuildingAlert> alerts = [];

    // ---------- Regra 1: a construção cabe no terreno? ----------
    final List<_Side> outside =
        sides.where((s) => s.distanceM < -_epsilon).toList();
    if (outside.isNotEmpty) {
      final String names = outside.map((s) => s.name).join(', ');
      // Se não cabe, as outras regras perdem o sentido: retornamos já.
      return [
        BuildingAlert(
          severity: AlertSeverity.error,
          title: 'Construção fora do terreno',
          message: 'A construção ultrapassa o limite do terreno '
              '(lados: $names). Reduza as medidas da planta ou ajuste '
              'o terreno e os afastamentos.',
        ),
      ];
    }

    // ---------- Regra 2: Art. 1.301 do Código Civil ----------
    final List<_Side> tooClose = sides
        .where(
            (s) => s.isNeighbor && s.distanceM < civilCodeDistanceM - _epsilon)
        .toList();

    for (final _Side side in tooClose) {
      alerts.add(
        BuildingAlert(
          severity: AlertSeverity.warning,
          title: 'Lado ${side.name}: menos de 1,50 m da divisa',
          message: 'A construção está a ${formatDecimal(side.distanceM)} m '
              'da divisa ${side.name}. Janelas, varandas, terraços e '
              'eirados a menos de 1,50 m do terreno vizinho não são '
              'permitidos (há exceção para pequenas aberturas de luz e '
              'ventilação). Evite aberturas deste lado ou aumente o '
              'afastamento.',
          reference: 'Código Civil, Art. 1.301',
        ),
      );
    }

    if (tooClose.isEmpty) {
      alerts.add(
        const BuildingAlert(
          severity: AlertSeverity.info,
          title: 'Afastamento de 1,50 m respeitado',
          message: 'Nas divisas com vizinhos (esquerda, direita e fundos) '
              'a construção mantém pelo menos 1,50 m, distância citada no '
              'Art. 1.301 do Código Civil para janelas, varandas e terraços.',
          reference: 'Código Civil, Art. 1.301',
        ),
      );
    }

    // ---------- Regra 3: recuos mínimos do município ----------
    for (final _Side side in sides) {
      final bool checked = side.minSetbackM > 0;
      if (checked && side.distanceM < side.minSetbackM - _epsilon) {
        alerts.add(
          BuildingAlert(
            severity: AlertSeverity.error,
            title: 'Lado ${side.name}: recuo abaixo do mínimo',
            message: 'O afastamento é de ${formatDecimal(side.distanceM)} m, '
                'mas o mínimo informado para este lado é '
                '${formatDecimal(side.minSetbackM)} m. Confira a lei de uso '
                'e ocupação do solo do seu município.',
            reference: 'Legislação municipal (valor informado por você)',
          ),
        );
      }
    }

    // ---------- Regra 4: taxa de ocupação ----------
    final double areaM2 = occupiedAreaM2 ?? plan.areaM2;
    final double occupancy = areaM2 / site.areaM2 * 100;
    final double maxOccupancy = settings.maxOccupancyPercent;

    if (maxOccupancy > 0 && occupancy > maxOccupancy + 0.01) {
      alerts.add(
        BuildingAlert(
          severity: AlertSeverity.error,
          title: 'Taxa de ocupação acima do limite',
          message: 'A construção ocupa ${formatDecimal(occupancy)}% do '
              'terreno, e o limite informado é ${formatDecimal(maxOccupancy)}%.',
          reference: 'Legislação municipal (valor informado por você)',
        ),
      );
    } else {
      final String limitText = maxOccupancy > 0
          ? 'Dentro do limite informado de ${formatDecimal(maxOccupancy)}%.'
          : 'Nenhum limite foi informado para comparação.';
      alerts.add(
        BuildingAlert(
          severity: AlertSeverity.info,
          title: 'Taxa de ocupação: ${formatDecimal(occupancy)}%',
          message: 'A planta ocupa ${formatDecimal(areaM2)} m² de um '
              'terreno de ${formatDecimal(site.areaM2)} m². $limitText',
        ),
      );
    }

    // Erros primeiro, depois avisos, depois informações.
    alerts.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return alerts;
  }
}
