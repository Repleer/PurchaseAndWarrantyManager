/// Гарантія, що скоро закінчується (картка на головному екрані).
class ExpiringWarranty {
  const ExpiringWarranty({
    required this.daysLeftLabel,
    required this.productName,
    required this.shop,
    required this.expiresOn,
  });

  final String daysLeftLabel;
  final String productName;
  final String shop;
  final String expiresOn;
}

/// Остання покупка (рядок таблиці «Останні чеки»).
class RecentPurchase {
  const RecentPurchase({
    required this.productName,
    required this.purchaseDate,
    required this.price,
    required this.warrantyUntil,
  });

  final String productName;
  final String purchaseDate;
  final String price;
  final String warrantyUntil;
}

/// Захардкоджені дані головного екрана (без Firebase / REST API).
abstract final class HomeMockData {
  static const String pageSubtitle =
      'Короткий огляд гарантій, що скоро закінчуються, і ваших останніх покупок.';

  static const List<ExpiringWarranty> expiringWarranties = [
    ExpiringWarranty(
      daysLeftLabel: '17 днів',
      productName: 'Навушники Sony WH-1000XM5',
      shop: 'Rozetka',
      expiresOn: '18.10.2026',
    ),
    ExpiringWarranty(
      daysLeftLabel: '28 днів',
      productName: 'Кавомашина De’Longhi Magnifica',
      shop: 'Comfy',
      expiresOn: '29.10.2026',
    ),
    ExpiringWarranty(
      daysLeftLabel: '42 дні',
      productName: 'Монітор Dell UltraSharp U2723QE',
      shop: 'MOYO',
      expiresOn: '12.11.2026',
    ),
  ];

  static const List<RecentPurchase> recentPurchases = [
    RecentPurchase(
      productName: 'Робот-пилосос Roborock Q8 Max',
      purchaseDate: '26.09.2026',
      price: '18 499 ₴',
      warrantyUntil: '26.09.2028',
    ),
    RecentPurchase(
      productName: 'Apple Magic Keyboard',
      purchaseDate: '14.09.2026',
      price: '5 999 ₴',
      warrantyUntil: '14.09.2027',
    ),
    RecentPurchase(
      productName: 'Електрочайник Tefal Loft',
      purchaseDate: '03.09.2026',
      price: '1 699 ₴',
      warrantyUntil: '03.09.2028',
    ),
  ];
}
