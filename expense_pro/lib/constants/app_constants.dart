import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction.dart';

const List<Category> kExpenseCategories = [
  Category('អាហារ', Icons.fastfood_rounded, Color(0xFFF59E0B), isExpense: true),
  Category('ធ្វើដំណើរ', Icons.directions_car_rounded, Color(0xFF3B82F6), isExpense: true),
  Category('ទិញទំនិញ', Icons.shopping_bag_rounded, Color(0xFFEC4899), isExpense: true),
  Category('សុខភាព', Icons.local_hospital_rounded, Color(0xFFEF4444), isExpense: true),
  Category('ការសិក្សា', Icons.school_rounded, Color(0xFF8B5CF6), isExpense: true),
  Category('ការកម្សាន្ត', Icons.movie_rounded, Color(0xFF06B6D4), isExpense: true),
  Category('ផ្ទះ', Icons.home_rounded, Color(0xFF84CC16), isExpense: true),
  Category('ផ្សេងៗ', Icons.account_balance_wallet_rounded, Color(0xFF64748B), isExpense: true),
];

const List<Category> kIncomeCategories = [
  Category('ប្រាក់ខែ', Icons.work_rounded, Color(0xFF3B82F6), isExpense: false),
  Category('អាជីវកម្ម', Icons.storefront_rounded, Color(0xFF14B8A6), isExpense: false),
  Category('វិនិយោគ', Icons.trending_up_rounded, Color(0xFF22C55E), isExpense: false),
  Category('អំណោយ', Icons.card_giftcard_rounded, Color(0xFFEC4899), isExpense: false),
  Category('ផ្សេងៗ', Icons.attach_money_rounded, Color(0xFF64748B), isExpense: false),
];

List<Category> get kAllCategories => getAllCategories();

List<Category> getAllCategories([List<Category> customCategories = const []]) {
  final seen = <String>{};
  final list = <Category>[];
  for (final c in [...customCategories, ...kExpenseCategories, ...kIncomeCategories]) {
    if (seen.add(c.name)) list.add(c);
  }
  return list;
}

Category categoryByName(
  String name,
  TxType type, [
  List<Category> customCategories = const [],
]) {
  if (type == TxType.transfer) {
    return const Category(
      'ផ្ទេរប្រាក់',
      Icons.swap_horiz_rounded,
      Color(0xFF6366F1),
      isExpense: false,
    );
  }

  final customMatch = customCategories.cast<Category?>().firstWhere(
        (c) => c?.name == name,
        orElse: () => null,
      );
  if (customMatch != null) return customMatch;

  final list = type == TxType.income ? kIncomeCategories : kExpenseCategories;
  return list.firstWhere((c) => c.name == name, orElse: () => list.last);
}
