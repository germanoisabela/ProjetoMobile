/// As formas possíveis de capturar um ambiente.
/// Um `enum` é uma lista fechada de opções: o app só aceita estes valores.
/// Fica no domain porque é uma regra do negócio, sem nada de Flutter.
enum CaptureMode {
  camera, // Tirar uma foto do ambiente ou da planta
  imageOrPdf, // Importar uma planta baixa já existente
  arLidar, // Escanear o ambiente em tempo real (Android)
}
