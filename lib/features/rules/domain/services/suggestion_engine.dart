import 'dart:math' as math;

import '../../../../core/utils/formatters.dart';
import '../../../plan/domain/entities/plan.dart';
import '../entities/rule_settings.dart';
import '../entities/site.dart';
import '../entities/suggestion.dart';
import 'building_rule_checker.dart';

/// Gera sugestões de correção. Assim como o BuildingRuleChecker, é
/// DOMÍNIO puro (sem Flutter) e, por isso, fácil de testar.
class SuggestionEngine {
  const SuggestionEngine();

  /// Tolerância de 1 mm para erros de arredondamento.
  static const double _epsilon = 0.001;

  List<Suggestion> suggest({
    required Plan plan,
    required Site site,
    required RuleSettings settings,
  }) {
    // Mínimos de cada lado: o maior entre 1,50 m (Art. 1.301) e o do município.
    final double minSide = math.max(
      BuildingRuleChecker.civilCodeDistanceM,
      settings.minSideSetbackM,
    );
    final double minRear = math.max(
      BuildingRuleChecker.civilCodeDistanceM,
      settings.minRearSetbackM,
    );
    final double minFront = settings.minFrontSetbackM; // a frente dá para a rua

    final List<Suggestion> suggestions = [];

    // Cada função devolve uma sugestão ou null (nada a sugerir).
    final Suggestion? horizontal = _horizontal(plan, site, minSide);
    final Suggestion? vertical = _vertical(plan, site, minRear, minFront);
    final Suggestion? occupancy = _occupancy(plan, site, settings);

    if (horizontal != null) suggestions.add(horizontal);
    if (vertical != null) suggestions.add(vertical);
    if (occupancy != null) suggestions.add(occupancy);
    return suggestions;
  }

  // ---------- Eixo horizontal (esquerda / direita) ----------
  Suggestion? _horizontal(Plan plan, Site site, double minSide) {
    // Espaço que sobra no terreno depois de colocar a construção.
    final double freeWidth = site.widthM - plan.boundingWidthM;

    // CASO A: sobra espaço para os dois afastamentos mínimos.
    if (freeWidth + _epsilon >= 2 * minSide) {
      // Faixa de posições válidas para "distância até a esquerda".
      final double lowest = minSide;
      final double highest = math.max(minSide, freeWidth - minSide);

      // clamp = "prende" o valor atual dentro da faixa, mexendo o mínimo.
      final double newLeft =
          site.leftSetbackM.clamp(lowest, highest).toDouble();
      final double delta = newLeft - site.leftSetbackM;

      if (delta.abs() <= _epsilon) return null; // já está numa posição válida

      final double newRight = site.widthM - newLeft - plan.boundingWidthM;
      final String direction = delta > 0 ? 'direita' : 'esquerda';

      return Suggestion(
        title: 'Desloque a construção ${formatDecimal(delta.abs())} m '
            'para a $direction',
        message: 'Com esse ajuste, os afastamentos ficam em '
            '${formatDecimal(newLeft)} m à esquerda e '
            '${formatDecimal(newRight)} m à direita, respeitando o mínimo '
            'de ${formatDecimal(minSide)} m de cada lado.',
        adjustedSite: site.copyWith(leftSetbackM: newLeft),
      );
    }

    // CASO B: não sobra espaço. Nenhum deslocamento resolve.
    final double maxWidth = site.widthM - 2 * minSide;
    if (maxWidth > 0) {
      return Suggestion(
        title: 'Reduza a largura da construção',
        message: 'Para manter ${formatDecimal(minSide)} m de cada divisa '
            'lateral, a largura da construção deveria ser de no máximo '
            '${formatDecimal(maxWidth)} m (hoje é '
            '${formatDecimal(plan.boundingWidthM)} m). Outra opção é '
            'evitar janelas, varandas e terraços nos lados que ficarem '
            'com menos de ${formatDecimal(minSide)} m.',
      );
    }

    return Suggestion(
      title: 'Terreno estreito para os afastamentos laterais',
      message: 'O terreno é estreito demais para manter '
          '${formatDecimal(minSide)} m de cada divisa lateral. Revise a '
          'largura do terreno ou evite janelas, varandas e terraços nos '
          'lados com menos de ${formatDecimal(minSide)} m.',
    );
  }

  // ---------- Eixo vertical (frente / fundos) ----------
  Suggestion? _vertical(
    Plan plan,
    Site site,
    double minRear,
    double minFront,
  ) {
    final double freeLength = site.lengthM - plan.boundingHeightM;

    // CASO A: sobra espaço para os afastamentos mínimos.
    if (freeLength + _epsilon >= minRear + minFront) {
      final double lowest = minFront;
      final double highest = math.max(minFront, freeLength - minRear);

      final double newFront =
          site.frontSetbackM.clamp(lowest, highest).toDouble();
      final double delta = newFront - site.frontSetbackM;

      if (delta.abs() <= _epsilon) return null;

      final double newRear = site.lengthM - newFront - plan.boundingHeightM;
      // Aumentar a distância até a frente = afastar da rua.
      final String action = delta > 0
          ? 'Afaste a construção da rua'
          : 'Aproxime a construção da rua';
      final String frontRule = minFront > 0
          ? ' e ${formatDecimal(minFront)} m na frente'
          : '';

      return Suggestion(
        title: '$action em ${formatDecimal(delta.abs())} m',
        message: 'Com esse ajuste, a frente fica a '
            '${formatDecimal(newFront)} m da rua e os fundos a '
            '${formatDecimal(newRear)} m da divisa, respeitando o mínimo '
            'de ${formatDecimal(minRear)} m nos fundos$frontRule.',
        adjustedSite: site.copyWith(frontSetbackM: newFront),
      );
    }

    // CASO B: não sobra espaço.
    final double maxHeight = site.lengthM - minRear - minFront;
    if (maxHeight > 0) {
      return Suggestion(
        title: 'Reduza o comprimento da construção',
        message: 'Para respeitar os afastamentos mínimos de frente e '
            'fundos, o comprimento da construção deveria ser de no máximo '
            '${formatDecimal(maxHeight)} m (hoje é '
            '${formatDecimal(plan.boundingHeightM)} m).',
      );
    }

    return const Suggestion(
      title: 'Terreno curto para os afastamentos de frente e fundos',
      message: 'O terreno é curto demais para manter os afastamentos '
          'mínimos de frente e fundos. Revise o comprimento do terreno.',
    );
  }

  // ---------- Taxa de ocupação ----------
  Suggestion? _occupancy(Plan plan, Site site, RuleSettings settings) {
    final double maxPercent = settings.maxOccupancyPercent;
    if (maxPercent <= 0) return null; // limite não informado

    final double occupancy = plan.areaM2 / site.areaM2 * 100;
    if (occupancy <= maxPercent + 0.01) return null; // dentro do limite

    final double maxArea = site.areaM2 * maxPercent / 100;
    final double excess = plan.areaM2 - maxArea;

    return Suggestion(
      title: 'Reduza a área construída em ${formatDecimal(excess)} m²',
      message: 'Para respeitar o limite de ${formatDecimal(maxPercent)}%, '
          'a construção pode ter no máximo ${formatDecimal(maxArea)} m² '
          '(hoje tem ${formatDecimal(plan.areaM2)} m²).',
    );
  }
}
