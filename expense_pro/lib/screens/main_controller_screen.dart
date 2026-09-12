import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/category.dart';
import '../models/debt_loan.dart';
import '../models/saving_goal.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';
import '../widgets/category_budget_modal.dart';
import '../widgets/category_manager_modal.dart';
import '../widgets/debt_tracker_modal.dart';
import '../widgets/pill_nav_bar.dart';
import '../widgets/savings_modal.dart';
import '../widgets/transaction_modal.dart';
import 'dashboard_view.dart';
import 'settings_sheet.dart';
import 'statistics_view.dart';
import '../widgets/export_modal.dart';

class MainControllerScreen extends StatefulWidget {
  final void Function(bool) onToggleTheme;
  final bool isDark;

  const MainControllerScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  State<MainControllerScreen> createState() => _MainControllerScreenState();
}

class _MainControllerScreenState extends State<MainControllerScreen> {
  int _currentIndex = 0;
  bool _loading = true;

  List<Transaction> _tx = [];
  double _monthlyBudget = 0.0;
  String _currency = 'USD';
  double _rate = 4100.0;

  // Wallets
  List<Wallet> _wallets = kDefaultWallets;
  String? _selectedWalletId;

  // Custom Categories & Budgets
  List<Category> _customCategories = [];
  Map<String, double> _categoryBudgets = {};

  // Savings & Localization
  List<SavingGoal> _savingsGoals = [];
  String _lang = 'km';

  // Debts & Loans
  List<DebtLoan> _debts = [];

  String _searchQuery = '';
  String? _filterCategory;
  DateRangeFilter _dateFilter = DateRangeFilter.month;
  DateTimeRange? _customDateRange;
  SortOption _sort = SortOption.newest;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final tx = await StorageService.loadTransactions();
    final budget = await StorageService.loadBudget();
    final currency = await StorageService.loadCurrency();
    final rate = await StorageService.loadRate();
    final wallets = await StorageService.loadWallets();
    final customCategories = await StorageService.loadCustomCategories();
    final categoryBudgets = await StorageService.loadCategoryBudgets();
    final savingsGoals = await StorageService.loadSavingGoals();
    final debts = await StorageService.loadDebts();
    final lang = await StorageService.loadLanguage();

    if (!mounted) return;
    setState(() {
      _tx = tx;
      _monthlyBudget = budget;
      _currency = currency;
      _rate = rate;
      _wallets = wallets;
      _customCategories = customCategories;
      _categoryBudgets = categoryBudgets;
      _savingsGoals = savingsGoals;
      _debts = debts;
      _lang = lang;
      _loading = false;
    });
  }

  Future<void> _persist() async => StorageService.saveTransactions(_tx);

  void _addTx(Transaction t) {
    if (t.type == TxType.expense) {
      _checkBudgetAlerts(t);
    }
    setState(() => _tx.insert(0, t));
    _persist();
    HapticFeedback.lightImpact();
  }

  void _checkBudgetAlerts(Transaction newTx) {
    final now = DateTime.now();

    // 1. Check Monthly Budget
    if (_monthlyBudget > 0) {
      double prevMonthExpense = 0;
      for (final tx in _tx) {
        if (tx.type == TxType.expense &&
            tx.date.year == now.year &&
            tx.date.month == now.month) {
          prevMonthExpense += tx.amount;
        }
      }
      final newMonthExpense = prevMonthExpense + newTx.amount;
      final prevRatio = prevMonthExpense / _monthlyBudget;
      final newRatio = newMonthExpense / _monthlyBudget;

      if (prevRatio < 1.0 && newRatio >= 1.0) {
        NotificationService.showBudgetAlert(
          id: 2001,
          title: '🚨 លើសកញ្ចប់ថវិកាខែនេះ!',
          body:
              'ការចំណាយខែនេះបានលើស 100% នៃថវិកាហើយ (${formatCurrency(newMonthExpense, _currency, _rate)} / ${formatCurrency(_monthlyBudget, _currency, _rate)})',
        );
      } else if (prevRatio < 0.8 && newRatio >= 0.8) {
        NotificationService.showBudgetAlert(
          id: 2002,
          title: '⚠️ ជិតដល់កម្រិតថវិកា!',
          body:
              'ការចំណាយខែនេះដល់ 80% នៃកញ្ចប់ថវិកាហើយ (${formatCurrency(newMonthExpense, _currency, _rate)} / ${formatCurrency(_monthlyBudget, _currency, _rate)})',
        );
      }
    }

    // 2. Check Category Budget
    final catBudget = _categoryBudgets[newTx.category];
    if (catBudget != null && catBudget > 0) {
      double prevCatExpense = 0;
      for (final tx in _tx) {
        if (tx.type == TxType.expense &&
            tx.category == newTx.category &&
            tx.date.year == now.year &&
            tx.date.month == now.month) {
          prevCatExpense += tx.amount;
        }
      }
      final newCatExpense = prevCatExpense + newTx.amount;
      final prevRatio = prevCatExpense / catBudget;
      final newRatio = newCatExpense / catBudget;

      if (prevRatio < 1.0 && newRatio >= 1.0) {
        NotificationService.showBudgetAlert(
          id: 2003,
          title: '🚨 លើសថវិកាលើ "${newTx.category}"!',
          body: 'ការចំណាយលើ "${newTx.category}" បានលើសកញ្ចប់ថវិកាដែលបានកំណត់!',
        );
      } else if (prevRatio < 0.8 && newRatio >= 0.8) {
        NotificationService.showBudgetAlert(
          id: 2004,
          title: '⚠️ ជិតដល់ 80% លើ "${newTx.category}"!',
          body: 'ការចំណាយលើ "${newTx.category}" បានឈានដល់ 80% នៃថវិកាហើយ!',
        );
      }
    }
  }

  void _updateTx(Transaction t) {
    setState(() {
      final idx = _tx.indexWhere((e) => e.id == t.id);
      if (idx != -1) _tx[idx] = t;
    });
    _persist();
  }

  void _removeTxWithUndo(Transaction t) {
    final idx = _tx.indexWhere((e) => e.id == t.id);
    setState(() => _tx.removeWhere((e) => e.id == t.id));
    _persist();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(_lang == 'km' ? 'បានលុប "${t.title}"' : 'Deleted "${t.title}"'),
        action: SnackBarAction(
          label: _lang == 'km' ? 'មិនធ្វើវិញ' : 'Undo',
          textColor: AppColors.primary,
          onPressed: () {
            setState(() => _tx.insert(idx.clamp(0, _tx.length), t));
            _persist();
          },
        ),
      ),
    );
  }

  Future<void> _setBudget(double v) async {
    setState(() => _monthlyBudget = v);
    await StorageService.saveBudget(v);
  }

  Future<void> _setCurrency(String v) async {
    setState(() => _currency = v);
    await StorageService.saveCurrency(v);
  }

  Future<void> _setRate(double v) async {
    setState(() => _rate = v);
    await StorageService.saveRate(v);
  }

  void _onWalletsChanged(List<Wallet> list) {
    setState(() => _wallets = list);
    StorageService.saveWallets(list);
  }

  void _openCategoryManager() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategoryManagerModal(
        customCategories: _customCategories,
        onCategoriesChanged: (list) {
          setState(() => _customCategories = list);
          StorageService.saveCustomCategories(list);
        },
      ),
    );
  }

  void _openCategoryBudgets() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CategoryBudgetModal(
        categoryBudgets: _categoryBudgets,
        transactions: _tx,
        customCategories: _customCategories,
        currency: _currency,
        rate: _rate,
        onBudgetsChanged: (budgets) {
          setState(() => _categoryBudgets = budgets);
          StorageService.saveCategoryBudgets(budgets);
        },
      ),
    );
  }

  void _onGoalsChanged(List<SavingGoal> list) {
    setState(() => _savingsGoals = list);
    StorageService.saveSavingGoals(list);
  }

  void _openSavingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SavingsManagerModal(
        goals: _savingsGoals,
        currency: _currency,
        rate: _rate,
        onGoalsChanged: _onGoalsChanged,
        lang: _lang,
      ),
    );
  }

  void _onDebtsChanged(List<DebtLoan> list) {
    setState(() => _debts = list);
    StorageService.saveDebts(list);
  }

  void _openDebtTracker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DebtTrackerModal(
        debts: _debts,
        currency: _currency,
        rate: _rate,
        onDebtsChanged: _onDebtsChanged,
        lang: _lang,
      ),
    );
  }

  Future<void> _setLanguage(String lang) async {
    setState(() => _lang = lang);
    await StorageService.saveLanguage(lang);
  }

  Future<void> _clearAllData() async {
    setState(() {
      _tx = [];
      _monthlyBudget = 0.0;
      _categoryBudgets = {};
      _customCategories = [];
      _wallets = kDefaultWallets;
      _selectedWalletId = null;
      _savingsGoals = [];
      _debts = [];
      _lang = 'km';
    });
    await StorageService.clearAll();
  }

  void _openTxModal({Transaction? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionModal(
        onAdd: _addTx,
        onUpdate: _updateTx,
        editing: editing,
        wallets: _wallets,
        customCategories: _customCategories,
        currency: _currency,
        rate: _rate,
        lang: _lang,
      ),
    );
  }

  void _openExportModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ExportModal(
        transactions: _tx,
        wallets: _wallets,
        currency: _currency,
        rate: _rate,
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SettingsSheet(
        isDark: widget.isDark,
        onToggleTheme: widget.onToggleTheme,
        currency: _currency,
        rate: _rate,
        monthlyBudget: _monthlyBudget,
        onSetCurrency: _setCurrency,
        onSetRate: _setRate,
        onSetBudget: _setBudget,
        onOpenCategoryManager: _openCategoryManager,
        onOpenCategoryBudgets: _openCategoryBudgets,
        onOpenSavingsGoals: _openSavingsModal,
        onOpenDebtTracker: _openDebtTracker,
        lang: _lang,
        onSetLanguage: _setLanguage,
        onDataRestored: _loadAll,
        onExport: () {
          Navigator.pop(ctx);
          _openExportModal();
        },
        onClearAll: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dctx) => AlertDialog(
              title: Text(_lang == 'km' ? 'លុបទិន្នន័យទាំងអស់?' : 'Clear all data?'),
              content: Text(
                _lang == 'km'
                    ? 'សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។'
                    : 'This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dctx, false),
                  child: Text(_lang == 'km' ? 'បោះបង់' : 'Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dctx, true),
                  child: Text(
                    _lang == 'km' ? 'លុបទាំងអស់' : 'Delete All',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await _clearAllData();
            if (mounted) Navigator.pop(context);
          }
        },
      ),
    );
  }

  List<Transaction> get _visibleTx {
    var list = _tx.where((t) {
      final matchesSearch = _searchQuery.isEmpty ||
          t.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _filterCategory == null || t.category == _filterCategory;
      final matchesDate = matchesDateRange(
        t.date,
        _dateFilter,
        customRange: _customDateRange,
      );
      final matchesWallet = _selectedWalletId == null ||
          t.walletId == _selectedWalletId ||
          (t.type == TxType.transfer && t.toWalletId == _selectedWalletId);
      return matchesSearch && matchesCategory && matchesDate && matchesWallet;
    }).toList();

    switch (_sort) {
      case SortOption.newest:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOption.oldest:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortOption.highest:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortOption.lowest:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    return list;
  }

  double get _monthIncome {
    final now = DateTime.now();
    return _tx
        .where((t) =>
            t.type == TxType.income &&
            t.date.year == now.year &&
            t.date.month == now.month &&
            (_selectedWalletId == null || t.walletId == _selectedWalletId))
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get _monthExpense {
    final now = DateTime.now();
    return _tx
        .where((t) =>
            t.type == TxType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month &&
            (_selectedWalletId == null || t.walletId == _selectedWalletId))
        .fold(0.0, (s, t) => s + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      DashboardView(
        tx: _visibleTx,
        allTx: _tx,
        monthlyBudget: _monthlyBudget,
        monthIncome: _monthIncome,
        monthExpense: _monthExpense,
        currency: _currency,
        rate: _rate,
        onRemove: _removeTxWithUndo,
        onEdit: (t) => _openTxModal(editing: t),
        searchQuery: _searchQuery,
        filterCategory: _filterCategory,
        dateFilter: _dateFilter,
        customDateRange: _customDateRange,
        sort: _sort,
        onSearchChanged: (v) => setState(() => _searchQuery = v),
        onFilterChanged: (v) => setState(() => _filterCategory = v),
        onDateFilterChanged: (v) => setState(() => _dateFilter = v),
        onCustomDateRangeChanged: (range) => setState(() => _customDateRange = range),
        onSortChanged: (v) => setState(() => _sort = v),
        onOpenSettings: _openSettings,
        wallets: _wallets,
        selectedWalletId: _selectedWalletId,
        onSelectWallet: (wid) => setState(() => _selectedWalletId = wid),
        onWalletsChanged: _onWalletsChanged,
        customCategories: _customCategories,
        categoryBudgets: _categoryBudgets,
        onOpenCategoryBudgets: _openCategoryBudgets,
        onOpenCategoryManager: _openCategoryManager,
        savingsGoals: _savingsGoals,
        onOpenSavingsGoals: _openSavingsModal,
        debts: _debts,
        onOpenDebtTracker: _openDebtTracker,
        lang: _lang,
      ),
      StatisticsView(
        tx: _tx,
        currency: _currency,
        rate: _rate,
        customCategories: _customCategories,
        lang: _lang,
        onRemove: _removeTxWithUndo,
        onEdit: (t) => _openTxModal(editing: t),
      ),
    ];

    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        body: SafeArea(bottom: false, child: pages[_currentIndex]),
        floatingActionButton: keyboardVisible
            ? null
            : FloatingActionButton(
                onPressed: () => _openTxModal(),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.add, size: 28),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: keyboardVisible
            ? null
            : PillNavBar(
                currentIndex: _currentIndex,
                onTap: (i) => setState(() => _currentIndex = i),
                lang: _lang,
              ),
      ),
    );
  }
}
