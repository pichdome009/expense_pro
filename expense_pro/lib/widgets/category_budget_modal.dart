import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

class CategoryBudgetModal extends StatefulWidget {
  final Map<String, double> categoryBudgets;
  final List<Transaction> transactions;
  final List<Category> customCategories;
  final String currency;
  final double rate;
  final ValueChanged<Map<String, double>> onBudgetsChanged;

  const CategoryBudgetModal({
    super.key,
    required this.categoryBudgets,
    required this.transactions,
    required this.customCategories,
    required this.currency,
    required this.rate,
    required this.onBudgetsChanged,
  });

  @override
  State<CategoryBudgetModal> createState() => _CategoryBudgetModalState();
}

class _CategoryBudgetModalState extends State<CategoryBudgetModal> {
  late Map<String, double> _budgets;

  @override
  void initState() {
    super.initState();
    _budgets = Map<String, double>.from(widget.categoryBudgets);
  }

  List<Category> get _expenseCategories {
    final list = <Category>[];
    final customExp = widget.customCategories.where((c) => c.isExpense);
    list.addAll(customExp);
    list.addAll(kExpenseCategories);
    return list;
  }

  double _getCategorySpent(String catName) {
    final now = DateTime.now();
    return widget.transactions
        .where((t) =>
            t.type == TxType.expense &&
            t.category == catName &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (s, t) => s + t.amount);
  }

  void _showSetBudgetDialog(Category cat) {
    final currentBudget = _budgets[cat.name] ?? 0.0;
    final ctrl = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toStringAsFixed(2) : '',
    );

    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(cat.icon, color: cat.color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text('ថវិកាសម្រាប់ "${cat.name}"')),
          ],
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'ចំនួនទឹកប្រាក់ (\$)',
            hintText: 'ឧ. 150',
            filled: true,
            fillColor: Colors.grey.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _budgets.remove(cat.name));
              widget.onBudgetsChanged(_budgets);
              Navigator.pop(dctx);
            },
            child: const Text('លុបថវិកា', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              final val = parseAmount(ctrl.text);
              if (val > 0) {
                setState(() => _budgets[cat.name] = val);
                widget.onBudgetsChanged(_budgets);
              }
              Navigator.pop(dctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('រក្សាទុក', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          top: 20,
          left: 22,
          right: 22,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 20),
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ថវិកាតាមប្រភេទ (Category Budget)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Text(
              'កំណត់កញ្ចប់ថវិកាដើម្បីទទួលការព្រមានពេលចំណាយជិតដល់ 80% ឬលើស 100%',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),

            ..._expenseCategories.map((cat) {
              final budget = _budgets[cat.name] ?? 0.0;
              final spent = _getCategorySpent(cat.name);
              final ratio = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
              final isWarning = budget > 0 && spent >= (budget * 0.8) && spent <= budget;
              final isOver = budget > 0 && spent > budget;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 0,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.cardDark
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isOver
                        ? Colors.red.withValues(alpha: 0.5)
                        : (isWarning
                            ? Colors.amber.withValues(alpha: 0.5)
                            : Colors.grey.withValues(alpha: 0.15)),
                  ),
                ),
                child: InkWell(
                  onTap: () => _showSetBudgetDialog(cat),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cat.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(cat.icon, color: cat.color, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    budget > 0
                                        ? 'បានចំណាយ: ${formatCurrency(spent, widget.currency, widget.rate)} / ${formatCurrency(budget, widget.currency, widget.rate)}'
                                        : 'មិនទាន់កំណត់ថវិកា',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isOver ? Colors.red : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isOver)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'លើស 100% 🚨',
                                  style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              )
                            else if (isWarning)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ជិតដល់ 80% ⚠️',
                                  style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit_rounded, size: 16, color: Colors.grey),
                          ],
                        ),
                        if (budget > 0) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 6,
                              backgroundColor: Colors.grey.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation(
                                isOver ? AppColors.expense : (isWarning ? Colors.amber : cat.color),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}
}
