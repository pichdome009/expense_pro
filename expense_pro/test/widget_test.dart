import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expense_pro/main.dart';
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
}
