import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/category.dart';
import '../models/debt_loan.dart';
import '../models/saving_goal.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';
import '../widgets/balance_card.dart';
import '../widgets/filter_chips.dart';
import '../widgets/tx_item_card.dart';
import '../widgets/wallet_selector.dart';

class DashboardView extends StatelessWidget {
  final List<Transaction> tx;
  final List<Transaction> allTx;
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
  final DateTimeRange? customDateRange;
  final SortOption sort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onFilterChanged;
  final ValueChanged<DateRangeFilter> onDateFilterChanged;
  final ValueChanged<DateTimeRange?> onCustomDateRangeChanged;
  final ValueChanged<SortOption> onSortChanged;
  final VoidCallback onOpenSettings;

  // Wallets
  final List<Wallet> wallets;
  final String? selectedWalletId;
  final ValueChanged<String?> onSelectWallet;
  final ValueChanged<List<Wallet>> onWalletsChanged;

  // Custom Categories & Budgets
  final List<Category> customCategories;
  final Map<String, double> categoryBudgets;
  final VoidCallback onOpenCategoryBudgets;
  final VoidCallback onOpenCategoryManager;

  // Savings & Localization
  final List<SavingGoal> savingsGoals;
  final VoidCallback onOpenSavingsGoals;
  final String lang;

  // Debts & Loans
  final List<DebtLoan> debts;
  final VoidCallback onOpenDebtTracker;

  const DashboardView({
    super.key,
    required this.tx,
    required this.allTx,
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
    this.customDateRange,
    required this.sort,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onDateFilterChanged,
    required this.onCustomDateRangeChanged,
    required this.onSortChanged,
    required this.onOpenSettings,
    required this.wallets,
    required this.selectedWalletId,
    required this.onSelectWallet,
    required this.onWalletsChanged,
    required this.customCategories,
    required this.categoryBudgets,
    required this.onOpenCategoryBudgets,
    required this.onOpenCategoryManager,
    this.savingsGoals = const [],
    required this.onOpenSavingsGoals,
    this.debts = const [],
    required this.onOpenDebtTracker,
    this.lang = 'km',
  });

  List<String> get _budgetAlerts {
    if (categoryBudgets.isEmpty) return const [];
    final alerts = <String>[];
    final now = DateTime.now();

    final monthExpenses = <String, double>{};
    for (final t in allTx) {
      if (t.type == TxType.expense &&
          t.date.year == now.year &&
          t.date.month == now.month) {
        monthExpenses[t.category] = (monthExpenses[t.category] ?? 0.0) + t.amount;
      }
    }

    for (final entry in categoryBudgets.entries) {
      final catName = entry.key;
      final limit = entry.value;
      if (limit <= 0) continue;
      final spent = monthExpenses[catName] ?? 0.0;

      if (spent > limit) {
        alerts.add('"$catName" លើសថវិកា 100% (${formatCurrency(spent, currency, rate)} / ${formatCurrency(limit, currency, rate)})');
      } else if (spent >= limit * 0.8) {
        alerts.add('"$catName" ចំណាយដល់ 80% (${formatCurrency(spent, currency, rate)} / ${formatCurrency(limit, currency, rate)})');
      }
    }
    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.navy;
    final balance = monthIncome - monthExpense;
    final budgetRatio =
        monthlyBudget > 0 ? (monthExpense / monthlyBudget).clamp(0.0, 1.0) : 0.0;
    final overBudget = monthlyBudget > 0 && monthExpense > monthlyBudget;
    final allCategories = getAllCategories(customCategories);
    final alerts = _budgetAlerts;

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
                    Text(
                      greetingForNow(lang),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      lang == 'km' ? 'ចំណូល-ចំណាយរបស់អ្នក' : 'Your Income & Expense',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: onOpenDebtTracker,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.handshake_rounded, color: Colors.indigoAccent, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onOpenSavingsGoals,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.savings_rounded, color: AppColors.income, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onOpenCategoryBudgets,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.pie_chart_outline_rounded, color: textColor, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
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
              ],
            ),
          ),
        ),

        // Wallet Selector
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: WalletSelectorBar(
              wallets: wallets,
              selectedWalletId: selectedWalletId,
              transactions: allTx,
              currency: currency,
              rate: rate,
              onSelectWallet: onSelectWallet,
              onWalletsChanged: onWalletsChanged,
            ),
          ),
        ),

        // Balance Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: BalanceCard(
              balance: balance,
              income: monthIncome,
              expense: monthExpense,
              budget: monthlyBudget,
              budgetRatio: budgetRatio,
              overBudget: overBudget,
              currency: currency,
              rate: rate,
              lang: lang,
            ),
          ),
        ),

        // Savings Goal Progress Banner
        if (savingsGoals.isNotEmpty)
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: onOpenSavingsGoals,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.teal.shade50.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.teal.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.savings_rounded, color: Colors.teal, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.of('savings_goals', lang),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                savingsGoals.first.title,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(savingsGoals.first.progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.teal),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: savingsGoals.first.progress,
                        minHeight: 6,
                        backgroundColor: Colors.teal.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Debt & Loan Summary Banner
        if (debts.any((d) => !d.isSettled))
          SliverToBoxAdapter(
            child: Builder(
              builder: (context) {
                final unsettled = debts.where((d) => !d.isSettled).toList();
                final toReceive = unsettled
                    .where((d) => d.type == DebtType.lent)
                    .fold(0.0, (s, d) => s + d.remainingAmount);
                final toPay = unsettled
                    .where((d) => d.type == DebtType.borrowed)
                    .fold(0.0, (s, d) => s + d.remainingAmount);

                return GestureDetector(
                  onTap: onOpenDebtTracker,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.indigo.shade50.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.indigo.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.handshake_rounded, color: Colors.indigo, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.get('debt_loans', lang),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (toReceive > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.income.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '↓ ${AppStrings.get('to_receive', lang)}: +${formatCurrency(toReceive, currency, rate)}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.income),
                                      ),
                                    ),
                                  if (toPay > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.expense.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '↑ ${AppStrings.get('to_pay', lang)}: -${formatCurrency(toPay, currency, rate)}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.expense),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        // Category Budget Alert Banner
        if (alerts.isNotEmpty)
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: onOpenCategoryBudgets,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ការព្រមានថវិកាតាមប្រភេទ',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                          ),
                          Text(
                            alerts.first,
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.amber, size: 18),
                  ],
                ),
              ),
            ),
          ),

        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: TextField(
              onChanged: onSearchChanged,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: lang == 'km' ? 'ស្វែងរកប្រតិបត្តិការ...' : 'Search transactions...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                filled: true,
                fillColor: isDark ? Colors.white10 : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),

        // Date filter chips & Sort
        SliverToBoxAdapter(
          child: SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                SmallChip(
                  label: AppStrings.get('today', lang),
                  selected: dateFilter == DateRangeFilter.today && customDateRange == null,
                  onTap: () {
                    onCustomDateRangeChanged(null);
                    onDateFilterChanged(DateRangeFilter.today);
                  },
                ),
                const SizedBox(width: 8),
                SmallChip(
                  label: AppStrings.get('7_days', lang),
                  selected: dateFilter == DateRangeFilter.week && customDateRange == null,
                  onTap: () {
                    onCustomDateRangeChanged(null);
                    onDateFilterChanged(DateRangeFilter.week);
                  },
                ),
                const SizedBox(width: 8),
                SmallChip(
                  label: AppStrings.get('this_month', lang),
                  selected: dateFilter == DateRangeFilter.month && customDateRange == null,
                  onTap: () {
                    onCustomDateRangeChanged(null);
                    onDateFilterChanged(DateRangeFilter.month);
                  },
                ),
                const SizedBox(width: 8),
                SmallChip(
                  label: AppStrings.get('all', lang),
                  selected: dateFilter == DateRangeFilter.all && customDateRange == null,
                  onTap: () {
                    onCustomDateRangeChanged(null);
                    onDateFilterChanged(DateRangeFilter.all);
                  },
                ),
                const SizedBox(width: 8),
                CustomDateChip(
                  label: customDateRange != null
                      ? '${customDateRange!.start.day}/${customDateRange!.start.month} - ${customDateRange!.end.day}/${customDateRange!.end.month}'
                      : AppStrings.get('custom_range', lang),
                  selected: customDateRange != null,
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDateRange: customDateRange ??
                          DateTimeRange(
                            start: DateTime(DateTime.now().year, DateTime.now().month, 1),
                            end: DateTime.now(),
                          ),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.fromSeed(
                              seedColor: AppColors.primary,
                              primary: AppColors.primary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      onCustomDateRangeChanged(picked);
                    }
                  },
                  onClear: () => onCustomDateRangeChanged(null),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 1,
                  height: 20,
                  color: Colors.grey.shade300,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                ),
                const SizedBox(width: 12),
                SortMenu(sort: sort, onChanged: onSortChanged, lang: lang),
              ],
            ),
          ),
        ),

        // Category filter chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              children: [
                FilterChipWidget(
                  label: lang == 'km' ? 'ប្រភេទទាំងអស់' : 'All Categories',
                  selected: filterCategory == null,
                  onTap: () => onFilterChanged(null),
                ),
                ...allCategories.map((c) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChipWidget(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang == 'km' ? 'ប្រតិបត្តិការ (${tx.length})' : 'Transactions (${tx.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (selectedWalletId != null)
                  TextButton.icon(
                    onPressed: () => onSelectWallet(null),
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 14),
                    label: Text(AppStrings.get('all_wallets', lang), style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),

        if (tx.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 72,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    lang == 'km' ? 'មិនទាន់មានប្រតិបត្តិការទេ' : 'No transactions yet',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => TxItemCard(
                  tx: tx[i],
                  onRemove: onRemove,
                  onEdit: onEdit,
                  currency: currency,
                  rate: rate,
                ),
                childCount: tx.length,
              ),
            ),
          ),
      ],
    );
  }
}
