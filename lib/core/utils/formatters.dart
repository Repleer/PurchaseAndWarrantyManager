/// Форматує дату для українського інтерфейсу.
String formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.'
    '${date.month.toString().padLeft(2, '0')}.${date.year}';

/// Форматує дату й час для історії звернення.
String formatDateTime(DateTime date) =>
    '${formatDate(date)} · ${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';

/// Форматує вартість у гривнях із пробілами між тисячами.
String formatPrice(num price) {
  final String digits = price.toStringAsFixed(0);
  return '${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')} ₴';
}

String _plural(int count, String one, String few, String many) {
  final int absolute = count.abs();
  if (absolute % 100 >= 11 && absolute % 100 <= 14) return many;
  return switch (absolute % 10) {
    1 => one,
    >= 2 && <= 4 => few,
    _ => many,
  };
}

/// Форматує термін гарантії в місяцях.
String formatMonths(int months) =>
    '$months ${_plural(months, 'місяць', 'місяці', 'місяців')}';

/// Форматує залишок днів з українським відмінюванням.
String formatDaysLeft(int days) =>
    '$days ${_plural(days, 'день', 'дні', 'днів')}';

/// Форматує розмір файлу в мебібайтах з одним десятковим знаком.
String formatFileSize(int bytes) =>
    '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} МБ';
