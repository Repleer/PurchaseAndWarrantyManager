/// Імена маршрутів застосунку.
///
/// Екран входу є початковим маршрутом (`/`).
abstract final class AppRoutes {
  static const String login = '/';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String googleAccount = '/google-account';

  static const String home = '/home';
  static const String purchases = '/purchases';
  static const String purchaseDetails = '/purchases/details';
  static const String purchaseCreate = '/purchases/new';
  static const String purchaseEdit = '/purchases/edit';
  static const String claims = '/claims';
  static const String claimDetails = '/claims/details';
  static const String claimPickPurchase = '/claims/pick-purchase';
  static const String claimCreate = '/claims/new';
  static const String claimEdit = '/claims/edit';
  static const String profile = '/profile';
}
