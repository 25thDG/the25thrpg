/// Whole kilometres with thousands separators: 12500 → "12,500".
String fmtKm(num v) {
  final rounded = v.round();
  final raw = rounded.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) buf.write(',');
    buf.write(raw[i]);
  }
  return '${rounded < 0 ? '-' : ''}$buf';
}

/// Tick and axis form: 12500 → "12.5k", 15000 → "15k", 800 → "800".
String fmtKmCompact(num v) {
  if (v.abs() < 1000) return v.round().toString();
  final s = (v / 1000).toStringAsFixed(1);
  return '${s.endsWith('.0') ? s.substring(0, s.length - 2) : s}k';
}

/// A daily rate: 27.34 → "27.3".
String fmtRate(double v) => v.toStringAsFixed(1);

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "12 Nov 2026"
String fmtDay(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// "12 Nov"
String fmtDayShort(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// "Nov"
String fmtMonthName(DateTime d) => _months[d.month - 1];
