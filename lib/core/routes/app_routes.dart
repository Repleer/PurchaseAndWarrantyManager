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
  static const String claims = '/claims';
  static const String profile = '/profile';
}
