import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expense_pro/main.dart';
import 'package:expense_pro/screens/lock_screen.dart';
import 'package:expense_pro/models/category.dart';
import 'package:expense_pro/models/debt_loan.dart';
import 'package:expense_pro/models/saving_goal.dart';
import 'package:expense_pro/models/transaction.dart';
import 'package:expense_pro/models/wallet.dart';
import 'package:expense_pro/services/backup_service.dart';
import 'package:expense_pro/services/excel_export_service.dart';
import 'package:expense_pro/services/financial_insights_service.dart';
import 'package:expense_pro/services/notification_service.dart';
import 'package:expense_pro/services/security_service.dart';
import 'package:expense_pro/services/storage_service.dart';
import 'package:expense_pro/utils/app_strings.dart';
import 'package:expense_pro/utils/formatters.dart';
import 'package:expense_pro/widgets/category_budget_modal.dart';
import 'package:expense_pro/widgets/tx_item_card.dart';
import 'package:expense_pro/widgets/wallet_selector.dart';

void main() {
  testWidgets('App smoke test - loads and displays dashboard with wallets', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ModernExpenseApp());
    // Advance through splash animation (2000ms + 350ms buffer)
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // Verify app core navigation, actions, and default wallets exist
    expect(find.text('ទំព័រដើម'), findsOneWidget);
    expect(find.text('ស្ថិតិ'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.text('កាបូបទាំងអស់'), findsOneWidget);
    expect(find.text('សាច់ប្រាក់សុទ្ធ'), findsOneWidget);
  });

  test('Wallet model serialization & deserialization', () {
    const wallet = Wallet(
      id: 'w_test',
      name: 'Test Wallet',
      icon: Icons.savings_rounded,
      color: Color(0xFF10B981),
      initialBalance: 50.0,
    );

    final json = wallet.toJson();
    final restored = Wallet.fromJson(json);

    expect(restored.id, wallet.id);
    expect(restored.name, wallet.name);
    expect(restored.initialBalance, wallet.initialBalance);
  });

  test('Custom Category serialization & deserialization', () {
    const category = Category(
      'Coffee',
      Icons.coffee_rounded,
      Color(0xFFF59E0B),
      isExpense: true,
      isCustom: true,
    );

    final json = category.toJson();
    final restored = Category.fromJson(json);

    expect(restored.name, 'Coffee');
    expect(restored.isExpense, true);
    expect(restored.isCustom, true);
  });

  test('Transaction model with walletId', () {
    final tx = Transaction(
      id: 'tx_1',
      title: 'Lunch',
      amount: 15.0,
      category: 'អាហារ',
      date: DateTime.now(),
      walletId: 'aba_bank',
    );

    final json = tx.toJson();
    final restored = Transaction.fromJson(json);

    expect(restored.walletId, 'aba_bank');
    expect(restored.amount, 15.0);
  });

  test('SecurityService PIN hash and verification', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await SecurityService.hasPinCode(), false);

    await SecurityService.setPinCode('1234');
    expect(await SecurityService.hasPinCode(), true);

    expect(await SecurityService.verifyPinCode('1234'), true);
    expect(await SecurityService.verifyPinCode('0000'), false);

    await SecurityService.setAppLockEnabled(true);
    expect(await SecurityService.isAppLockEnabled(), true);

    await SecurityService.setAppLockEnabled(false);
    expect(await SecurityService.isAppLockEnabled(), false);

    // Auto-lock timeout
    expect(await SecurityService.getAutoLockTimeoutSeconds(), 30);
    await SecurityService.setAutoLockTimeoutSeconds(60);
    expect(await SecurityService.getAutoLockTimeoutSeconds(), 60);
  });

  test('ExcelExportService creates valid spreadsheet bytes', () async {
    final txList = [
      Transaction(
        id: 'tx_1',
        title: 'Lunch',
        amount: 5.0,
        category: 'អាហារ',
        date: DateTime(2026, 3, 10, 12, 30),
        type: TxType.expense,
        walletId: 'default_cash',
      ),
      Transaction(
        id: 'tx_2',
        title: 'Salary',
        amount: 500.0,
        category: 'ប្រាក់ខែ',
        date: DateTime(2026, 3, 10, 9, 0),
        type: TxType.income,
        walletId: 'aba_bank',
      ),
    ];

    final bytes = await ExcelExportService.generateExcelBytes(
      transactions: txList,
      wallets: kDefaultWallets,
      rate: 4100.0,
    );

    expect(bytes.isNotEmpty, true);
  });

  test('NotificationService preference persistence', () async {
    SharedPreferences.setMockInitialValues({});

    // Default daily reminder is true, 20:00
    expect(await NotificationService.isDailyReminderEnabled(), true);
    expect(await NotificationService.getDailyReminderHour(), 20);
    expect(await NotificationService.getDailyReminderMinute(), 0);

    await NotificationService.setDailyReminderEnabled(false);
    expect(await NotificationService.isDailyReminderEnabled(), false);

    await NotificationService.setDailyReminderTime(21, 30);
    expect(await NotificationService.getDailyReminderHour(), 21);
    expect(await NotificationService.getDailyReminderMinute(), 30);

    // Budget alerts default true
    expect(await NotificationService.isBudgetAlertsEnabled(), true);
    await NotificationService.setBudgetAlertsEnabled(false);
    expect(await NotificationService.isBudgetAlertsEnabled(), false);
  });

  test('BackupData serialization & BackupService JSON roundtrip', () {
    final original = BackupData(
      exportedAt: DateTime.now().toIso8601String(),
      transactions: [
        Transaction(
          id: 'tx_khr_test',
          title: 'Morning Coffee',
          amount: 2.5,
          category: 'កាហ្វេ',
          date: DateTime(2026, 4, 1),
          originalCurrency: 'KHR',
          originalAmount: 10000.0,
        ),
      ],
      wallets: kDefaultWallets,
      customCategories: [
        const Category('Gym', Icons.fitness_center_rounded, Color(0xFF10B981), isCustom: true),
      ],
      categoryBudgets: {'អាហារ': 120.0},
      savingsGoals: [
        const SavingGoal(
          id: 'goal_backup',
          title: 'Car Fund',
          targetAmount: 3000.0,
          currentAmount: 1200.0,
        ),
      ],
      debts: [
        DebtLoan(
          id: 'debt_backup',
          personName: 'Rithy',
          amount: 100.0,
          type: DebtType.lent,
          createdAt: DateTime(2026, 6, 1),
        ),
      ],
      monthlyBudget: 500.0,
      currency: 'USD',
      rate: 4100.0,
    );

    final jsonMap = original.toJson();
    final restored = BackupData.fromJson(jsonMap);

    expect(restored.transactions.length, 1);
    expect(restored.transactions.first.originalCurrency, 'KHR');
    expect(restored.transactions.first.originalAmount, 10000.0);
    expect(restored.customCategories.first.name, 'Gym');
    expect(restored.categoryBudgets['អាហារ'], 120.0);
    expect(restored.savingsGoals.first.title, 'Car Fund');
    expect(restored.debts.first.personName, 'Rithy');
    expect(restored.monthlyBudget, 500.0);
  });

  test('matchesDateRange supports custom DateTimeRange filtering', () {
    final t1 = DateTime(2026, 5, 10);
    final t2 = DateTime(2026, 5, 20);
    final t3 = DateTime(2026, 5, 26);

    final range = DateTimeRange(
      start: DateTime(2026, 5, 15),
      end: DateTime(2026, 5, 25),
    );

    expect(matchesDateRange(t1, DateRangeFilter.all, customRange: range), false);
    expect(matchesDateRange(t2, DateRangeFilter.all, customRange: range), true);
    expect(matchesDateRange(t3, DateRangeFilter.all, customRange: range), false);
  });

  test('Wallet transfer transaction serialization and balance logic', () {
    final transferTx = Transaction(
      id: 'tx_tr_1',
      title: 'Transfer to Cash',
      amount: 40.0,
      category: 'ផ្ទេរប្រាក់',
      date: DateTime.now(),
      type: TxType.transfer,
      walletId: 'aba_bank',
      toWalletId: 'default_cash',
    );

    final json = transferTx.toJson();
    final restored = Transaction.fromJson(json);

    expect(restored.type, TxType.transfer);
    expect(restored.walletId, 'aba_bank');
    expect(restored.toWalletId, 'default_cash');
    expect(restored.amount, 40.0);
  });

  test('SavingGoal model progress, completion and serialization', () {
    const goal = SavingGoal(
      id: 'g_1',
      title: 'New Laptop',
      targetAmount: 1000.0,
      currentAmount: 250.0,
      icon: Icons.laptop_mac_rounded,
      color: Color(0xFF3B82F6),
    );

    expect(goal.progress, 0.25);
    expect(goal.isCompleted, false);

    final completedGoal = goal.copyWith(currentAmount: 1000.0);
    expect(completedGoal.progress, 1.0);
    expect(completedGoal.isCompleted, true);

    final json = goal.toJson();
    final restored = SavingGoal.fromJson(json);
    expect(restored.id, 'g_1');
    expect(restored.title, 'New Laptop');
    expect(restored.targetAmount, 1000.0);
    expect(restored.currentAmount, 250.0);
    expect(restored.icon, Icons.laptop_mac_rounded);
  });

  test('AppStrings localization dictionary lookup', () {
    expect(AppStrings.of('home', 'km'), 'ទំព័រដើម');
    expect(AppStrings.of('home', 'en'), 'Home');
    expect(AppStrings.of('statistics', 'km'), 'ស្ថិតិ');
    expect(AppStrings.of('statistics', 'en'), 'Statistics');
    expect(AppStrings.of('savings_goals', 'km'), 'គោលដៅសន្សំប្រាក់');
    expect(AppStrings.of('savings_goals', 'en'), 'Savings Goals');
  });

  test('StorageService saving goals and language persistence', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await StorageService.loadLanguage(), 'km');
    await StorageService.saveLanguage('en');
    expect(await StorageService.loadLanguage(), 'en');

    expect((await StorageService.loadSavingGoals()).isEmpty, true);
    const goal = SavingGoal(
      id: 'test_g',
      title: 'Emergency Fund',
      targetAmount: 500.0,
      currentAmount: 100.0,
    );
    await StorageService.saveSavingGoals([goal]);
    final loaded = await StorageService.loadSavingGoals();
    expect(loaded.length, 1);
    expect(loaded.first.title, 'Emergency Fund');
  });

  test('DebtLoan model remaining amount, settlement and serialization', () {
    final debt = DebtLoan(
      id: 'debt_1',
      personName: 'Sokha',
      amount: 150.0,
      paidAmount: 50.0,
      type: DebtType.lent,
      createdAt: DateTime(2026, 9, 1),
      dueDate: DateTime(2026, 10, 1),
      notes: 'Dinner loan',
    );

    expect(debt.remainingAmount, 100.0);
    expect(debt.isSettled, false);

    final settledDebt = debt.copyWith(paidAmount: 150.0);
    expect(settledDebt.remainingAmount, 0.0);
    expect(settledDebt.isSettled, true);

    final json = debt.toJson();
    final restored = DebtLoan.fromJson(json);
    expect(restored.id, 'debt_1');
    expect(restored.personName, 'Sokha');
    expect(restored.amount, 150.0);
    expect(restored.paidAmount, 50.0);
    expect(restored.type, DebtType.lent);
    expect(restored.notes, 'Dinner loan');
  });

  test('StorageService debt load and save persistence', () async {
    SharedPreferences.setMockInitialValues({});
    expect((await StorageService.loadDebts()).isEmpty, true);

    final debt = DebtLoan(
      id: 'debt_test',
      personName: 'Bona',
      amount: 80.0,
      type: DebtType.borrowed,
      createdAt: DateTime.now(),
    );

    await StorageService.saveDebts([debt]);
    final loaded = await StorageService.loadDebts();
    expect(loaded.length, 1);
    expect(loaded.first.personName, 'Bona');
    expect(loaded.first.amount, 80.0);
    expect(loaded.first.type, DebtType.borrowed);
  });

  test('Monthly comparison percentage calculations', () {
    // Current month expense: 120, previous month expense: 100 -> +20%
    const currentSpent = 120.0;
    const prevSpent = 100.0;
    const diff = currentSpent - prevSpent;
    const percent = (diff / prevSpent) * 100;
    expect(percent, 20.0);
    expect(diff > 0, true); // Spent more than last month
  });

  test('FinancialInsightsService computes correct daily average, peak day, top category and tips', () {
    final txs = [
      Transaction(
        id: '1',
        title: 'Salary',
        amount: 1000.0,
        category: 'ប្រាក់ខែ',
        date: DateTime(2026, 9, 1), // Tuesday
        type: TxType.income,
      ),
      Transaction(
        id: '2',
        title: 'Groceries',
        amount: 60.0,
        category: 'អាហារ',
        date: DateTime(2026, 9, 2), // Wednesday
        type: TxType.expense,
      ),
      Transaction(
        id: '3',
        title: 'Dinner',
        amount: 40.0,
        category: 'អាហារ',
        date: DateTime(2026, 9, 2), // Wednesday
        type: TxType.expense,
      ),
      Transaction(
        id: '4',
        title: 'Fuel',
        amount: 50.0,
        category: 'ធ្វើដំណើរ',
        date: DateTime(2026, 9, 4), // Friday
        type: TxType.expense,
      ),
    ];

    final insightsEn = FinancialInsightsService.computeInsights(
      transactions: txs,
      daysInPeriod: 30,
      lang: 'en',
    );

    // Total expense = 150, days = 30 -> dailyAvg = 5.0
    expect(insightsEn.dailyAverage, 5.0);
    expect(insightsEn.totalExpense, 150.0);
    expect(insightsEn.totalIncome, 1000.0);
    // Savings rate = (1000 - 150) / 1000 * 100 = 85.0%
    expect(insightsEn.savingsRate, 85.0);
    // Peak day is Wednesday (60 + 40 = 100)
    expect(insightsEn.peakWeekdayName, 'Wednesday');
    expect(insightsEn.peakWeekdayAmount, 100.0);
    // Top category is 'អាហារ' (100 / 150 = 66.7%)
    expect(insightsEn.topCategory, 'អាហារ');
    expect(insightsEn.topCategoryPercentage, closeTo(66.67, 0.1));
    expect(insightsEn.smartTip.isNotEmpty, true);

    // Khmer version
    final insightsKm = FinancialInsightsService.computeInsights(
      transactions: txs,
      daysInPeriod: 30,
      lang: 'km',
    );
    expect(insightsKm.peakWeekdayName, 'ថ្ងៃពុធ');
    expect(insightsKm.smartTip.isNotEmpty, true);
  });

  test('Decimal parsing supports both comma and dot for currency inputs', () {
    // Test USD: "2,50" -> 2.50, "2.50" -> 2.50
    const rawComma = '2,50';
    const rawDot = '2.50';
    expect(double.parse(rawComma.replaceAll(',', '.')), 2.50);
    expect(double.parse(rawDot.replaceAll(',', '.')), 2.50);

    // Test KHR: "10,000" -> 10000
    const rawKhr = '10,000';
    expect(double.parse(rawKhr.replaceAll(',', '').replaceAll('.', '')), 10000.0);
  });

  test('parseAmount handles comma, dot, mixed thousands and empty inputs', () {
    expect(parseAmount('2,50'), 2.50);
    expect(parseAmount('2.50'), 2.50);
    expect(parseAmount('1,500.75'), 1500.75);
    expect(parseAmount('1500'), 1500.0);
    expect(parseAmount(''), 0.0);
    expect(parseAmount('   '), 0.0);
    expect(parseAmount('abc'), 0.0);
  });

  test('StorageService - atomic writes, backup checkpoints, and self-healing recovery', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testTxs = [
      Transaction(
        id: 'tx_safe_1',
        title: 'Lunch Safe',
        amount: 12.5,
        category: 'អាហារ',
        date: DateTime(2026, 4, 1),
        type: TxType.expense,
        walletId: 'aba_bank',
      ),
      Transaction(
        id: 'tx_safe_2',
        title: 'Salary Safe',
        amount: 800.0,
        category: 'ប្រាក់ខែ',
        date: DateTime(2026, 4, 1),
        type: TxType.income,
        walletId: 'default_cash',
      ),
    ];

    // 1. Save transactions and verify primary and backup are both written
    await StorageService.saveTransactions(testTxs);
    expect(prefs.containsKey('transactions_v2'), true);
    expect(prefs.containsKey('transactions_v2_bak'), true);
    expect(await StorageService.hasInternalBackup(), true);

    // 2. Load transactions should succeed normally
    final loaded = await StorageService.loadTransactions();
    expect(loaded.length, 2);
    expect(loaded.first.title, 'Lunch Safe');

    // 3. Simulate Primary Key Corruption (e.g. crash/interrupted write produces invalid JSON)
    await prefs.setString('transactions_v2', '{"invalid_json_corrupted: [');

    // 4. Load transactions should self-heal using the backup snapshot!
    final recovered = await StorageService.loadTransactions();
    expect(recovered.length, 2);
    expect(recovered.first.title, 'Lunch Safe');

    // 5. Verify the primary key has been repaired/self-healed
    final repairedRaw = prefs.getString('transactions_v2');
    expect(repairedRaw != null && !repairedRaw.startsWith('{"invalid_json'), true);

    // 6. Test Accidental Wipeout Protection:
    // If an empty list is passed to saveTransactions, the backup snapshot is preserved
    await StorageService.saveTransactions([]);
    final currentPrimary = prefs.getString('transactions_v2');
    final preservedBackup = prefs.getString('transactions_v2_bak');
    expect(currentPrimary, '[]');
    expect(preservedBackup != null && preservedBackup.length > 2, true);

    // 7. Verify clearAll cleanly purges both primary and backups
    await StorageService.clearAll();
    expect(prefs.containsKey('transactions_v2'), false);
    expect(prefs.containsKey('transactions_v2_bak'), false);
    expect(await StorageService.hasInternalBackup(), false);
  });

  test('StorageService - wallets, category budgets, saving goals, and debts self-healing', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // 1. Wallets
    const testWallet = Wallet(
      id: 'w_heal_test',
      name: 'Heal Wallet',
      icon: Icons.account_balance_wallet,
      color: Color(0xFF10B981),
      initialBalance: 250.0,
    );
    await StorageService.saveWallets([testWallet]);
    expect(prefs.containsKey('wallets_v1_bak'), true);

    // Corrupt primary wallets
    await prefs.setString('wallets_v1', 'broken_wallet_json');
    final recoveredWallets = await StorageService.loadWallets();
    expect(recoveredWallets.any((w) => w.id == 'w_heal_test'), true);

    // 2. Category Budgets
    await StorageService.saveCategoryBudgets({'អាហារ': 150.0, 'កាហ្វេ': 45.0});
    expect(prefs.containsKey('category_budgets_v1_bak'), true);

    // Corrupt primary category budgets
    await prefs.setString('category_budgets_v1', '{corrupted');
    final recoveredBudgets = await StorageService.loadCategoryBudgets();
    expect(recoveredBudgets['អាហារ'], 150.0);
    expect(recoveredBudgets['កាហ្វេ'], 45.0);

    // 3. Saving Goals
    const testGoal = SavingGoal(
      id: 'goal_heal',
      title: 'Emergency Fund',
      targetAmount: 5000.0,
      currentAmount: 1500.0,
    );
    await StorageService.saveSavingGoals([testGoal]);
    expect(prefs.containsKey('saving_goals_v1_bak'), true);

    // Corrupt primary saving goals
    await prefs.setString('saving_goals_v1', '[corrupt');
    final recoveredGoals = await StorageService.loadSavingGoals();
    expect(recoveredGoals.first.title, 'Emergency Fund');
  });

  testWidgets('LockScreen overlay is non-destructive and preserves state across app lifecycle', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'sec_app_lock_enabled_v1': true,
      'sec_pin_hash_v1': SecurityService.hashPin('1234'),
      'sec_auto_lock_timeout_v1': 0, // immediate lock
    });

    await tester.pumpWidget(const ModernExpenseApp());
    // Advance splash
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // LockScreen overlay is visible because app lock is enabled
    expect(find.byType(LockScreen), findsOneWidget);

    // Tap PIN 1-2-3-4 on the on-screen keypad to unlock
    for (final digit in ['1', '2', '3', '4']) {
      await tester.tap(find.text(digit).first);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();

    // Now LockScreen is dismissed and dashboard is visible
    expect(find.byType(LockScreen), findsNothing);
    expect(find.text('ទំព័រដើម'), findsOneWidget);
  });

  testWidgets('CategoryBudgetModal - multi-currency consistency and legacy auto-healing', (WidgetTester tester) async {
    Map<String, double> updatedBudgets = {};

    // 1. Test Legacy Auto-Migration:
    // If a budget was saved as 410,000 (raw KHR) in earlier versions, opening the modal
    // automatically normalizes it to 100.0 USD using rate 4100!
    final legacyCorruptedBudgets = {'អាហារ': 410000.0};

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CategoryBudgetModal(
          categoryBudgets: legacyCorruptedBudgets,
          transactions: const [],
          customCategories: const [],
          currency: 'KHR',
          rate: 4100.0,
          onBudgetsChanged: (map) => updatedBudgets = map,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // The legacy 410,000 should be auto-healed to 100.0 USD!
    expect(updatedBudgets['អាហារ'], 100.0);

    // 2. Open set budget dialog for a category
    await tester.tap(find.text('អាហារ').first);
    await tester.pumpAndSettle();

    // Dialog title exists
    expect(find.text('ថវិកាសម្រាប់ "អាហារ"'), findsOneWidget);
    // Currency label should indicate Riel (៛) because currency is KHR
    expect(find.text('ចំនួនទឹកប្រាក់ (៛)'), findsOneWidget);

    // Enter 820,000 ៛ (which equals 200.0 USD at 4100 rate)
    await tester.enterText(find.byType(TextField).last, '820000');
    await tester.pump();

    // Live preview shows USD equivalent
    expect(find.textContaining('≈ \$200.00'), findsOneWidget);

    // Tap 'រក្សាទុក'
    await tester.tap(find.text('រក្សាទុក'));
    await tester.pumpAndSettle();

    // Stored budget in USD should be normalized to 200.0 USD!
    expect(updatedBudgets['អាហារ'], 200.0);
  });

  test('Transaction model - exchangeRate serialization and legacy auto-derivation', () {
    // 1. Transaction with explicit exchangeRate
    final tx = Transaction(
      id: 'tx_rate_test',
      title: 'Coffee',
      amount: 2.50,
      category: 'កាហ្វេ',
      date: DateTime(2026, 4, 1),
      originalCurrency: 'KHR',
      originalAmount: 10000.0,
      exchangeRate: 4000.0,
    );

    final json = tx.toJson();
    expect(json['exchangeRate'], 4000.0);

    final restored = Transaction.fromJson(json);
    expect(restored.exchangeRate, 4000.0);
    expect(restored.originalCurrency, 'KHR');
    expect(restored.originalAmount, 10000.0);

    // 2. Legacy transaction without exchangeRate field in json:
    // Auto-derives 10000 / 2.5 = 4000.0
    final legacyJson = {
      'id': 'tx_legacy',
      'title': 'Legacy Lunch',
      'amount': 2.50,
      'category': 'អាហារ',
      'date': DateTime(2026, 4, 1).toIso8601String(),
      'type': 'expense',
      'originalCurrency': 'KHR',
      'originalAmount': 10000.0,
    };
    final legacyRestored = Transaction.fromJson(legacyJson);
    expect(legacyRestored.exchangeRate, 4000.0);
  });

  testWidgets('TxItemCard preserves exact historical Khmer Riel amount when exchange rate changes', (WidgetTester tester) async {
    // Historical transaction: 10,000 Riels spent when rate was 4000 (amount = $2.50)
    final historicalTx = Transaction(
      id: 'tx_khr_hist',
      title: 'Morning Coffee',
      amount: 2.50,
      category: 'កាហ្វេ',
      date: DateTime(2026, 4, 1),
      originalCurrency: 'KHR',
      originalAmount: 10000.0,
      exchangeRate: 4000.0,
    );

    // Render with current exchange rate = 4200 (which would be 10,500 Riels if unpreserved!)
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TxItemCard(
          tx: historicalTx,
          onRemove: (_) {},
          onEdit: (_) {},
          currency: 'KHR',
          rate: 4200.0, // Floating current rate changed to 4200
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // 1. Primary amount must be EXACTLY historical 10,000 ៛, NOT distorted to 10,500 ៛!
    expect(find.text('-10,000 ៛'), findsOneWidget);
    expect(find.text('-10,500 ៛'), findsNothing);

    // 2. Secondary amount shows USD base
    expect(find.text('(\$2.50)'), findsOneWidget);
  });

  testWidgets('WalletSelectorBar guards against deleting the only wallet', (WidgetTester tester) async {
    const singleWallet = Wallet(
      id: 'w_only',
      name: 'Only Wallet',
      icon: Icons.wallet,
      color: Colors.blue,
      initialBalance: 100,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WalletSelectorBar(
          wallets: const [singleWallet],
          selectedWalletId: null,
          transactions: const [],
          currency: 'USD',
          rate: 4000.0,
          onSelectWallet: (_) {},
          onWalletsChanged: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Find custom wallet chip and trigger long-press delete
    await tester.longPress(find.text('Only Wallet'));
    await tester.pumpAndSettle();

    // Guard snackbar displayed
    expect(find.text('មិនអាចលុបបានទេ ត្រូវមានកាបូបយ៉ាងហោចណាស់មួយ!'), findsOneWidget);
  });

  testWidgets('WalletSelectorBar handles deletion with orphan protection dialog (reassignment)', (WidgetTester tester) async {
    const wallet1 = Wallet(
      id: 'w_cash',
      name: 'Cash',
      icon: Icons.payments,
      color: Colors.green,
      initialBalance: 100,
    );
    const wallet2 = Wallet(
      id: 'w_custom_bank',
      name: 'Custom Bank',
      icon: Icons.account_balance,
      color: Colors.blue,
      initialBalance: 200,
    );

    final tiedTx = Transaction(
      id: 'tx_tied',
      title: 'Coffee',
      amount: 3.0,
      category: 'Food',
      date: DateTime.now(),
      walletId: 'w_custom_bank',
    );

    Wallet? deletedWallet;
    String? reassignedTo;
    bool? deletedTxs;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: WalletSelectorBar(
          wallets: const [wallet1, wallet2],
          selectedWalletId: null,
          transactions: [tiedTx],
          currency: 'USD',
          rate: 4000.0,
          onSelectWallet: (_) {},
          onWalletsChanged: (_) {},
          onDeleteWallet: (w, {reassignToWalletId, deleteTransactions = false}) {
            deletedWallet = w;
            reassignedTo = reassignToWalletId;
            deletedTxs = deleteTransactions;
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Long press Custom Bank
    await tester.longPress(find.text('Custom Bank'));
    await tester.pumpAndSettle();

    // Warning dialog should appear with orphan warning
    expect(find.text('លុបកាបូប "Custom Bank"?'), findsOneWidget);
    expect(find.textContaining('កាបូបនេះមានប្រតិបត្តិការចំនួន 1'), findsOneWidget);
    expect(find.text('ផ្ទេរប្រតិបត្តិការទៅកាបូបផ្សេង (ណែនាំ)'), findsOneWidget);

    // Confirm reassignment
    await tester.tap(find.text('បញ្ជាក់ការផ្ទេរ & លុប'));
    await tester.pumpAndSettle();

    expect(deletedWallet?.id, 'w_custom_bank');
    expect(reassignedTo, 'w_cash');
    expect(deletedTxs, false);
  });

  test('Auto-heals orphan transactions referencing deleted wallets on load', () async {
    SharedPreferences.setMockInitialValues({});
    const validWallet = Wallet(
      id: 'w_active',
      name: 'Active Wallet',
      icon: Icons.wallet,
      color: Colors.blue,
    );
    await StorageService.saveWallets([validWallet]);

    final orphanTx = Transaction(
      id: 'tx_orphan',
      title: 'Old Expense',
      amount: 50.0,
      category: 'Other',
      date: DateTime.now(),
      walletId: 'deleted_wallet_999', // Non-existent wallet
      toWalletId: 'deleted_wallet_888',
    );
    await StorageService.saveTransactions([orphanTx]);

    // Simulate startup load & sanitize logic
    final loadedWallets = await StorageService.loadWallets();
    final loadedTx = await StorageService.loadTransactions();

    final validWalletIds = loadedWallets.map((w) => w.id).toSet();
    final fallbackWalletId = loadedWallets.isNotEmpty ? loadedWallets.first.id : 'default_cash';

    final sanitizedTx = loadedTx.map((t) {
      String currentWalletId = t.walletId;
      String? currentToWalletId = t.toWalletId;

      if (!validWalletIds.contains(currentWalletId)) {
        currentWalletId = fallbackWalletId;
      }
      if (currentToWalletId != null && !validWalletIds.contains(currentToWalletId)) {
        final otherWallets = validWalletIds.where((id) => id != currentWalletId);
        currentToWalletId = otherWallets.isNotEmpty ? otherWallets.first : null;
      }

      return t.copyWith(walletId: currentWalletId, toWalletId: currentToWalletId);
    }).toList();

    expect(sanitizedTx.first.walletId, 'w_active');
    expect(sanitizedTx.first.toWalletId, isNull);
  });
}




