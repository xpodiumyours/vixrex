double? parseProductPriceAmount(String raw) {
  var cleaned = raw.trim().replaceAll(RegExp(r'[^\d,.]'), '');
  if (cleaned.isEmpty) return null;

  final lastComma = cleaned.lastIndexOf(',');
  final lastDot = cleaned.lastIndexOf('.');

  if (lastComma != -1 && lastDot != -1) {
    final decimalSeparator = lastComma > lastDot ? ',' : '.';
    final thousandsSeparator = decimalSeparator == ',' ? '.' : ',';
    cleaned = cleaned.replaceAll(thousandsSeparator, '');
    if (decimalSeparator == ',') cleaned = cleaned.replaceAll(',', '.');
  } else if (lastComma != -1) {
    cleaned = cleaned.replaceAll(',', '.');
  } else if (RegExp(r'^\d{1,3}(?:\.\d{3})+$').hasMatch(cleaned)) {
    cleaned = cleaned.replaceAll('.', '');
  }

  final amount = double.tryParse(cleaned);
  return amount != null && amount >= 0 ? amount : null;
}
