/// Незмінні дані профілю користувача без залежності від Firebase.
class UserProfile {
  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.createdAt,
    required List<String> providers,
  }) : providers = List.unmodifiable(providers);

  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime? createdAt;
  final List<String> providers;

  static const Object _unset = Object();

  /// Повертає копію з можливістю очистити необов'язкові поля через null.
  UserProfile copyWith({
    String? uid,
    String? email,
    Object? displayName = _unset,
    Object? photoUrl = _unset,
    Object? createdAt = _unset,
    List<String>? providers,
  }) => UserProfile(
    uid: uid ?? this.uid,
    email: email ?? this.email,
    displayName: identical(displayName, _unset)
        ? this.displayName
        : displayName as String?,
    photoUrl: identical(photoUrl, _unset) ? this.photoUrl : photoUrl as String?,
    createdAt: identical(createdAt, _unset)
        ? this.createdAt
        : createdAt as DateTime?,
    providers: providers ?? this.providers,
  );

  /// Формує JSON-сумісну мапу для майбутнього кешування.
  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'createdAt': createdAt?.toIso8601String(),
    'providers': providers.toList(),
  };

  /// Відновлює профіль із JSON-сумісної мапи.
  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    uid: json['uid'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String?,
    photoUrl: json['photoUrl'] as String?,
    createdAt: json['createdAt'] == null
        ? null
        : DateTime.parse(json['createdAt'] as String),
    providers: (json['providers'] as List).cast<String>(),
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserProfile ||
        uid != other.uid ||
        email != other.email ||
        displayName != other.displayName ||
        photoUrl != other.photoUrl ||
        createdAt != other.createdAt ||
        providers.length != other.providers.length) {
      return false;
    }
    for (int i = 0; i < providers.length; i++) {
      if (providers[i] != other.providers[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    uid,
    email,
    displayName,
    photoUrl,
    createdAt,
    Object.hashAll(providers),
  );
}
