import 'package:flutter/material.dart';
import 'package:warranty_and_purchase_manager/core/routes/app_router.dart';
import 'package:warranty_and_purchase_manager/core/theme/app_theme.dart';
import 'package:warranty_and_purchase_manager/core/core.dart';


/// Кореневий віджет застосунку «Менеджер гарантій і покупок».
class WarrantyManagerApp extends StatelessWidget {
  const WarrantyManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Менеджер гарантій і покупок',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
