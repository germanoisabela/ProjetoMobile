import 'capture_mode.dart';

/// O arquivo que o usuário escolheu (foto tirada ou imagem/PDF importado).
/// Guarda só dados simples, sem depender de nenhum pacote.
class CapturedInput {
  /// Caminho do arquivo no armazenamento do celular.
  final String path;

  /// Nome do arquivo (ex.: "planta_casa.pdf").
  final String name;

  /// Como o arquivo foi obtido (câmera, importação...).
  final CaptureMode mode;

  const CapturedInput({
    required this.path,
    required this.name,
    required this.mode,
  });

  /// `true` se o arquivo é um PDF.
  /// Um "getter" se usa como propriedade: input.isPdf
  bool get isPdf => name.toLowerCase().endsWith('.pdf');
}