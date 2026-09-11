import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../models/transaction.dart';
import '../utils/app_strings.dart';
import '../utils/formatters.dart';
import 'tx_item_card.dart';

class FinancialCalendarView extends StatefulWidget {
  final List<Transaction> transactions;
  final String currency;
  final double rate;
  final String lang;
  final Function(Transaction)? onRemove;
  final Function(Transaction)? onEdit;

  const FinancialCalendarView({
    super.key,
    required this.transactions,
    required this.currency,
    required this.rate,
    this.lang = 'km',
    this.onRemove,
    this.onEdit,
  });

  @override
  State<FinancialCalendarView> createState() => _FinancialCalendarViewState();
}

class _FinancialCalendarViewState extends State<FinancialCalendarView> {
  late DateTime _currentMonth;
  late DateTime _selectedDay;

  static const List<String> _kmWeekdays = ['អា', 'ច', 'អ', 'ព', 'ព្រ', 'សុ', 'ស'];
  static const List<String> _enWeekdays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  static const List<String> _kmMonths = [
    'មករា', 'កុម្ភៈ', 'មីនា', 'មេសា', 'ឧសភា', 'មិថុនា',
    'កក្កដា', 'សីហា', 'កញ្ញា', 'តុលា', 'វិច្ឆិកា', 'ធ្នូ',
  ];

  static const List<String> _enMonths = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  String _formatMonthTitle() {
    final isKm = widget.lang == 'km';
    final m = isKm ? _kmMonths[_currentMonth.month - 1] : _enMonths[_currentMonth.month - 1];
    return '$m ${_currentMonth.year}';
  }

  Map<int, List<Transaction>> _getDaysMap() {
    final map = <int, List<Transaction>>{};
    for (final t in widget.transactions) {
      if (t.date.year == _currentMonth.year && t.date.month == _currentMonth.month) {
        map.putIfAbsent(t.date.day, () => []).add(t);
      }
    }
    return map;
  }

  List<Transaction> get _selectedDayTransactions {
    return widget.transactions.where((t) {
      return t.date.year == _selectedDay.year &&
          t.date.month == _selectedDay.month &&
          t.date.day == _selectedDay.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.navy;

    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    // DateTime.weekday: Monday=1, Sunday=7. In standard US calendar Sunday=0.
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;
    final totalCells = firstWeekday + daysInMonth;

    final daysMap = _getDaysMap();
    final selectedTxs = _selectedDayTransactions;

    final dayIncome = selectedTxs
        .where((t) => t.type == TxType.income)
        .fold(0.0, (s, t) => s + t.amount);
    final dayExpense = selectedTxs
        .where((t) => t.type == TxType.expense)
        .fold(0.0, (s, t) => s + t.amount);

    final isKm = widget.lang == 'km';
    final weekdays = isKm ? _kmWeekdays : _enWeekdays;

    return Column(
      children: [
        // Month navigation bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 28),
                onPressed: _prevMonth,
              ),
              Text(
                _formatMonthTitle(),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 28),
                onPressed: _nextMonth,
              ),
            ],
          ),
        ),

        // Weekday header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: List.generate(7, (i) {
              final isWeekend = i == 0 || i == 6;
              return Expanded(
                child: Center(
                  child: Text(
                    weekdays[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isWeekend ? Colors.red.shade400 : Colors.grey.shade500,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 6),

        // Monthly calendar grid
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.05,
            ),
            itemCount: totalCells,
            itemBuilder: (ctx, idx) {
              if (idx < firstWeekday) {
                return const SizedBox.shrink();
              }
              final day = idx - firstWeekday + 1;
              final thisDate = DateTime(_currentMonth.year, _currentMonth.month, day);
              final isSelected = _selectedDay.year == thisDate.year &&
                  _selectedDay.month == thisDate.month &&
                  _selectedDay.day == thisDate.day;

              final now = DateTime.now();
              final isToday = now.year == thisDate.year &&
                  now.month == thisDate.month &&
                  now.day == thisDate.day;

              final dayTxs = daysMap[day] ?? const [];
              final hasIncome = dayTxs.any((t) => t.type == TxType.income);
              final hasExpense = dayTxs.any((t) => t.type == TxType.expense);
              final hasTransfer = dayTxs.any((t) => t.type == TxType.transfer);

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDay = thisDate);
                },
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSelected
                        ? Border.all(color: AppColors.primary, width: 1.2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppColors.primary
                                  : textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasIncome)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : AppColors.income,
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (hasExpense)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : AppColors.expense,
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (hasTransfer)
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // Selected Day Ledger Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat(isKm ? 'd MMMM y' : 'MMMM d, y').format(_selectedDay),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    '${selectedTxs.length} ${AppStrings.of('day_transactions', widget.lang)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (dayIncome > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: AppColors.income.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${formatCurrency(dayIncome, widget.currency, widget.rate)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.income,
                        ),
                      ),
                    ),
                  if (dayExpense > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-${formatCurrency(dayExpense, widget.currency, widget.rate)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.expense,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Day Transactions List
        if (selectedTxs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Column(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.of('no_tx_day', widget.lang),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            itemCount: selectedTxs.length,
            itemBuilder: (ctx, i) => TxItemCard(
              tx: selectedTxs[i],
              onRemove: widget.onRemove ?? (_) {},
              onEdit: widget.onEdit ?? (_) {},
              currency: widget.currency,
              rate: widget.rate,
            ),
          ),
      ],
    );
  }
}
