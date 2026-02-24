/// Formats a euro amount with thousands separators.
/// e.g. 247500.0 → "€247,500"  |  -50000.5 → "-€50,001"
String fmtEur(double v) {
  final isNeg = v < 0;
  final abs = v.abs();
  final intPart = abs.truncate();
  final decPart = abs - intPart;

  // Thousands-separated integer part.
  final raw = intPart.toString();
  final buf = StringBuffer();
  for (int i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) buf.write(',');
    buf.write(raw[i]);
  }

  // Cents only if non-zero.
  if (decPart > 0.005) {
    buf.write('.');
    buf.write((decPart * 100).round().toString().padLeft(2, '0'));
  }

  return '${isNeg ? '-' : ''}€$buf';
}

/// Compact form: 247500 → "€247.5k", 1500000 → "€1.5M"
String fmtEurCompact(double v) {
  final isNeg = v < 0;
  final abs = v.abs();
  String formatted;
  if (abs >= 1_000_000) {
    formatted = '€${(abs / 1_000_000).toStringAsFixed(2)}M';
  } else if (abs >= 1_000) {
    formatted = '€${(abs / 1_000).toStringAsFixed(1)}k';
  } else {
    formatted = '€${abs.toStringAsFixed(0)}';
  }
  return isNeg ? '-$formatted' : formatted;
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Jan 2024"
String fmtMonth(DateTime d) => '${_months[d.month - 1]} ${d.year}';
