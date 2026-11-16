import '../entities/captured_input.dart';

/// Contrato: o que precisamos saber fazer para capturar um ambiente.
///
/// `Future<CapturedInput?>` significa: "resultado que chega depois (Future)
/// e que pode ser nulo (?)". Retorna null quando o usuário cancela.
abstract class CaptureRepository {
  /// Abre a câmera e devolve a foto tirada.
  Future<CapturedInput?> pickFromCamera();

  /// Abre o seletor de arquivos para escolher uma imagem ou PDF.
  Future<CapturedInput?> pickImageOrPdf();
}