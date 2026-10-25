import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warranty_and_purchase_manager/core/features/auth/application/auth_controller.dart';
import 'package:warranty_and_purchase_manager/core/routes/app_routes.dart';
import 'package:warranty_and_purchase_manager/core/theme/app_colors.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> _authStateChanges;
  bool _hasReceivedState = false;
  String? _lastUid;

  @override
  void initState() {
    super.initState();
    _authStateChanges = context.read<AuthController>().authStateChanges();
  }

  void _syncRoute(User? user) {
    final String? uid = user?.uid;
    if (_hasReceivedState && uid == _lastUid) return;
    _hasReceivedState = true;
    _lastUid = uid;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        user == null ? AppRoutes.login : AppRoutes.home,
        (_) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Не вдалося відновити сеанс. Перезапустіть застосунок.'),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        _syncRoute(snapshot.data);
        return widget.child;
      },
    );
  }
}
