import 'package:flutter/foundation.dart';

import '../../purchases/domain/purchase.dart';
import '../data/warranty_verification_service.dart';
import '../domain/warranty_check.dart';

/// Ефемерні стани перевірки гарантії на рівні форми.
enum WarrantyCheckStatus { idle, checking, done }

/// Керує однією перевіркою гарантії та ігнорує застарілі результати.
class WarrantyCheckController extends ChangeNotifier {
  WarrantyCheckController(this._service);

  final WarrantyVerificationService _service;
  int _generation = 0;
  bool _disposed = false;
  WarrantyCheckStatus status = WarrantyCheckStatus.idle;
  WarrantyCheckResult? result;

  Future<void> run(Purchase purchase, String serial) async {
    if (_disposed) return;
    final int generation = ++_generation;
    status = WarrantyCheckStatus.checking;
    result = null;
    notifyListeners();
    try {
      final WarrantyCheckResult checked = await _service.verify(
        purchase: purchase,
        serialNumber: serial,
      );
      if (_disposed || generation != _generation) return;
      result = checked;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      result = null;
    }
    status = WarrantyCheckStatus.done;
    notifyListeners();
  }

  void reset() {
    if (_disposed) return;
    _generation++;
    status = WarrantyCheckStatus.idle;
    result = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
