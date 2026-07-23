import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const ModernExpenseApp());
}

// ==========================================
// ០. ពណ៌ និង Theme
// ==========================================
class AppColors {
  static const bgLight = Color(0xFFF6F7FB);
  static const bgDark = Color(0xFF0D1220);
  static const cardDark = Color(0xFF171E2E);
  static const primary = Color(0xFF10B981);
  static const primaryDeep = Color(0xFF059669);
  static const income = Color(0xFF22C55E);
  static const expense = Color(0xFFF43F5E);
  static const navy = Color(0xFF1E293B);
  static const navy2 = Color(0xFF334155);
  static const accent = Color(0xFF6366F1);
}

class ModernExpenseApp extends StatefulWidget {
  const ModernExpenseApp({super.key});
  @override
  State<ModernExpenseApp> createState() => _ModernExpenseAppState();
}

class _ModernExpenseAppState extends State<ModernExpenseApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme(bool isDark) {
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.kantumruyProTextTheme();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Pro',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navy,
          primary: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.bgLight,
        cardColor: Colors.white,
        useMaterial3: true,
        textTheme: baseTextTheme,
        splashFactory: InkRipple.splashFactory,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: const Color(0xFF34D399),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.bgDark,
        cardColor: AppColors.cardDark,
        useMaterial3: true,
        textTheme: baseTextTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: MainControllerScreen(onToggleTheme: _toggleTheme, isDark: _themeMode == ThemeMode.dark),
    );
  }
}

// ==========================================
// ១. MODELS
// ==========================================
enum TxType { income, expense }

class Category {
  final String name;
  final IconData icon;
  final Color color;
  const Category(this.name, this.icon, this.color);
}

const List<Category> kExpenseCategories = [
  Category('អាហារ', Icons.fastfood_rounded, Color(0xFFF59E0B)),
  Category('ធ្វើដំណើរ', Icons.directions_car_rounded, Color(0xFF3B82F6)),
  Category('ទិញទំនិញ', Icons.shopping_bag_rounded, Color(0xFFEC4899)),
  Category('សុខភាព', Icons.local_hospital_rounded, Color(0xFFEF4444)),
  Category('ការសិក្សា', Icons.school_rounded, Color(0xFF8B5CF6)),
  Category('ការកម្សាន្ត', Icons.movie_rounded, Color(0xFF06B6D4)),
  Category('ផ្ទះ', Icons.home_rounded, Color(0xFF84CC16)),
  Category('ផ្សេងៗ', Icons.account_balance_wallet_rounded, Color(0xFF64748B)),
];

const List<Category> kIncomeCategories = [
  Category('ប្រាក់ខែ', Icons.work_rounded, Color(0xFF3B82F6)),
  Category('អាជីវកម្ម', Icons.storefront_rounded, Color(0xFF14B8A6)),
  Category('វិនិយោគ', Icons.trending_up_rounded, Color(0xFF22C55E)),
  Category('អំណោយ', Icons.card_giftcard_rounded, Color(0xFFEC4899)),
  Category('ផ្សេងៗ', Icons.attach_money_rounded, Color(0xFF64748B)),
];

Category categoryByName(String name, TxType type) {
  final list = type == TxType.income ? kIncomeCategories : kExpenseCategories;
  return list.firstWhere((c) => c.name == name, orElse: () => list.last);
}

enum DateRangeFilter { today, week, month, all }

enum SortOption { newest, oldest, highest, lowest }

class Transaction {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final TxType type;
  final String note;
  final bool isRecurring;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.type = TxType.expense,
    this.note = '',
    this.isRecurring = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'type': type.name,
        'note': note,
        'isRecurring': isRecurring,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        title: json['title'],
        amount: (json['amount'] as num).toDouble(),
        category: json['category'],
        date: DateTime.parse(json['date']),
        type: (json['type'] == 'income') ? TxType.income : TxType.expense,
        note: json['note'] ?? '',
        isRecurring: json['isRecurring'] ?? false,
      );
}

// ==========================================
// ២. PERSISTENCE
// ==========================================
class StorageService {
  static const _kTxKey = 'transactions_v2';
  static const _kBudgetKey = 'monthly_budget_v1';
  static const _kCurrencyKey = 'currency_v1';
  static const _kRateKey = 'exchange_rate_v1';

  static Future<List<Transaction>> loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kTxKey);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.map((e) => Transaction.fromJson(e)).toList();
  }

  static Future<void> saveTransactions(List<Transaction> tx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTxKey, jsonEncode(tx.map((e) => e.toJson()).toList()));
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

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTxKey);
    await prefs.remove(_kBudgetKey);
  }
}

// ==========================================
// ៣. Utils
// ==========================================
String formatCurrency(double usdAmount, String currency, double rate) {
  if (currency == 'KHR') {
    final khr = usdAmount * rate;
    return '${NumberFormat('#,##0').format(khr)} ៛';
  }
  return '\$${usdAmount.toStringAsFixed(2)}';
}

String greetingForNow() {
  final h = DateTime.now().hour;
  if (h < 12) return 'អរុណសួស្តី ☀️';
  if (h < 18) return 'ទិវាសួស្តី 🌤️';
  return 'សាយណ្ហសួស្តី 🌙';
}

bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

bool matchesDateRange(DateTime date, DateRangeFilter filter) {
  final now = DateTime.now();
  switch (filter) {
    case DateRangeFilter.today:
      return _isSameDay(date, now);
    case DateRangeFilter.week:
      return now.difference(date).inDays.abs() <= 7;
    case DateRangeFilter.month:
      return date.year == now.year && date.month == now.month;
    case DateRangeFilter.all:
      return true;
  }
}

// ==========================================
// ៤. MAIN CONTROLLER
// ==========================================
class MainControllerScreen extends StatefulWidget {
  final void Function(bool) onToggleTheme;
  final bool isDark;
  const MainControllerScreen({super.key, required this.onToggleTheme, required this.isDark});

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

  String _searchQuery = '';
  String? _filterCategory;
  DateRangeFilter _dateFilter = DateRangeFilter.month;
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
    setState(() {
      _tx = tx;
      _monthlyBudget = budget;
      _currency = currency;
      _rate = rate;
      _loading = false;
    });
  }

  Future<void> _persist() async => StorageService.saveTransactions(_tx);

  void _addTx(Transaction t) {
    setState(() => _tx.insert(0, t));
    _persist();
    HapticFeedback.lightImpact();
  }

  void _updateTx(Transaction t) {
    setState(() {
      final idx = _tx.indexWhere((e) => e.id == t.id);
      if (idx != -1) _tx[idx] = t;
    });
    _persist();
  }

  void _removeTxWithUndo(Transaction t) {
    final idx = _tx.indexOf(t);
    setState(() => _tx.removeWhere((e) => e.id == t.id));
    _persist();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text('បានលុប "${t.title}"'),
        action: SnackBarAction(
          label: 'មិនធ្វើវិញ',
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

  Future<void> _clearAllData() async {
    setState(() {
      _tx = [];
      _monthlyBudget = 0.0;
    });
    await StorageService.clearAll();
  }

  void _openTxModal({Transaction? editing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TransactionModal(
        onAdd: _addTx,
        onUpdate: _updateTx,
        editing: editing,
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
        onExport: _exportCsv,
        onClearAll: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dctx) => AlertDialog(
              title: const Text('លុបទិន្នន័យទាំងអស់?'),
              content: const Text('សកម្មភាពនេះមិនអាចត្រឡប់វិញបានទេ។'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('បោះបង់')),
                TextButton(
                  onPressed: () => Navigator.pop(dctx, true),
                  child: const Text('លុបទាំងអស់', style: TextStyle(color: Colors.red)),
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

  void _exportCsv() {
    final buffer = StringBuffer('Type,Title,Amount(USD),Category,Date,Note\n');
    for (final t in _tx) {
      buffer.writeln(
          '${t.type.name},"${t.title}",${t.amount},"${t.category}",${DateFormat('yyyy-MM-dd').format(t.date)},"${t.note.replaceAll('"', '""')}"');
    }
    final csv = buffer.toString();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('នាំចេញទិន្នន័យ (CSV)'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(csv, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('បិទ')),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csv));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('បានចម្លងទៅ Clipboard ✅')),
              );
            },
            child: const Text('ចម្លង'),
          ),
        ],
      ),
    );
  }

  List<Transaction> get _visibleTx {
    var list = _tx.where((t) {
      final matchesSearch = _searchQuery.isEmpty || t.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _filterCategory == null || t.category == _filterCategory;
      final matchesDate = matchesDateRange(t.date, _dateFilter);
      return matchesSearch && matchesCategory && matchesDate;
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
        .where((t) => t.type == TxType.income && t.date.year == now.year && t.date.month == now.month)
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get _monthExpense {
    final now = DateTime.now();
    return _tx
        .where((t) => t.type == TxType.expense && t.date.year == now.year && t.date.month == now.month)
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
        sort: _sort,
        onSearchChanged: (v) => setState(() => _searchQuery = v),
        onFilterChanged: (v) => setState(() => _filterCategory = v),
        onDateFilterChanged: (v) => setState(() => _dateFilter = v),
        onSortChanged: (v) => setState(() => _sort = v),
        onOpenSettings: _openSettings,
      ),
      StatisticsView(tx: _tx, currency: _currency, rate: _rate),
    ];

    return Scaffold(
      extendBody: true,
      body: SafeArea(bottom: false, child: pages[_currentIndex]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTxModal(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _PillNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ==========================================
// ៥. Pill-style Bottom Navigation
// ==========================================
class _PillNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _PillNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08), blurRadius: 24, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            Expanded(child: _navItem(context, Icons.home_rounded, 'ទំព័រដើម', 0)),
            const SizedBox(width: 64),
            Expanded(child: _navItem(context, Icons.pie_chart_rounded, 'ស្ថិតិ', 1)),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, int index) {
    final selected = currentIndex == index;
    final color = selected ? AppColors.primary : Colors.grey.shade400;
    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

// ==========================================
// ៦. DASHBOARD
// ==========================================
class DashboardView extends StatelessWidget {
  final List<Transaction> tx;
  final double monthlyBudget;
  final double monthIncome;
  final double monthExpense;
  final String currency;
  final double rate;
  final Function(Transaction) onRemove;
  final Function(Transaction) onEdit;
  final String searchQuery;
  final String? filterCategory;
  final DateRangeFilter dateFilter;
  final SortOption sort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onFilterChanged;
  final ValueChanged<DateRangeFilter> onDateFilterChanged;
  final ValueChanged<SortOption> onSortChanged;
  final VoidCallback onOpenSettings;

  const DashboardView({
    super.key,
    required this.tx,
    required this.monthlyBudget,
    required this.monthIncome,
    required this.monthExpense,
    required this.currency,
    required this.rate,
    required this.onRemove,
    required this.onEdit,
    required this.searchQuery,
    required this.filterCategory,
    required this.dateFilter,
    required this.sort,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onDateFilterChanged,
    required this.onSortChanged,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.navy;
    final balance = monthIncome - monthExpense;
    final budgetRatio = monthlyBudget > 0 ? (monthExpense / monthlyBudget).clamp(0.0, 1.0) : 0.0;
    final overBudget = monthlyBudget > 0 && monthExpense > monthlyBudget;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greetingForNow(), style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                    Text('ចំណូល-ចំណាយរបស់អ្នក',
                        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: textColor)),
                  ],
                ),
                InkWell(
                  onTap: onOpenSettings,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.settings_rounded, color: textColor, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: _BalanceCard(
              balance: balance,
              income: monthIncome,
              expense: monthExpense,
              budget: monthlyBudget,
              budgetRatio: budgetRatio,
              overBudget: overBudget,
              currency: currency,
              rate: rate,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: TextField(
              onChanged: onSearchChanged,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'ស្វែងរកប្រតិបត្តិការ...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _SmallChip(label: 'ថ្ងៃនេះ', selected: dateFilter == DateRangeFilter.today, onTap: () => onDateFilterChanged(DateRangeFilter.today)),
                const SizedBox(width: 8),
                _SmallChip(label: '៧ថ្ងៃ', selected: dateFilter == DateRangeFilter.week, onTap: () => onDateFilterChanged(DateRangeFilter.week)),
                const SizedBox(width: 8),
                _SmallChip(label: 'ខែនេះ', selected: dateFilter == DateRangeFilter.month, onTap: () => onDateFilterChanged(DateRangeFilter.month)),
                const SizedBox(width: 8),
                _SmallChip(label: 'ទាំងអស់', selected: dateFilter == DateRangeFilter.all, onTap: () => onDateFilterChanged(DateRangeFilter.all)),
                const SizedBox(width: 16),
                Container(width: 1, height: 20, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(vertical: 8)),
                const SizedBox(width: 12),
                _SortMenu(sort: sort, onChanged: onSortChanged),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              children: [
                _FilterChip(label: 'ប្រភេទទាំងអស់', selected: filterCategory == null, onTap: () => onFilterChanged(null)),
                ...{...kExpenseCategories, ...kIncomeCategories}.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _FilterChip(
                        label: c.name,
                        selected: filterCategory == c.name,
                        color: c.color,
                        onTap: () => onFilterChanged(c.name),
                      ),
                    )),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text('ប្រតិបត្តិការ (${tx.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
          ),
        ),
        if (tx.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(Icons.receipt_long_rounded, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('មិនទាន់មានប្រតិបត្តិការទេ', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => TxItemCard(tx: tx[i], onRemove: onRemove, onEdit: onEdit, currency: currency, rate: rate),
                childCount: tx.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance, income, expense, budget, budgetRatio;
  final bool overBudget;
  final String currency;
  final double rate;
  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
    required this.budget,
    required this.budgetRatio,
    required this.overBudget,
    required this.currency,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.navy2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: AppColors.navy.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('សមតុល្យខែនេះ', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: balance),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (ctx, value, _) => Text(
              formatCurrency(value, currency, rate),
              style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.income,
                  label: 'ចំណូល',
                  value: formatCurrency(income, currency, rate),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  icon: Icons.arrow_upward_rounded,
                  color: AppColors.expense,
                  label: 'ចំណាយ',
                  value: formatCurrency(expense, currency, rate),
                ),
              ),
            ],
          ),
          if (budget > 0) ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ថវិកា: ${formatCurrency(budget, currency, rate)}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                if (overBudget)
                  Text('លើសថវិកា ⚠️', style: TextStyle(color: Colors.red.shade300, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: budgetRatio,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(overBudget ? AppColors.expense : AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  const _MiniStat({required this.icon, required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SmallChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : Colors.grey.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  final SortOption sort;
  final ValueChanged<SortOption> onChanged;
  const _SortMenu({required this.sort, required this.onChanged});

  String _label(SortOption s) {
    switch (s) {
      case SortOption.newest:
        return 'ថ្មីបំផុត';
      case SortOption.oldest:
        return 'ចាស់បំផុត';
      case SortOption.highest:
        return 'ថ្លៃបំផុត';
      case SortOption.lowest:
        return 'ថោកបំផុត';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      initialValue: sort,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (ctx) => SortOption.values
          .map((s) => PopupMenuItem(value: s, child: Text(_label(s))))
          .toList(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_vert_rounded, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(_label(sort), style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? chipColor : chipColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : chipColor, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

// ==========================================
// ៧. Transaction Item Card
// ==========================================
class TxItemCard extends StatelessWidget {
  final Transaction tx;
  final Function(Transaction) onRemove;
  final Function(Transaction) onEdit;
  final String currency;
  final double rate;

  const TxItemCard({super.key, required this.tx, required this.onRemove, required this.onEdit, required this.currency, required this.rate});

  @override
  Widget build(BuildContext context) {
    final cat = categoryByName(tx.category, tx.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = tx.type == TxType.income;
    final amountColor = isIncome ? AppColors.income : AppColors.expense;

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(tx),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(color: AppColors.expense, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
      ),
      child: GestureDetector(
        onTap: () => onEdit(tx),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 7),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                child: Icon(cat.icon, color: cat.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                        if (tx.isRecurring) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.autorenew_rounded, size: 13, color: Colors.grey.shade400),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('${cat.name} · ${DateFormat('dd MMM').format(tx.date)}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    if (tx.note.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(tx.note, style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}${formatCurrency(tx.amount, currency, rate)}',
                style: TextStyle(color: amountColor, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// ៨. Add / Edit Modal
// ==========================================
class TransactionModal extends StatefulWidget {
  final Function(Transaction) onAdd;
  final Function(Transaction) onUpdate;
  final Transaction? editing;
  const TransactionModal({super.key, required this.onAdd, required this.onUpdate, this.editing});

  @override
  State<TransactionModal> createState() => _TransactionModalState();
}

class _TransactionModalState extends State<TransactionModal> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late TxType _type;
  late bool _recurring;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _type = e?.type ?? TxType.expense;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _amountCtrl = TextEditingController(text: e != null ? e.amount.toString() : '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _selectedDate = e?.date ?? DateTime.now();
    _selectedCategory = e?.category ?? (_type == TxType.income ? kIncomeCategories.first.name : kExpenseCategories.first.name);
    _recurring = e?.isRecurring ?? false;
  }

  List<Category> get _categoryList => _type == TxType.income ? kIncomeCategories : kExpenseCategories;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    final title = _titleCtrl.text;
    final amount = double.tryParse(_amountCtrl.text);
    if (title.trim().isEmpty || amount == null || amount <= 0) return;

    final t = Transaction(
      id: widget.editing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      category: _selectedCategory,
      date: _selectedDate,
      type: _type,
      note: _noteCtrl.text.trim(),
      isRecurring: _recurring,
    );

    if (_isEditing) {
      widget.onUpdate(t);
    } else {
      widget.onAdd(t);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _type == TxType.income ? AppColors.income : AppColors.expense;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(top: 20, left: 22, right: 22, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
            ),
            const SizedBox(height: 18),
            Text(_isEditing ? 'កែប្រតិបត្តិការ' : 'ប្រតិបត្តិការថ្មី', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 18),

            // Type toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  _typeTab('ចំណាយ', TxType.expense, AppColors.expense),
                  _typeTab('ចំណូល', TxType.income, AppColors.income),
                ],
              ),
            ),
            const SizedBox(height: 18),

            TextField(
              controller: _titleCtrl,
              decoration: _inputDecoration('ឈ្មោះប្រតិបត្តិការ'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration('ចំនួនទឹកប្រាក់ (\$)'),
            ),
            const SizedBox(height: 16),
            Text('ប្រភេទ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categoryList.map((c) {
                final selected = c.name == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = c.name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected ? c.color : c.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c.icon, size: 16, color: selected ? Colors.white : c.color),
                        const SizedBox(width: 6),
                        Text(c.name, style: TextStyle(color: selected ? Colors.white : c.color, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: _inputDecoration('កំណត់ចំណាំ (មិនចាំបាច់)'),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(15)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18),
                    const SizedBox(width: 10),
                    Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _recurring,
              onChanged: (v) => setState(() => _recurring = v),
              title: const Text('កើតឡើងវិញរៀងរាល់ខែ', style: TextStyle(fontSize: 14)),
              secondary: Icon(Icons.autorenew_rounded, color: Colors.grey.shade500),
              activeColor: accent,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(_isEditing ? 'កែប្រែ' : 'រក្សាទុក', style: const TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeTab(String label, TxType type, Color color) {
    final selected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          _selectedCategory = _categoryList.first.name;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: selected ? color : Colors.transparent, borderRadius: BorderRadius.circular(13)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      );
}

// ==========================================
// ៩. STATISTICS
// ==========================================
class StatisticsView extends StatelessWidget {
  final List<Transaction> tx;
  final String currency;
  final double rate;
  const StatisticsView({super.key, required this.tx, required this.currency, required this.rate});

  List<Map<String, Object>> get groupedByDay {
    return List.generate(7, (index) {
      final day = DateTime.now().subtract(Duration(days: index));
      double sum = 0;
      for (final t in tx) {
        if (t.type == TxType.expense && _isSameDay(t.date, day)) sum += t.amount;
      }
      return {'day': '${day.day}/${day.month}', 'amount': sum};
    }).reversed.toList();
  }

  double get maxDay => groupedByDay.fold(0.0, (m, e) => math.max(m, e['amount'] as double));

  Map<String, double> get categoryBreakdown {
    final now = DateTime.now();
    final map = <String, double>{};
    for (final t in tx) {
      if (t.type == TxType.expense && t.date.year == now.year && t.date.month == now.month) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  double get monthIncome {
    final now = DateTime.now();
    return tx.where((t) => t.type == TxType.income && t.date.year == now.year && t.date.month == now.month).fold(0.0, (s, t) => s + t.amount);
  }

  double get monthExpense {
    final now = DateTime.now();
    return tx.where((t) => t.type == TxType.expense && t.date.year == now.year && t.date.month == now.month).fold(0.0, (s, t) => s + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final byCategory = categoryBreakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final grandTotal = byCategory.fold(0.0, (s, e) => s + e.value);

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 150),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Text('ស្ថិតិចំណូល-ចំណាយ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.navy)),
        ),

        // Income vs expense summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(child: _SummaryCard(label: 'ចំណូលខែនេះ', value: formatCurrency(monthIncome, currency, rate), color: AppColors.income, icon: Icons.trending_up_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(label: 'ចំណាយខែនេះ', value: formatCurrency(monthExpense, currency, rate), color: AppColors.expense, icon: Icons.trending_down_rounded)),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
          child: Text('ចំណាយ ៧ ថ្ងៃចុងក្រោយ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.navy)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: groupedByDay.map((data) {
              final amount = data['amount'] as double;
              final heightPct = maxDay == 0.0 ? 0.0 : amount / maxDay;
              return Column(
                children: [
                  Text(amount == 0 ? '' : formatCurrency(amount, currency, rate), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Container(
                    height: 110, width: 20,
                    decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    alignment: Alignment.bottomCenter,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: heightPct),
                      duration: const Duration(milliseconds: 600),
                      builder: (ctx, v, _) => FractionallySizedBox(
                        heightFactor: v,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDeep], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(data['day'] as String, style: const TextStyle(fontSize: 11)),
                ],
              );
            }).toList(),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 14),
          child: Text('ចំណាយតាមប្រភេទ (ខែនេះ)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.navy)),
        ),
        if (byCategory.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Text('មិនទាន់មានទិន្នន័យទេ', style: TextStyle(color: Colors.grey.shade500)),
          )
        else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 170,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: CustomPaint(
                          painter: DonutChartPainter(
                            values: byCategory.map((e) => e.value).toList(),
                            colors: byCategory.map((e) => categoryByName(e.key, TxType.expense).color).toList(),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('សរុប', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                Text(formatCurrency(grandTotal, currency, rate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: byCategory.take(5).map((e) {
                            final cat = categoryByName(e.key, TxType.expense);
                            final pct = grandTotal == 0 ? 0.0 : (e.value / grandTotal * 100);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(cat.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                                  Text('${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  DonutChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (s, v) => s + v);
    if (total <= 0) return;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final strokeWidth = size.shortestSide * 0.18;
    double startAngle = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect.deflate(strokeWidth / 2), startAngle, sweep - 0.03, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) => oldDelegate.values != values;
}

// ==========================================
// ១០. SETTINGS SHEET
// ==========================================
class SettingsSheet extends StatefulWidget {
  final bool isDark;
  final void Function(bool) onToggleTheme;
  final String currency;
  final double rate;
  final double monthlyBudget;
  final void Function(String) onSetCurrency;
  final void Function(double) onSetRate;
  final void Function(double) onSetBudget;
  final VoidCallback onExport;
  final VoidCallback onClearAll;

  const SettingsSheet({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.currency,
    required this.rate,
    required this.monthlyBudget,
    required this.onSetCurrency,
    required this.onSetRate,
    required this.onSetBudget,
    required this.onExport,
    required this.onClearAll,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late TextEditingController _budgetCtrl;
  late TextEditingController _rateCtrl;

  @override
  void initState() {
    super.initState();
    _budgetCtrl = TextEditingController(text: widget.monthlyBudget > 0 ? widget.monthlyBudget.toStringAsFixed(2) : '');
    _rateCtrl = TextEditingController(text: widget.rate.toStringAsFixed(0));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(top: 20, left: 22, right: 22, bottom: MediaQuery.of(context).viewInsets.bottom + 30),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 18),
            const Text('ការកំណត់', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: widget.isDark,
              onChanged: widget.onToggleTheme,
              title: const Text('របៀបងងឹត (Dark Mode)'),
              secondary: const Icon(Icons.dark_mode_rounded),
              activeColor: AppColors.primary,
            ),
            const Divider(),

            const Text('រូបិយប័ណ្ណបង្ហាញ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _currencyTab('USD (\$)', 'USD')),
                const SizedBox(width: 10),
                Expanded(child: _currencyTab('KHR (៛)', 'KHR')),
              ],
            ),
            if (widget.currency == 'KHR') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _rateCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'អត្រាប្តូរប្រាក់ (1\$ = ? ៛)',
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.08),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                onSubmitted: (v) {
                  final r = double.tryParse(v);
                  if (r != null && r > 0) widget.onSetRate(r);
                },
              ),
            ],
            const SizedBox(height: 20),

            const Text('ថវិកាប្រចាំខែ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            TextField(
              controller: _budgetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'ថវិកា (\$)',
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onSubmitted: (v) {
                final b = double.tryParse(v) ?? 0.0;
                widget.onSetBudget(b);
              },
            ),
            const SizedBox(height: 24),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.ios_share_rounded, color: AppColors.primary),
              title: const Text('នាំចេញទិន្នន័យ (CSV)'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: widget.onExport,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
              title: const Text('លុបទិន្នន័យទាំងអស់', style: TextStyle(color: Colors.red)),
              onTap: widget.onClearAll,
            ),
          ],
        ),
      ),
    );
  }

  Widget _currencyTab(String label, String value) {
    final selected = widget.currency == value;
    return GestureDetector(
      onTap: () => widget.onSetCurrency(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : Colors.grey.shade600, fontWeight: FontWeight.bold)),
      ),
    );
  }
}