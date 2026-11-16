import '../../../plan/domain/entities/plan.dart';

/// O terreno (retangular) e a posição da construção dentro dele.
///
/// Convenção: a planta é vista de CIMA, com a RUA na parte de BAIXO.
///   - "frente"  = divisa de baixo (rua)
///   - "fundos"  = divisa de cima (vizinho)
///   - esquerda e direita = vizinhos laterais
class Site {
  final double widthM;         // largura do terreno
  final double lengthM;        // comprimento (profundidade) do terreno
  final double frontSetbackM;  // distância da construção até a frente
  final double leftSetbackM;   // distância da construção até a esquerda

  const Site({
    required this.widthM,
    required this.lengthM,
    required this.frontSetbackM,
    required this.leftSetbackM,
  });

  /// Cópia do terreno trocando só o que for informado.
  /// (Mesma ideia do copyWith da Plan: não alteramos o objeto, criamos outro.)
  Site copyWith({
    double? widthM,
    double? lengthM,
    double? frontSetbackM,
    double? leftSetbackM,
  }) {
    return Site(
      widthM: widthM ?? this.widthM,
      lengthM: lengthM ?? this.lengthM,
      frontSetbackM: frontSetbackM ?? this.frontSetbackM,
      leftSetbackM: leftSetbackM ?? this.leftSetbackM,
    );
  }

  double get areaM2 => widthM * lengthM;

  /// Distância até a divisa da direita (o que sobra do terreno).
  /// Valor negativo = a construção passou do limite do terreno.
  double rightSetbackM(Plan plan) => widthM - leftSetbackM - plan.boundingWidthM;

  /// Distância até a divisa dos fundos (o que sobra do terreno).
  double rearSetbackM(Plan plan) => lengthM - frontSetbackM - plan.boundingHeightM;
}
