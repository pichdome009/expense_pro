import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/category.dart';
import '../models/debt_loan.dart';
import '../models/saving_goal.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import 'storage_service.dart';

class BackupData {
  final int version;
  final String exportedAt;
  final List<Transaction> transactions;
  final List<Wallet> wallets;
  final List<Category> customCategories;
  final Map<String, double> categoryBudgets;
  final List<SavingGoal> savingsGoals;
  final List<DebtLoan> debts;
  final double monthlyBudget;
  final String currency;
  final double rate;

  BackupData({
    this.version = 1,
    required this.exportedAt,
    required this.transactions,
    required this.wallets,
    required this.customCategories,
    required this.categoryBudgets,
    this.savingsGoals = const [],
    this.debts = const [],
    required this.monthlyBudget,
    required this.currency,
    required this.rate,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'app': 'Expense Pro',
        'exportedAt': exportedAt,
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'wallets': wallets.map((w) => w.toJson()).toList(),
        'customCategories': customCategories.map((c) => c.toJson()).toList(),
        'categoryBudgets': categoryBudgets,
        'savingsGoals': savingsGoals.map((g) => g.toJson()).toList(),
        'debts': debts.map((d) => d.toJson()).toList(),
        'monthlyBudget': monthlyBudget,
        'currency': currency,
        'rate': rate,
      };

  factory BackupData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> txRaw = json['transactions'] ?? [];
    final List<dynamic> walletsRaw = json['wallets'] ?? [];
    final List<dynamic> customCatsRaw = json['customCategories'] ?? [];
    final Map<String, dynamic> budgetsRaw = json['categoryBudgets'] ?? {};
    final List<dynamic> savingsRaw = json['savingsGoals'] ?? [];
    final List<dynamic> debtsRaw = json['debts'] ?? [];

    return BackupData(
      version: json['version'] ?? 1,
      exportedAt: json['exportedAt'] ?? DateTime.now().toIso8601String(),
      transactions: txRaw.map((e) => Transaction.fromJson(e)).toList(),
      wallets: walletsRaw.map((e) => Wallet.fromJson(e)).toList(),
      customCategories: customCatsRaw.map((e) => Category.fromJson(e)).toList(),
      categoryBudgets: budgetsRaw.map((k, v) => MapEntry(k, (v as num).toDouble())),
      savingsGoals: savingsRaw.map((e) => SavingGoal.fromJson(e as Map<String, dynamic>)).toList(),
      debts: debtsRaw.map((e) => DebtLoan.fromJson(e as Map<String, dynamic>)).toList(),
      monthlyBudget: (json['monthlyBudget'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'USD',
      rate: (json['rate'] as num?)?.toDouble() ?? 4100.0,
    );
  }
}

class BackupService {
  /// Generate the full backup data object from current storage state
  static Future<BackupData> createBackupData() async {
    final tx = await StorageService.loadTransactions();
    final wallets = await StorageService.loadWallets();
    final customCats = await StorageService.loadCustomCategories();
    final categoryBudgets = await StorageService.loadCategoryBudgets();
    final savings = await StorageService.loadSavingGoals();
    final debts = await StorageService.loadDebts();
    final budget = await StorageService.loadBudget();
    final currency = await StorageService.loadCurrency();
    final rate = await StorageService.loadRate();

    return BackupData(
      exportedAt: DateTime.now().toIso8601String(),
      transactions: tx,
      wallets: wallets,
      customCategories: customCats,
      categoryBudgets: categoryBudgets,
      savingsGoals: savings,
      debts: debts,
      monthlyBudget: budget,
      currency: currency,
      rate: rate,
    );
  }

  /// Exports backup to a JSON string
  static Future<String> generateBackupJson() async {
    final data = await createBackupData();
    return const JsonEncoder.withIndent('  ').convert(data.toJson());
  }

  /// Exports backup to a physical file and opens the system Share sheet
  /// (allowing save to Google Drive, Files, Telegram, etc.)
  static Future<void> shareBackupFile() async {
    final jsonStr = await generateBackupJson();
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${tempDir.path}/expense_pro_backup_$timestamp.json';
    final file = File(filePath);
    await file.writeAsString(jsonStr, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: 'Expense Pro Backup ($timestamp)',
        text: 'ទិន្នន័យបម្រុងទុក Expense Pro Backup JSON',
      ),
    );
  }

  /// Parses and validates a JSON backup string
  static BackupData parseBackupJson(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('ទម្រង់ឯកសារមិនត្រឹមត្រូវ');
    }
    if (!decoded.containsKey('transactions') && !decoded.containsKey('wallets')) {
      throw const FormatException('ឯកសារនេះមិនមែនជាទិន្នន័យ Expense Pro ឡើយ');
    }
    return BackupData.fromJson(decoded);
  }

  /// Restores imported backup data into local storage
  static Future<void> restoreFromBackup(BackupData data) async {
    await StorageService.saveTransactions(data.transactions);
    await StorageService.saveWallets(data.wallets);
    await StorageService.saveCustomCategories(data.customCategories);
    await StorageService.saveCategoryBudgets(data.categoryBudgets);
    await StorageService.saveBudget(data.monthlyBudget);
    await StorageService.saveCurrency(data.currency);
    await StorageService.saveRate(data.rate);
    await StorageService.saveSavingGoals(data.savingsGoals);
    await StorageService.saveDebts(data.debts);
  }
}
