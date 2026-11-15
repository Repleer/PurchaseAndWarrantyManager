import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'data_failure.dart';

/// Читає й атомарно записує списки JSON у каталозі застосунку.
class JsonFileStore {
  JsonFileStore({Future<Directory> Function()? baseDir})
    : _baseDir = baseDir ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _baseDir;

  /// Повертає дійсний кореневий каталог локальних даних.
  Future<Directory> baseDirectory() => _baseDir();

  String _checkedPath(String relative, {required bool directory}) {
    final List<String> parts = relative.replaceAll('\\', '/').split('/');
    final int length = directory ? 2 : 3;
    if (parts.length != length ||
        parts.first != 'users' ||
        parts.any((part) => part.isEmpty || part == '.' || part == '..') ||
        (!directory && !parts.last.endsWith('.json'))) {
      throw const DataFailure('Некоректний шлях до локальних даних.');
    }
    return parts.join(Platform.pathSeparator);
  }

  Future<File> _file(String relativePath) async {
    final String relative = _checkedPath(relativePath, directory: false);
    final Directory base = await _baseDir();
    return File('${base.path}${Platform.pathSeparator}$relative');
  }

  /// Повертає null лише тоді, коли файлу ще немає.
  Future<List<Map<String, dynamic>>?> readList(String relativePath) async {
    final File file = await _file(relativePath);
    if (!await file.exists()) return null;
    try {
      final Object? decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) {
        throw const DataFailure('Локальні дані пошкоджено');
      }
      return List<Map<String, dynamic>>.unmodifiable(
        decoded.map((entry) {
          if (entry is! Map<String, dynamic>) {
            throw const DataFailure('Локальні дані пошкоджено');
          }
          return entry;
        }),
      );
    } on DataFailure {
      rethrow;
    } on FormatException {
      throw const DataFailure('Локальні дані пошкоджено');
    } on TypeError {
      throw const DataFailure('Локальні дані пошкоджено');
    } on FileSystemException {
      throw const DataFailure('Не вдалося прочитати локальні дані.');
    }
  }

  /// Записує через тимчасовий файл і атомарне перейменування.
  Future<void> writeList(
    String relativePath,
    List<Map<String, dynamic>> data,
  ) async {
    final File file = await _file(relativePath);
    try {
      await file.parent.create(recursive: true);
      final File temporary = File('${file.path}.tmp');
      await temporary.writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
        flush: true,
      );
      await temporary.rename(file.path);
    } on FileSystemException {
      throw const DataFailure('Не вдалося зберегти локальні дані.');
    }
  }

  /// Видаляє каталог лише в межах `users/<uid>`.
  Future<void> deleteDir(String relativeDir) async {
    final String relative = _checkedPath(relativeDir, directory: true);
    final Directory base = await _baseDir();
    final Directory directory = Directory(
      '${base.path}${Platform.pathSeparator}$relative',
    );
    try {
      if (await directory.exists()) await directory.delete(recursive: true);
    } on FileSystemException {
      throw const DataFailure('Не вдалося видалити локальні дані.');
    }
  }
}
