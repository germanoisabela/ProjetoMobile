/// Formata um número com duas casas decimais e vírgula, no padrão brasileiro.
String formatDecimal(double value) {
  return value.toStringAsFixed(2).replaceAll('.', ',');
}

/// Converte texto em número, aceitando vírgula ("3,5") ou ponto ("3.5").
/// Retorna null se o texto não for um número válido.
double? parseDecimal(String? text) {
  if (text == null) return null;
  return double.tryParse(text.trim().replaceAll(',', '.'));
}
