import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/debt_loan.dart';
import '../models/saving_goal.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';

/// StorageService provides robust, atomic persistence with dual-checkpoint
/// backups and corruption self-healing to prevent data loss across all platforms
/// (Web, Android, iOS, Windows, macOS).
class StorageService {
  // Primary Keys
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

  // Backup & Self-Healing Checkpoint Keys
  static const _kTxBackupKey = 'transactions_v2_bak';
  static const _kBudgetBackupKey = 'monthly_budget_v1_bak';
  static const _kWalletsBackupKey = 'wallets_v1_bak';
  static const _kCustomCategoriesBackupKey = 'custom_categories_v1_bak';
  static const _kCategoryBudgetsBackupKey = 'category_budgets_v1_bak';
  static const _kSavingGoalsBackupKey = 'saving_goals_v1_bak';
  static const _kDebtsBackupKey = 'debts_v1_bak';
  static const _kRateBackupKey = 'exchange_rate_v1_bak';
  static const _kCurrencyBackupKey = 'currency_v1_bak';
  static const _kStorageHealthMetaKey = 'storage_health_meta_v1';

  // ---------------------------------------------------------------------------
  // Internal Atomic Engine & Self-Healing Helpers
  // ---------------------------------------------------------------------------

  /// Safely reads and decodes a list from primary storage.
  /// If the primary storage is corrupted or unparseable, it automatically recovers
  /// healthy data from the backup checkpoint and self-heals the primary key.
  static Future<List<T>> _safeLoadList<T>({
    required SharedPreferences prefs,
    required String primaryKey,
    required String backupKey,
    required T Function(Map<String, dynamic>) fromJson,
    List<T> fallbackDefault = const [],
  }) async {
    // 1. Attempt reading from Primary
    final rawPrimary = prefs.getString(primaryKey);
    if (rawPrimary != null && rawPrimary.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPrimary);
        if (decoded is List) {
          final items = <T>[];
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              items.add(fromJson(item));
            } else if (item is Map) {
              items.add(fromJson(Map<String, dynamic>.from(item)));
            }
          }
          // Mirror to backup snapshot if backup is missing
          if (!prefs.containsKey(backupKey) && items.isNotEmpty) {
            await prefs.setString(backupKey, rawPrimary);
          }
          return items;
        }
      } catch (_) {
        // Primary JSON corrupted or format changed. Proceed to backup recovery.
      }
    }

    // 2. Auto-Recovery from Backup Snapshot
    final rawBackup = prefs.getString(backupKey);
    if (rawBackup != null && rawBackup.trim().isNotEmpty) {
      try {
        final decodedBak = jsonDecode(rawBackup);
        if (decodedBak is List) {
          final items = <T>[];
          for (final item in decodedBak) {
            if (item is Map<String, dynamic>) {
              items.add(fromJson(item));
            } else if (item is Map) {
              items.add(fromJson(Map<String, dynamic>.from(item)));
            }
          }
          // Self-heal: rewrite healthy backup data to restore primary key!
          await prefs.setString(primaryKey, rawBackup);
          return items;
        }
      } catch (_) {
        // Backup also corrupted or unparseable
      }
    }

    return fallbackDefault;
  }

  /// Atomically commits a list to disk with validation and dual checkpoints:
  /// 1. Validates JSON serialization and deserialization in memory before disk write.
  /// 2. If existing primary has valid non-empty data and the new list is empty,
  ///    preserves the backup checkpoint to avoid accidental wipeout.
  /// 3. Backs up prior healthy primary state before writing new state.
  /// 4. Mirrors verified state to backup key upon successful primary write.
  static Future<bool> _atomicSaveList({
    required SharedPreferences prefs,
    required String primaryKey,
    required String backupKey,
    required List<Map<String, dynamic>> items,
    bool preserveBackupOnEmpty = true,
  }) async {
    try {
      final encoded = jsonEncode(items);
      // In-memory verification
      final testDecoded = jsonDecode(encoded);
      if (testDecoded is! List) return false;

      // Wipeout Protection:
      // If saving empty list, but previous primary had data,
      // preserve the existing healthy backup snapshot!
      if (items.isEmpty && preserveBackupOnEmpty) {
        final existingPrimary = prefs.getString(primaryKey);
        if (existingPrimary != null && existingPrimary.length > 2) {
          await prefs.setString(backupKey, existingPrimary);
        }
        return await prefs.setString(primaryKey, encoded);
      }

      // Non-empty list:
      // First update backup with current primary (if valid)
      final existingPrimary = prefs.getString(primaryKey);
      if (existingPrimary != null && existingPrimary.isNotEmpty) {
        await prefs.setString(backupKey, existingPrimary);
      }

      // Write to primary
      final primaryOk = await prefs.setString(primaryKey, encoded);
      if (primaryOk) {
        // Mirror latest verified state to backup
        await prefs.setString(backupKey, encoded);
      }
      return primaryOk;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------------

  static Future<List<Transaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _safeLoadList<Transaction>(
      prefs: prefs,
      primaryKey: _kTxKey,
      backupKey: _kTxBackupKey,
      fromJson: (json) => Transaction.fromJson(json),
      fallbackDefault: const [],
    );
    return processRecurringTransactions(list);
  }

  static Future<void> saveTransactions(List<Transaction> tx) async {
    final prefs = await SharedPreferences.getInstance();
    await _atomicSaveList(
      prefs: prefs,
      primaryKey: _kTxKey,
      backupKey: _kTxBackupKey,
      items: tx.map((e) => e.toJson()).toList(),
    );
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
          originalCurrency: item.originalCurrency,
          originalAmount: item.originalAmount,
          exchangeRate: item.exchangeRate,
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

  // ---------------------------------------------------------------------------
  // Budget & Currency Settings
  // ---------------------------------------------------------------------------

  static Future<double> loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getDouble(_kBudgetKey);
    if (val != null) {
      if (!prefs.containsKey(_kBudgetBackupKey)) {
        await prefs.setDouble(_kBudgetBackupKey, val);
      }
      return val;
    }
    return prefs.getDouble(_kBudgetBackupKey) ?? 0.0;
  }

  static Future<void> saveBudget(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kBudgetKey, v);
    await prefs.setDouble(_kBudgetBackupKey, v);
  }

  static Future<String> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final cur = prefs.getString(_kCurrencyKey);
    if (cur != null) {
      if (!prefs.containsKey(_kCurrencyBackupKey)) {
        await prefs.setString(_kCurrencyBackupKey, cur);
      }
      return cur;
    }
    return prefs.getString(_kCurrencyBackupKey) ?? 'USD';
  }

  static Future<void> saveCurrency(String v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrencyKey, v);
    await prefs.setString(_kCurrencyBackupKey, v);
  }

  static Future<double> loadRate() async {
    final prefs = await SharedPreferences.getInstance();
    final rate = prefs.getDouble(_kRateKey);
    if (rate != null) {
      if (!prefs.containsKey(_kRateBackupKey)) {
        await prefs.setDouble(_kRateBackupKey, rate);
      }
      return rate;
    }
    return prefs.getDouble(_kRateBackupKey) ?? 4100.0;
  }

  static Future<void> saveRate(double v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kRateKey, v);
    await prefs.setDouble(_kRateBackupKey, v);
  }

  // ---------------------------------------------------------------------------
  // Wallets
  // ---------------------------------------------------------------------------

  static Future<List<Wallet>> loadWallets() async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _safeLoadList<Wallet>(
      prefs: prefs,
      primaryKey: _kWalletsKey,
      backupKey: _kWalletsBackupKey,
      fromJson: (json) => Wallet.fromJson(json),
      fallbackDefault: kDefaultWallets,
    );
    return list.isEmpty ? kDefaultWallets : list;
  }

  static Future<void> saveWallets(List<Wallet> wallets) async {
    final prefs = await SharedPreferences.getInstance();
    await _atomicSaveList(
      prefs: prefs,
      primaryKey: _kWalletsKey,
      backupKey: _kWalletsBackupKey,
      items: wallets.map((e) => e.toJson()).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Custom Categories
  // ---------------------------------------------------------------------------

  static Future<List<Category>> loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return _safeLoadList<Category>(
      prefs: prefs,
      primaryKey: _kCustomCategoriesKey,
      backupKey: _kCustomCategoriesBackupKey,
      fromJson: (json) => Category.fromJson(json),
      fallbackDefault: const [],
    );
  }

  static Future<void> saveCustomCategories(List<Category> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await _atomicSaveList(
      prefs: prefs,
      primaryKey: _kCustomCategoriesKey,
      backupKey: _kCustomCategoriesBackupKey,
      items: categories.map((e) => e.toJson()).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Category Budgets
  // ---------------------------------------------------------------------------

  static Future<Map<String, double>> loadCategoryBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    // 1. Try primary
    final rawPrimary = prefs.getString(_kCategoryBudgetsKey);
    if (rawPrimary != null && rawPrimary.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPrimary);
        if (decoded is Map) {
          final map = decoded.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
          if (!prefs.containsKey(_kCategoryBudgetsBackupKey) && map.isNotEmpty) {
            await prefs.setString(_kCategoryBudgetsBackupKey, rawPrimary);
          }
          return map;
        }
      } catch (_) {}
    }

    // 2. Auto-Recovery from backup
    final rawBackup = prefs.getString(_kCategoryBudgetsBackupKey);
    if (rawBackup != null && rawBackup.trim().isNotEmpty) {
      try {
        final decodedBak = jsonDecode(rawBackup);
        if (decodedBak is Map) {
          final map = decodedBak.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
          await prefs.setString(_kCategoryBudgetsKey, rawBackup); // Self-healing
          return map;
        }
      } catch (_) {}
    }

    return {};
  }

  static Future<void> saveCategoryBudgets(Map<String, double> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final encoded = jsonEncode(budgets);
      final test = jsonDecode(encoded);
      if (test is Map) {
        final existing = prefs.getString(_kCategoryBudgetsKey);
        if (existing != null && existing.isNotEmpty) {
          await prefs.setString(_kCategoryBudgetsBackupKey, existing);
        }
        final ok = await prefs.setString(_kCategoryBudgetsKey, encoded);
        if (ok && budgets.isNotEmpty) {
          await prefs.setString(_kCategoryBudgetsBackupKey, encoded);
        }
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Saving Goals
  // ---------------------------------------------------------------------------

  static Future<List<SavingGoal>> loadSavingGoals() async {
    final prefs = await SharedPreferences.getInstance();
    return _safeLoadList<SavingGoal>(
      prefs: prefs,
      primaryKey: _kSavingGoalsKey,
      backupKey: _kSavingGoalsBackupKey,
      fromJson: (json) => SavingGoal.fromJson(json),
      fallbackDefault: const [],
    );
  }

  static Future<void> saveSavingGoals(List<SavingGoal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await _atomicSaveList(
      prefs: prefs,
      primaryKey: _kSavingGoalsKey,
      backupKey: _kSavingGoalsBackupKey,
      items: goals.map((e) => e.toJson()).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Debts & Loans
  // ---------------------------------------------------------------------------

  static Future<List<DebtLoan>> loadDebts() async {
    final prefs = await SharedPreferences.getInstance();
    return _safeLoadList<DebtLoan>(
      prefs: prefs,
      primaryKey: _kDebtsKey,
      backupKey: _kDebtsBackupKey,
      fromJson: (json) => DebtLoan.fromJson(json),
      fallbackDefault: const [],
    );
  }

  static Future<void> saveDebts(List<DebtLoan> debts) async {
    final prefs = await SharedPreferences.getInstance();
    await _atomicSaveList(
      prefs: prefs,
      primaryKey: _kDebtsKey,
      backupKey: _kDebtsBackupKey,
      items: debts.map((e) => e.toJson()).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // App Language
  // ---------------------------------------------------------------------------

  static Future<String> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLanguageKey) ?? 'km';
  }

  static Future<void> saveLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, langCode);
  }

  // ---------------------------------------------------------------------------
  // Diagnostics & Manual Restore
  // ---------------------------------------------------------------------------

  /// Checks if valid backup checkpoints exist in storage
  static Future<bool> hasInternalBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kTxBackupKey) ||
        prefs.containsKey(_kWalletsBackupKey) ||
        prefs.containsKey(_kSavingGoalsBackupKey) ||
        prefs.containsKey(_kDebtsBackupKey);
  }

  /// Manually triggers a restore from internal backup checkpoints
  static Future<bool> restoreFromInternalBackup() async {
    final prefs = await SharedPreferences.getInstance();
    bool restoredAny = false;

    for (final pair in [
      [_kTxBackupKey, _kTxKey],
      [_kWalletsBackupKey, _kWalletsKey],
      [_kCustomCategoriesBackupKey, _kCustomCategoriesKey],
      [_kCategoryBudgetsBackupKey, _kCategoryBudgetsKey],
      [_kSavingGoalsBackupKey, _kSavingGoalsKey],
      [_kDebtsBackupKey, _kDebtsKey],
      [_kBudgetBackupKey, _kBudgetKey],
      [_kRateBackupKey, _kRateKey],
      [_kCurrencyBackupKey, _kCurrencyKey],
    ]) {
      final bak = prefs.getString(pair[0]);
      if (bak != null && bak.isNotEmpty) {
        await prefs.setString(pair[1], bak);
        restoredAny = true;
      }
    }
    return restoredAny;
  }

  // ---------------------------------------------------------------------------
  // Clean Data Reset
  // ---------------------------------------------------------------------------

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    // Primary keys
    await prefs.remove(_kTxKey);
    await prefs.remove(_kBudgetKey);
    await prefs.remove(_kWalletsKey);
    await prefs.remove(_kCustomCategoriesKey);
    await prefs.remove(_kCategoryBudgetsKey);
    await prefs.remove(_kSavingGoalsKey);
    await prefs.remove(_kDebtsKey);

    // Backup keys
    await prefs.remove(_kTxBackupKey);
    await prefs.remove(_kBudgetBackupKey);
    await prefs.remove(_kWalletsBackupKey);
    await prefs.remove(_kCustomCategoriesBackupKey);
    await prefs.remove(_kCategoryBudgetsBackupKey);
    await prefs.remove(_kSavingGoalsBackupKey);
    await prefs.remove(_kDebtsBackupKey);
    await prefs.remove(_kRateBackupKey);
    await prefs.remove(_kCurrencyBackupKey);
    await prefs.remove(_kStorageHealthMetaKey);
  }
}
