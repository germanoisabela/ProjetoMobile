/// Parâmetros da legislação MUNICIPAL, informados pelo usuário.
/// Valor 0 significa "não informado": a regra correspondente não é verificada.
class RuleSettings {
  final double minFrontSetbackM;
  final double minSideSetbackM;
  final double minRearSetbackM;
  final double maxOccupancyPercent;

  const RuleSettings({
    this.minFrontSetbackM = 0,
    this.minSideSetbackM = 0,
    this.minRearSetbackM = 0,
    this.maxOccupancyPercent = 0,
  });
}
