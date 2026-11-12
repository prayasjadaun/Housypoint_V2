/// Indian-style number formatting for prices and counts.
class Formatters {
  Formatters._();

  /// 30000000 → "₹3 Cr", 4500000 → "₹45 L", 40000 → "₹40,000".
  static String price(num? value) {
    if (value == null || value <= 0) return 'Price on request';
    if (value >= 10000000) return '₹${_trim(value / 10000000)} Cr';
    if (value >= 100000) return '₹${_trim(value / 100000)} L';
    return '₹${grouped(value.round())}';
  }

  /// 1234567 → "12,34,567" (Indian digit grouping).
  static String grouped(int value) {
    final digits = value.abs().toString();
    if (digits.length <= 3) return '${value < 0 ? '-' : ''}$digits';
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${value < 0 ? '-' : ''}${parts.join(',')},$last3';
  }

  /// "semi-furnished" → "Semi furnished", "north east" → "North east".
  static String humanize(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final text = value.replaceAll(RegExp(r'[_-]'), ' ').trim();
    return text[0].toUpperCase() + text.substring(1);
  }

  static String _trim(double v) {
    final fixed = v.toStringAsFixed(2);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

/// "13 Feb 2026"
String formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
