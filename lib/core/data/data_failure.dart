/// Помилка доступу до локальних даних із повідомленням для користувача.
class DataFailure implements Exception {
  const DataFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
