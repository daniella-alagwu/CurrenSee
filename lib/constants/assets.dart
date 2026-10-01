class AppAssets {
  AppAssets._();

  // Logo lockups (transparent PNGs)
  static const String logoMark = 'assets/brand/logo_mark.png';
  static const String logoFull = 'assets/brand/logo_full.png'; // mark + wordmark, horizontal
  static const String logoStacked = 'assets/brand/logo_stacked.png'; // mark above wordmark

  // Animated splash layers. The three square layers share one canvas centred
  // on the coin, so they can be rotated about their centre and stay aligned.
  static const String splashCoin = 'assets/brand/splash_coin.png';
  static const String splashArrowGreen = 'assets/brand/splash_arrow_green.png';
  static const String splashArrowGold = 'assets/brand/splash_arrow_gold.png';
  static const String splashCurren = 'assets/brand/splash_curren.png';
  static const String splashSee = 'assets/brand/splash_see.png';

  static const List<String> splashLayers = [
    splashCoin,
    splashArrowGreen,
    splashArrowGold,
    splashCurren,
    splashSee,
  ];

  // Photos
  static const String moneyLady = 'assets/images/money_lady.jpg';
}

class AppBrand {
  AppBrand._();

  /// Shown as "Powered by ..." on the splash and welcome screens.
  static const String poweredBy = 'AB Finance';
}
