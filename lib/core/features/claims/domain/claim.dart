import '../../../utils/formatters.dart';

/// Стани опрацювання гарантійного звернення.
enum ClaimStatus {
  underReview('На розгляді'),
  inProgress('В роботі'),
  resolved('Вирішено'),
  rejected('Відхилено');

  const ClaimStatus(this.label);
  final String label;
}

/// Тип доданого до звернення матеріалу.
enum AttachmentKind { image, video }

/// Незмінний опис фото чи відео дефекту.
class ClaimAttachment {
  const ClaimAttachment({
    required this.fileName,
    required this.kind,
    required this.sizeBytes,
  });

  final String fileName;
  final AttachmentKind kind;
  final int sizeBytes;

  /// Тип та розмір вкладення для підпису в інтерфейсі.
  String get subtitle {
    final String extension = fileName.split('.').last.toUpperCase();
    return '$extension · ${formatFileSize(sizeBytes)}';
  }

  /// Перетворює вкладення на JSON-сумісну мапу.
  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'kind': kind.name,
    'sizeBytes': sizeBytes,
  };

  /// Відновлює вкладення з JSON-сумісної мапи.
  factory ClaimAttachment.fromJson(Map<String, dynamic> json) =>
      ClaimAttachment(
        fileName: json['fileName'] as String,
        kind: AttachmentKind.values.byName(json['kind'] as String),
        sizeBytes: json['sizeBytes'] as int,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaimAttachment &&
          fileName == other.fileName &&
          kind == other.kind &&
          sizeBytes == other.sizeBytes;

  @override
  int get hashCode => Object.hash(fileName, kind, sizeBytes);
}

/// Незмінний запис події в історії звернення.
class ClaimHistoryEntry {
  const ClaimHistoryEntry({
    required this.title,
    required this.at,
    required this.note,
    required this.done,
  });

  final String title;
  final DateTime at;
  final String note;
  final bool done;

  /// Перетворює подію на JSON-сумісну мапу.
  Map<String, dynamic> toJson() => {
    'title': title,
    'at': at.toIso8601String(),
    'note': note,
    'done': done,
  };

  /// Відновлює подію з JSON-сумісної мапи.
  factory ClaimHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ClaimHistoryEntry(
        title: json['title'] as String,
        at: DateTime.parse(json['at'] as String),
        note: json['note'] as String,
        done: json['done'] as bool,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClaimHistoryEntry &&
          title == other.title &&
          at == other.at &&
          note == other.note &&
          done == other.done;

  @override
  int get hashCode => Object.hash(title, at, note, done);
}

/// Незмінне звернення з матеріалами та історією.
class Claim {
  Claim({
    required this.id,
    required this.number,
    required this.purchaseId,
    required this.defectDate,
    required this.serialNumber,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required List<ClaimAttachment> attachments,
    required List<ClaimHistoryEntry> history,
    required this.warrantyVerified,
  }) : attachments = List.unmodifiable(attachments),
       history = List.unmodifiable(history);

  final String id;
  final String number;
  final String purchaseId;
  final DateTime defectDate;
  final String serialNumber;
  final String description;
  final ClaimStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ClaimAttachment> attachments;
  final List<ClaimHistoryEntry> history;
  final bool warrantyVerified;

  /// Створює копію звернення із заданими змінами.
  Claim copyWith({
    String? id,
    String? number,
    String? purchaseId,
    DateTime? defectDate,
    String? serialNumber,
    String? description,
    ClaimStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ClaimAttachment>? attachments,
    List<ClaimHistoryEntry>? history,
    bool? warrantyVerified,
  }) => Claim(
    id: id ?? this.id,
    number: number ?? this.number,
    purchaseId: purchaseId ?? this.purchaseId,
    defectDate: defectDate ?? this.defectDate,
    serialNumber: serialNumber ?? this.serialNumber,
    description: description ?? this.description,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    attachments: attachments ?? this.attachments,
    history: history ?? this.history,
    warrantyVerified: warrantyVerified ?? this.warrantyVerified,
  );

  /// Перетворює звернення та вкладені об'єкти на JSON-сумісну мапу.
  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'purchaseId': purchaseId,
    'defectDate': defectDate.toIso8601String(),
    'serialNumber': serialNumber,
    'description': description,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'attachments': attachments.map((item) => item.toJson()).toList(),
    'history': history.map((item) => item.toJson()).toList(),
    'warrantyVerified': warrantyVerified,
  };

  /// Відновлює звернення та вкладені об'єкти з JSON-сумісної мапи.
  factory Claim.fromJson(Map<String, dynamic> json) => Claim(
    id: json['id'] as String,
    number: json['number'] as String,
    purchaseId: json['purchaseId'] as String,
    defectDate: DateTime.parse(json['defectDate'] as String),
    serialNumber: json['serialNumber'] as String,
    description: json['description'] as String,
    status: ClaimStatus.values.byName(json['status'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    attachments: (json['attachments'] as List)
        .map((item) => ClaimAttachment.fromJson(item as Map<String, dynamic>))
        .toList(),
    history: (json['history'] as List)
        .map((item) => ClaimHistoryEntry.fromJson(item as Map<String, dynamic>))
        .toList(),
    warrantyVerified: json['warrantyVerified'] as bool,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Claim &&
          id == other.id &&
          number == other.number &&
          purchaseId == other.purchaseId &&
          defectDate == other.defectDate &&
          serialNumber == other.serialNumber &&
          description == other.description &&
          status == other.status &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt &&
          _equalLists(attachments, other.attachments) &&
          _equalLists(history, other.history) &&
          warrantyVerified == other.warrantyVerified;

  @override
  int get hashCode => Object.hash(
    id,
    number,
    purchaseId,
    defectDate,
    serialNumber,
    description,
    status,
    createdAt,
    updatedAt,
    Object.hashAll(attachments),
    Object.hashAll(history),
    warrantyVerified,
  );
}

bool _equalLists<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
