import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/debt_loan.dart';
import '../models/saving_goal.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';

class StorageService {
  static const _kTxKey = 'transactions_v2';
  static const _kBudgetKey = 'monthly_budget_v1';
  static const _kCurrencyKey = 'currency_v1';
  static const _kRateKey = 'exchange_rate_v1';
  static const _kWalletsKey = 'wallets_v1';
  static const _kCustomCategoriesKey = 'custom_categories_v1';
  static const _kCategoryBudgetsKey = 'category_budgets_v1';
  static const _kSavingGoalsKey = 'saving_goals_v1';
  static const _kDebtsKey = 'debts_v1';
  static const _kLanguageKey = 'app_language_v1';

  static Future<List<Transaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTxKey);
    if (raw == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      final list = decoded.map((e) => Transaction.fromJson(e)).toList();
      return processRecurringTransactions(list);
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTransactions(List<Transaction> tx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTxKey, jsonEncode(tx.map((e) => e.toJson()).toList()));
  }

  static List<Transaction> processRecurringTransactions(List<Transaction> list) {
    final now = DateTime.now();
    final updated = List<Transaction>.from(list);
    final recurringItems = list.where((t) => t.isRecurring).toList();

    bool hasNew = false;
    for (final item in recurringItems) {
      final existsThisMonth = list.any((t) =>
          t.title == item.title &&
          t.amount == item.amount &&
          t.category == item.category &&
          t.date.year == now.year &&
          t.date.month == now.month);

      if (!existsThisMonth &&
          (item.date.year < now.year ||
              (item.date.year == now.year && item.date.month < now.month))) {
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final day = item.date.day.clamp(1, daysInMonth);
        final newDate = DateTime(
          now.year,
          now.month,
          day,
          item.date.hour,
          item.date.minute,
        );
        final newTx = Transaction(
          id: '${item.id}_${now.year}_${now.month}',
          title: item.title,
          amount: item.amount,
          category: item.category,
          date: newDate,
          type: item.type,
          note: item.note.isNotEmpty ? '${item.note} (ស្វ័យប្រវត្តិ)' : '(ស្វ័យប្រវត្តិ)',
          isRecurring: true,
          walletId: item.walletId,
        );
        updated.insert(0, newTx);
        hasNew = true;
      }
    }
    if (hasNew) {
      saveTransactions(updated);
    }
    return updated;
  }

  static Future<double> loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kBudgetKey) ?? 0.0;
  }

  static Future<void> saveBudget(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kBudgetKey, v);
  }

  static Future<String> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrencyKey) ?? 'USD';
  }

  static Future<void> saveCurrency(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrencyKey, v);
  }

  static Future<double> loadRate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_kRateKey) ?? 4100.0;
  }

  static Future<void> saveRate(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kRateKey, v);
  }

  // Wallets
  static Future<List<Wallet>> loadWallets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kWalletsKey);
    if (raw == null) return kDefaultWallets;
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      final list = decoded.map((e) => Wallet.fromJson(e)).toList();
      return list.isEmpty ? kDefaultWallets : list;
    } catch (_) {
      return kDefaultWallets;
    }
  }

  static Future<void> saveWallets(List<Wallet> wallets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kWalletsKey,
      jsonEncode(wallets.map((e) => e.toJson()).toList()),
    );
  }

  // Custom Categories
  static Future<List<Category>> loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCustomCategoriesKey);
    if (raw == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => Category.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCustomCategories(List<Category> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCustomCategoriesKey,
      jsonEncode(categories.map((e) => e.toJson()).toList()),
    );
  }



  // Category Budgets
  static Future<Map<String, double>> loadCategoryBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCategoryBudgetsKey);
    if (raw == null) return {};
    try {
      final Map<String, dynamic> decoded = jsonDecode(raw);
      return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveCategoryBudgets(Map<String, double> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCategoryBudgetsKey, jsonEncode(budgets));
  }

  // Saving Goals
  static Future<List<SavingGoal>> loadSavingGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSavingGoalsKey);
    if (raw == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => SavingGoal.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSavingGoals(List<SavingGoal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kSavingGoalsKey,
      jsonEncode(goals.map((e) => e.toJson()).toList()),
    );
  }

  // Debts & Loans
  static Future<List<DebtLoan>> loadDebts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDebtsKey);
    if (raw == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => DebtLoan.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDebts(List<DebtLoan> debts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kDebtsKey,
      jsonEncode(debts.map((e) => e.toJson()).toList()),
    );
  }

  // App Language ('km' or 'en')
  static Future<String> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLanguageKey) ?? 'km';
  }

  static Future<void> saveLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, langCode);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTxKey);
    await prefs.remove(_kBudgetKey);
    await prefs.remove(_kWalletsKey);
    await prefs.remove(_kCustomCategoriesKey);
    await prefs.remove(_kCategoryBudgetsKey);
    await prefs.remove(_kSavingGoalsKey);
    await prefs.remove(_kDebtsKey);
  }
}
