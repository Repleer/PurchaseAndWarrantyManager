import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/data/claims_mock_data.dart';
import 'package:warranty_and_purchase_manager/core/features/claims/domain/claim.dart';

void main() {
  final Claim sony = ClaimsMockData.items.first;

  test('JSON round-trip зберігає вкладення, історію та всі поля', () {
    final Map<String, dynamic> decoded =
        jsonDecode(jsonEncode(sony.toJson())) as Map<String, dynamic>;
    final Claim restored = Claim.fromJson(decoded);
    expect(restored, sony);
    expect(restored.hashCode, sony.hashCode);
    expect(decoded['status'], 'underReview');
    expect(decoded['attachments'][0]['kind'], 'image');
    expect(restored.attachments.first.subtitle, 'JPG · 2,4 МБ');
    expect(restored.attachments.last.subtitle, 'MP4 · 12,8 МБ');
    expect(restored.history.last.done, isFalse);
  });

  test('вкладені списки незмінні і порівнюються за вмістом', () {
    final List<ClaimAttachment> attachments = [...sony.attachments];
    final Claim copy = sony.copyWith(attachments: attachments);
    attachments.clear();
    expect(copy, sony);
    expect(() => copy.attachments.clear(), throwsUnsupportedError);
    expect(() => copy.history.clear(), throwsUnsupportedError);
    expect(copy.copyWith(history: []), isNot(sony));
  });

  test('кожне звернення посилається на окрему покупку', () {
    expect(ClaimsMockData.items.length, 5);
    expect(ClaimsMockData.items.map((c) => c.purchaseId).toList(), [
      'p1',
      'p2',
      'p3',
      'p4',
      'p5',
    ]);
  });
}
