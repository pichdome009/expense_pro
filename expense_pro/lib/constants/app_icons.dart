import 'package:flutter/material.dart';

/// Registry of known icons used across Categories and Wallets.
/// Using constant IconData references enables Flutter's icon font tree-shaking
/// and avoids runtime dynamic font lookups that cause slow builds or compile errors.
const List<IconData> kAllAppIcons = [
  // Categories (Expense)
  Icons.fastfood_rounded,
  Icons.directions_car_rounded,
  Icons.shopping_bag_rounded,
  Icons.local_hospital_rounded,
  Icons.school_rounded,
  Icons.movie_rounded,
  Icons.home_rounded,
  Icons.account_balance_wallet_rounded,

  // Categories (Income)
  Icons.work_rounded,
  Icons.storefront_rounded,
  Icons.trending_up_rounded,
  Icons.card_giftcard_rounded,
  Icons.attach_money_rounded,

  // Custom Category Picker
  Icons.stars_rounded,
  Icons.coffee_rounded,
  Icons.local_cafe_rounded,
  Icons.fitness_center_rounded,
  Icons.pets_rounded,
  Icons.sports_esports_rounded,
  Icons.flight_takeoff_rounded,
  Icons.spa_rounded,
  Icons.laptop_mac_rounded,
  Icons.smartphone_rounded,
  Icons.local_gas_station_rounded,
  Icons.build_rounded,
  Icons.music_note_rounded,
  Icons.savings_rounded,
  Icons.credit_card_rounded,
  Icons.clean_hands_rounded,

  // Wallets
  Icons.payments_rounded,
  Icons.account_balance_rounded,
  Icons.currency_exchange_rounded,
  Icons.wallet_rounded,
  Icons.category_rounded,
];

final Map<int, IconData> _iconMap = {
  for (final icon in kAllAppIcons) icon.codePoint: icon,
};

/// Get a const IconData from a stored codePoint, falling back to a default icon
IconData iconFromCodePoint(int codePoint) {
  return _iconMap[codePoint] ?? Icons.category_rounded;
}
