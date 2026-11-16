import 'site.dart';

/// Uma sugestão de correção para o usuário.
class Suggestion {
  final String title;
  final String message;

  /// Se não for nulo, a sugestão pode ser APLICADA automaticamente:
  /// é o terreno com a construção já na nova posição.
  /// Se for nulo, é só uma orientação (ex.: "reduza a largura").
  final Site? adjustedSite;

  const Suggestion({
    required this.title,
    required this.message,
    this.adjustedSite,
  });

  bool get canApply => adjustedSite != null;
}
