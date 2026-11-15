import '../domain/claim.dart';

/// П'ять звернень із таблиці макета та їхні історії.
abstract final class ClaimsMockData {
  static final List<Claim> items = List.unmodifiable([
    Claim(
      id: 'c1',
      number: 'ГВ-2026-010',
      purchaseId: 'p1',
      defectDate: DateTime(2026, 10, 10),
      serialNumber: 'S01-1234567-8',
      description:
          'У лівому навушнику зник звук. Тріск під час шумозаглушення.',
      status: ClaimStatus.underReview,
      createdAt: DateTime(2026, 10, 10, 14, 32),
      updatedAt: DateTime(2026, 10, 10, 14, 33),
      attachments: [
        ClaimAttachment(
          fileName: 'Лівий навушник.jpg',
          kind: AttachmentKind.image,
          sizeBytes: 2516582,
        ),
        ClaimAttachment(
          fileName: 'Перевірка звуку.mp4',
          kind: AttachmentKind.video,
          sizeBytes: 13421773,
        ),
      ],
      history: [
        ClaimHistoryEntry(
          title: 'Створено',
          at: DateTime(2026, 10, 10, 14, 32),
          note: 'Звернення успішно надіслано.',
          done: true,
        ),
        ClaimHistoryEntry(
          title: 'Гарантію перевірено',
          at: DateTime(2026, 10, 10, 14, 32),
          note: 'Гарантія чинна до 18.10.2026.',
          done: true,
        ),
        ClaimHistoryEntry(
          title: 'На розгляді',
          at: DateTime(2026, 10, 10, 14, 33),
          note: 'Очікуємо на відповідь продавця.',
          done: false,
        ),
      ],
      warrantyVerified: true,
    ),
    Claim(
      id: 'c2',
      number: 'ГВ-2026-009',
      purchaseId: 'p2',
      defectDate: DateTime(2026, 10, 8),
      serialNumber: 'DL-2024-1029',
      description: 'Не подає воду під час приготування кави.',
      status: ClaimStatus.inProgress,
      createdAt: DateTime(2026, 10, 8, 11, 20),
      updatedAt: DateTime(2026, 10, 9, 9, 10),
      attachments: [],
      history: [
        ClaimHistoryEntry(
          title: 'Створено',
          at: DateTime(2026, 10, 8, 11, 20),
          note: 'Звернення успішно надіслано.',
          done: true,
        ),
        ClaimHistoryEntry(
          title: 'В роботі',
          at: DateTime(2026, 10, 9, 9, 10),
          note: 'Сервіс розглядає звернення.',
          done: false,
        ),
      ],
      warrantyVerified: true,
    ),
    Claim(
      id: 'c3',
      number: 'ГВ-2026-008',
      purchaseId: 'p3',
      defectDate: DateTime(2026, 10, 6),
      serialNumber: 'RR-Q8-260926',
      description: 'Не повертається на зарядну станцію після прибирання.',
      status: ClaimStatus.inProgress,
      createdAt: DateTime(2026, 10, 6, 12, 0),
      updatedAt: DateTime(2026, 10, 7, 10, 0),
      attachments: [],
      history: [
        ClaimHistoryEntry(
          title: 'Створено',
          at: DateTime(2026, 10, 6, 12, 0),
          note: 'Звернення успішно надіслано.',
          done: true,
        ),
        ClaimHistoryEntry(
          title: 'В роботі',
          at: DateTime(2026, 10, 7, 10, 0),
          note: 'Сервіс розглядає звернення.',
          done: false,
        ),
      ],
      warrantyVerified: true,
    ),
    Claim(
      id: 'c4',
      number: 'ГВ-2026-007',
      purchaseId: 'p4',
      defectDate: DateTime(2026, 10, 2),
      serialNumber: 'MK-260914-01',
      description: 'Клавіша пробілу спрацьовує через раз.',
      status: ClaimStatus.resolved,
      createdAt: DateTime(2026, 10, 2, 10, 0),
      updatedAt: DateTime(2026, 10, 5, 16, 0),
      attachments: [],
      history: [
        ClaimHistoryEntry(
          title: 'Створено',
          at: DateTime(2026, 10, 2, 10, 0),
          note: 'Звернення успішно надіслано.',
          done: true,
        ),
        ClaimHistoryEntry(
          title: 'Вирішено',
          at: DateTime(2026, 10, 5, 16, 0),
          note: 'Звернення опрацьовано.',
          done: true,
        ),
      ],
      warrantyVerified: true,
    ),
    Claim(
      id: 'c5',
      number: 'ГВ-2026-006',
      purchaseId: 'p5',
      defectDate: DateTime(2026, 9, 28),
      serialNumber: 'TF-LF-030926',
      description: 'Не вимикається автоматично після закипання.',
      status: ClaimStatus.resolved,
      createdAt: DateTime(2026, 9, 28, 13, 0),
      updatedAt: DateTime(2026, 10, 1, 15, 0),
      attachments: [],
      history: [
        ClaimHistoryEntry(
          title: 'Створено',
          at: DateTime(2026, 9, 28, 13, 0),
          note: 'Звернення успішно надіслано.',
          done: true,
        ),
        ClaimHistoryEntry(
          title: 'Вирішено',
          at: DateTime(2026, 10, 1, 15, 0),
          note: 'Звернення опрацьовано.',
          done: true,
        ),
      ],
      warrantyVerified: true,
    ),
  ]);
}
