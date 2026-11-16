/// Gravidade de um alerta. A ordem importa (info < warning < error).
enum AlertSeverity { info, warning, error }

/// Um resultado da análise, para ser mostrado ao usuário.
class BuildingAlert {
  final AlertSeverity severity;
  final String title;
  final String message;

  /// Base legal ou origem da regra (opcional).
  final String? reference;

  const BuildingAlert({
    required this.severity,
    required this.title,
    required this.message,
    this.reference,
  });
}
