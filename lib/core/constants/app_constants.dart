class AppConstants {
  AppConstants._();

  // MiomiPay API
  static const String miomiPayBaseUrl = 'https://pg.miomidev.com/api/v1';
  static const String miomiPayKey = 'MP-SB-84KfA7pgzP7FQoqLQt0DkzeUu5XJgVeS';
  static const String miomiPayWebhookSecret = 'whsec_MJ6OOpFAXYyoZ0RQZKuydZ4Dr7ZPEnjr';

  // Firebase Realtime DB Paths
  static const String usersPath = 'users';
  static const String menuPath = 'menu';
  static const String transactionsPath = 'transactions';

  // Role
  static const String roleAdmin = 'admin';
  static const String roleKasir = 'kasir';

  // Category
  static const List<String> menuCategories = [
    'Semua',
    'Makanan',
    'Minuman',
    'Snack',
    'Lainnya',
  ];

  // Payment Method
  static const String paymentQris = 'qris';
  static const String paymentCash = 'cash';

  // Transaction Status
  static const String statusPending = 'PENDING';
  static const String statusPaid = 'PAID';
  static const String statusExpired = 'EXPIRED';

  // Tax Rate
  static const double taxRate = 0.10; // 10% PB1

  // Spacing
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;

  // Border Radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 9999.0;
}
