import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_and_purchase_manager/core/utils/formatters.dart';

void main() {
  test('форматує дату та дату з часом', () {
    expect(formatDate(DateTime(2024, 10, 18)), '18.10.2024');
    expect(
      formatDateTime(DateTime(2026, 10, 10, 14, 32)),
      '10.10.2026 · 14:32',
    );
    expect(formatDateTime(DateTime(2026, 1, 2, 3, 4)), '02.01.2026 · 03:04');
  });

  test('форматує ціну', () {
    expect(formatPrice(14999), '14 999 ₴');
    expect(formatPrice(5999), '5 999 ₴');
    expect(formatPrice(42), '42 ₴');
  });

  test('відмінює місяці й дні з винятком 11–14', () {
    expect(formatMonths(1), '1 місяць');
    expect(formatMonths(2), '2 місяці');
    expect(formatMonths(4), '4 місяці');
    expect(formatMonths(5), '5 місяців');
    expect(formatMonths(11), '11 місяців');
    expect(formatMonths(21), '21 місяць');
    expect(formatMonths(24), '24 місяці');
    expect(formatDaysLeft(1), '1 день');
    expect(formatDaysLeft(3), '3 дні');
    expect(formatDaysLeft(17), '17 днів');
    expect(formatDaysLeft(21), '21 день');
    expect(formatDaysLeft(42), '42 дні');
    expect(formatDaysLeft(111), '111 днів');
  });

  test('форматує розмір файлу в МБ', () {
    expect(formatFileSize(2516582), '2,4 МБ');
    expect(formatFileSize(13421773), '12,8 МБ');
  });
}
