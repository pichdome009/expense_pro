import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/financial_insights_service.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';
import '../widgets/donut_chart.dart';
import '../widgets/financial_calendar_view.dart';
import '../widgets/financial_insights_card.dart';

enum StatPeriod { month, year, all }

class StatisticsView extends StatefulWidget {
  final List<Transaction> tx;
  final String currency;
  final double rate;
  final List<Category> customCategories;
  final String lang;
  final Function(Transaction)? onRemove;
  final Function(Transaction)? onEdit;

  const StatisticsView({
    super.key,
    required this.tx,
    required this.currency,
    required this.rate,
    this.customCategories = const [],
    this.lang = 'km',
    this.onRemove,
    this.onEdit,
  });

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  int _viewMode = 0; // 0 = Analytics & Insights, 1 = Financial Calendar
  StatPeriod _period = StatPeriod.month;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  static const List<String> _khmerMonths = [
    'មករា',
    'កុម្ភៈ',
    'មីនា',
    'មេសា',
    'ឧសភា',
    'មិថុនា',
    'កក្កដា',
    'សីហា',
    'កញ្ញា',
    'តុលា',
    'វិច្ឆិកា',
    'ធ្នូ',
  ];

  static const List<String> _enMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _formatPeriodTitle() {
    final isKm = widget.lang == 'km';
    switch (_period) {
      case StatPeriod.month:
        final mName = isKm ? _khmerMonths[_selectedMonth - 1] : _enMonths[_selectedMonth - 1];
        return '$mName $_selectedYear';
      case StatPeriod.year:
        return '$_selectedYear';
      case StatPeriod.all:
        return AppStrings.of('all', widget.lang);
    }
  }

  void _prevPeriod() {
    setState(() {
      if (_period == StatPeriod.month) {
        if (_selectedMonth == 1) {
          _selectedMonth = 12;
          _selectedYear--;
        } else {
          _selectedMonth--;
        }
      } else if (_period == StatPeriod.year) {
        _selectedYear--;
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_period == StatPeriod.month) {
        if (_selectedMonth == 12) {
          _selectedMonth = 1;
          _selectedYear++;
        } else {
          _selectedMonth++;
        }
      } else if (_period == StatPeriod.year) {
        _selectedYear++;
      }
    });
  }

  List<Transaction> get _filteredTx {
    return widget.tx.where((t) {
      if (t.type == TxType.transfer) return false;
      switch (_period) {
        case StatPeriod.month:
          return t.date.year == _selectedYear && t.date.month == _selectedMonth;
        case StatPeriod.year:
          return t.date.year == _selectedYear;
        case StatPeriod.all:
          return true;
      }
    }).toList();
  }

  List<Map<String, Object>> get groupedByDay {
    return List.generate(7, (index) {
      final now = DateTime.now();
      final day = DateTime(now.year, now.month, now.day - index);
      double sum = 0;
      for (final t in widget.tx) {
        if (t.type == TxType.expense && isSameDay(t.date, day)) sum += t.amount;
      }
      return {'day': '${day.day}/${day.month}', 'amount': sum};
    }).reversed.toList();
  }

  double get maxDay =>
      groupedByDay.fold(0.0, (m, e) => math.max(m, e['amount'] as double));

  Map<String, double> get categoryBreakdown {
    final map = <String, double>{};
    for (final t in _filteredTx) {
      if (t.type == TxType.expense) {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  double get totalIncome {
    return _filteredTx
        .where((t) => t.type == TxType.income)
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get totalExpense {
    return _filteredTx
        .where((t) => t.type == TxType.expense)
        .fold(0.0, (s, t) => s + t.amount);
  }

  double get previousMonthExpense {
    final prevMonth = _selectedMonth == 1 ? 12 : _selectedMonth - 1;
    final prevYear = _selectedMonth == 1 ? _selectedYear - 1 : _selectedYear;
    return widget.tx
        .where((t) =>
            t.type == TxType.expense &&
            t.date.year == prevYear &&
            t.date.month == prevMonth)
        .fold(0.0, (s, t) => s + t.amount);
  }

  List<Map<String, dynamic>> get monthlyTrend {
    return List.generate(6, (index) {
      final offset = 5 - index;
      var y = _selectedYear;
      var m = _selectedMonth - offset;
      while (m <= 0) {
        m += 12;
        y--;
      }
      double exp = 0.0;
      for (final t in widget.tx) {
        if (t.type == TxType.expense && t.date.year == y && t.date.month == m) {
          exp += t.amount;
        }
      }
      final isKm = widget.lang == 'km';
      final label = isKm ? _khmerMonths[m - 1] : _enMonths[m - 1].substring(0, 3);
      return {
        'month': m,
        'year': y,
        'label': label,
        'expense': exp,
        'isSelected': offset == 0,
      };
    });
  }

  double get maxMonthTrend =>
      monthlyTrend.fold(0.0, (m, e) => math.max(m, e['expense'] as double));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final byCategory = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final grandTotal = byCategory.fold(0.0, (s, e) => s + e.value);

    final incomeLabel = _period == StatPeriod.month
        ? AppStrings.of('month_income', widget.lang)
        : '${AppStrings.of('income', widget.lang)} (${_formatPeriodTitle()})';
    final expenseLabel = _period == StatPeriod.month
        ? AppStrings.of('month_expense', widget.lang)
        : '${AppStrings.of('expense', widget.lang)} (${_formatPeriodTitle()})';

    final daysInCurrentPeriod = _period == StatPeriod.month
        ? DateTime(_selectedYear, _selectedMonth + 1, 0).day
        : (_period == StatPeriod.year ? 365 : 30);

    final insights = FinancialInsightsService.computeInsights(
      transactions: _filteredTx,
      daysInPeriod: daysInCurrentPeriod,
      lang: widget.lang,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 150),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Text(
            AppStrings.of('stat_overview', widget.lang),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.navy,
            ),
          ),
        ),

        // Main View Mode Toggle: [ 📊 ស្ថិតិ & វិភាគ | 📅 ប្រតិទិន ]
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.grey.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _viewMode = 0),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _viewMode == 0
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _viewMode == 0
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          size: 18,
                          color: _viewMode == 0 ? Colors.white : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.of('analytics_view', widget.lang),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _viewMode == 0 ? FontWeight.bold : FontWeight.w500,
                            color: _viewMode == 0 ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _viewMode = 1),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _viewMode == 1
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: _viewMode == 1
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: _viewMode == 1 ? Colors.white : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.of('calendar_view', widget.lang),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _viewMode == 1 ? FontWeight.bold : FontWeight.w500,
                            color: _viewMode == 1 ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_viewMode == 1) ...[
          // CALENDAR VIEW MODE
          FinancialCalendarView(
            transactions: widget.tx,
            currency: widget.currency,
            rate: widget.rate,
            lang: widget.lang,
            onRemove: widget.onRemove,
            onEdit: widget.onEdit,
          ),
        ] else ...[
          // Period filter buttons: Month | Year | All
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildPeriodTab(
                  title: widget.lang == 'km' ? 'ខែ' : 'Month',
                  period: StatPeriod.month,
                ),
                _buildPeriodTab(
                  title: widget.lang == 'km' ? 'ឆ្នាំ' : 'Year',
                  period: StatPeriod.year,
                ),
                _buildPeriodTab(
                  title: widget.lang == 'km' ? 'ទាំងអស់' : 'All Time',
                  period: StatPeriod.all,
                ),
              ],
            ),
          ),

        // Period Navigator (only when month or year)
        if (_period != StatPeriod.all)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 28),
                  onPressed: _prevPeriod,
                ),
                Text(
                  _formatPeriodTitle(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.navy,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 28),
                  onPressed: _nextPeriod,
                ),
              ],
            ),
          )
        else
          const SizedBox(height: 12),

        const SizedBox(height: 8),

        // Income vs expense summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: incomeLabel,
                  value: formatCurrency(totalIncome, widget.currency, widget.rate),
                  color: AppColors.income,
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryCard(
                  label: expenseLabel,
                  value: formatCurrency(totalExpense, widget.currency, widget.rate),
                  color: AppColors.expense,
                  icon: Icons.trending_down_rounded,
                ),
              ),
            ],
          ),
        ),

        if (_period == StatPeriod.month)
          _buildMonthlyComparison(isDark),

        // Smart Financial Insights & Analytics Card
        FinancialInsightsCard(
          data: insights,
          currency: widget.currency,
          rate: widget.rate,
          lang: widget.lang,
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
          child: Text(
            AppStrings.of('recent_7_days', widget.lang),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.navy,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: groupedByDay.map((data) {
              final amount = data['amount'] as double;
              final heightPct = maxDay == 0.0 ? 0.0 : amount / maxDay;
              return Column(
                children: [
                  Text(
                    amount == 0 ? '' : formatCurrency(amount, widget.currency, widget.rate),
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    height: 110,
                    width: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.bottomCenter,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: heightPct),
                      duration: const Duration(milliseconds: 600),
                      builder: (ctx, v, _) => FractionallySizedBox(
                        heightFactor: v,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDeep,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['day'] as String,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              );
            }).toList(),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
          child: Text(
            AppStrings.of('monthly_trend', widget.lang),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.navy,
            ),
          ),
        ),
        _build6MonthTrendChart(isDark),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 14),
          child: Text(
            '${AppStrings.of('by_category', widget.lang)} (${_formatPeriodTitle()})',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.navy,
            ),
          ),
        ),
        if (byCategory.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Text(
              widget.lang == 'km' ? 'មិនទាន់មានទិន្នន័យទេ' : 'No transaction data',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          )
        else
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CustomPaint(
                    painter: DonutChartPainter(
                      values: byCategory.map((e) => e.value).toList(),
                      colors: byCategory
                          .map<Color>((e) => categoryByName(
                                e.key,
                                TxType.expense,
                                widget.customCategories,
                              ).color)
                          .toList(),
                      trackColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.shade100,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.lang == 'km' ? 'សរុប' : 'Total',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                formatCurrency(grandTotal, widget.currency, widget.rate),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: byCategory.take(5).map((e) {
                      final cat = categoryByName(
                        e.key,
                        TxType.expense,
                        widget.customCategories,
                      );
                      final pct = grandTotal == 0
                          ? 0.0
                          : (e.value / grandTotal * 100);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: cat.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cat.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cat.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${pct.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cat.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
      ],
    );
  }

  Widget _buildPeriodTab({required String title, required StatPeriod period}) {
    final selected = _period == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _period = period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyComparison(bool isDark) {
    final prev = previousMonthExpense;
    final cur = totalExpense;
    final diff = cur - prev;
    final pct = prev > 0 ? (diff / prev * 100) : (cur > 0 ? 100.0 : 0.0);
    final isSaved = diff <= 0;
    final isKm = widget.lang == 'km';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? (isSaved
                ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                : const Color(0xFF7F1D1D).withValues(alpha: 0.25))
            : (isSaved ? Colors.green.shade50 : Colors.red.shade50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSaved
              ? Colors.green.withValues(alpha: 0.35)
              : Colors.red.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isSaved ? Colors.green : Colors.red).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSaved ? Icons.trending_down_rounded : Icons.trending_up_rounded,
              color: isSaved ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isKm ? 'ធៀបនឹងខែមុន' : 'vs Last Month',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSaved ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isSaved ? Colors.green : Colors.red).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${diff > 0 ? '+' : ''}${pct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSaved ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  prev == 0
                      ? (isKm
                          ? 'មិនមានទិន្នន័យខែមុនសម្រាប់ប្រៀបធៀបទេ'
                          : 'No previous month data to compare')
                      : (isSaved
                          ? (isKm
                              ? 'អ្នកបានសន្សំ ${formatCurrency(diff.abs(), widget.currency, widget.rate)} ច្រើនជាងខែមុន'
                              : 'You saved ${formatCurrency(diff.abs(), widget.currency, widget.rate)} compared to last month')
                          : (isKm
                              ? 'ចំណាយកើនលើសខែមុន ${formatCurrency(diff.abs(), widget.currency, widget.rate)}'
                              : 'Spent ${formatCurrency(diff.abs(), widget.currency, widget.rate)} more than last month')),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _build6MonthTrendChart(bool isDark) {
    final list = monthlyTrend;
    final max = maxMonthTrend;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: list.map((data) {
          final exp = data['expense'] as double;
          final isSel = data['isSelected'] as bool;
          final heightPct = max == 0.0 ? 0.0 : (exp / max);

          return Column(
            children: [
              Text(
                exp == 0 ? '' : formatCurrency(exp, widget.currency, widget.rate),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  color: isSel ? AppColors.primary : Colors.grey,
                ),
              ),
              const SizedBox(height: 5),
              Container(
                height: 100,
                width: 24,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.bottomCenter,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: heightPct),
                  duration: const Duration(milliseconds: 600),
                  builder: (ctx, v, _) => FractionallySizedBox(
                    heightFactor: v,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSel
                              ? [const Color(0xFF10B981), const Color(0xFF059669)]
                              : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isSel
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: isSel
                    ? const EdgeInsets.symmetric(horizontal: 5, vertical: 2)
                    : EdgeInsets.zero,
                decoration: isSel
                    ? BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      )
                    : null,
                child: Text(
                  data['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    color: isSel ? const Color(0xFF10B981) : null,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
