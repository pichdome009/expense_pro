import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/debt_loan.dart';
import '../utils/formatters.dart';

class DebtTrackerModal extends StatefulWidget {
  final List<DebtLoan> debts;
  final String currency;
  final double rate;
  final String lang;
  final ValueChanged<List<DebtLoan>> onDebtsChanged;

  const DebtTrackerModal({
    super.key,
    required this.debts,
    required this.currency,
    required this.rate,
    this.lang = 'km',
    required this.onDebtsChanged,
  });

  @override
  State<DebtTrackerModal> createState() => _DebtTrackerModalState();
}

class _DebtTrackerModalState extends State<DebtTrackerModal> {
  late List<DebtLoan> _debts;
  String _filter = 'all'; // all, lent, borrowed, settled

  @override
  void initState() {
    super.initState();
    _debts = List<DebtLoan>.from(widget.debts);
  }

  double get _totalLentPending {
    return _debts
        .where((d) => d.type == DebtType.lent && !d.isSettled)
        .fold(0.0, (s, d) => s + d.remainingAmount);
  }

  double get _totalBorrowedPending {
    return _debts
        .where((d) => d.type == DebtType.borrowed && !d.isSettled)
        .fold(0.0, (s, d) => s + d.remainingAmount);
  }

  List<DebtLoan> get _filteredDebts {
    switch (_filter) {
      case 'lent':
        return _debts.where((d) => d.type == DebtType.lent && !d.isSettled).toList();
      case 'borrowed':
        return _debts.where((d) => d.type == DebtType.borrowed && !d.isSettled).toList();
      case 'settled':
        return _debts.where((d) => d.isSettled).toList();
      case 'all':
      default:
        return _debts;
    }
  }

  void _showAddDebtDialog() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DebtType selectedType = DebtType.lent;
    DateTime? selectedDueDate;

    showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            widget.lang == 'km' ? 'កត់ត្រាបំណុល / លុយខ្ចីថ្មី' : 'New Debt / Loan Entry',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Selector
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(widget.lang == 'km' ? 'គេជំពាក់យើង' : 'Lent (To Receive)'),
                        selected: selectedType == DebtType.lent,
                        selectedColor: AppColors.income.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: selectedType == DebtType.lent ? AppColors.income : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (val) => setDState(() => selectedType = DebtType.lent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(widget.lang == 'km' ? 'យើងជំពាក់គេ' : 'Borrowed (To Pay)'),
                        selected: selectedType == DebtType.borrowed,
                        selectedColor: AppColors.expense.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: selectedType == DebtType.borrowed ? AppColors.expense : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (val) => setDState(() => selectedType = DebtType.borrowed),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: widget.lang == 'km' ? 'ឈ្មោះបុគ្គល (ឧ. សុខា)' : 'Person Name',
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: widget.lang == 'km' ? 'ចំនួនទឹកប្រាក់ (\$)' : 'Amount (\$)',
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Due Date picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDState(() => selectedDueDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_rounded, size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              selectedDueDate != null
                                  ? '${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}'
                                  : (widget.lang == 'km' ? 'កាលបរិច្ឆេទសន្យាសង (មិនចាំបាច់)' : 'Due Date (Optional)'),
                              style: TextStyle(
                                fontSize: 13,
                                color: selectedDueDate != null ? null : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        if (selectedDueDate != null)
                          GestureDetector(
                            onTap: () => setDState(() => selectedDueDate = null),
                            child: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: widget.lang == 'km' ? 'កំណត់ចំណាំ (មិនចាំបាច់)' : 'Note (Optional)',
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: Text(widget.lang == 'km' ? 'បោះបង់' : 'Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final amt = parseAmount(amountCtrl.text);
                if (name.isNotEmpty && amt > 0) {
                  final newDebt = DebtLoan(
                    id: 'debt_${DateTime.now().microsecondsSinceEpoch}',
                    personName: name,
                    amount: amt,
                    type: selectedType,
                    dueDate: selectedDueDate,
                    createdAt: DateTime.now(),
                    notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  );
                  setState(() => _debts.insert(0, newDebt));
                  widget.onDebtsChanged(_debts);
                  Navigator.pop(dctx);
                }
              },
              child: Text(widget.lang == 'km' ? 'រក្សាទុក' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRepayDialog(DebtLoan debt) {
    final amtCtrl = TextEditingController(text: debt.remainingAmount.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          widget.lang == 'km' ? 'កត់ត្រាការសងប្រាក់' : 'Record Repayment',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${debt.personName} (${debt.type == DebtType.lent ? (widget.lang == 'km' ? 'គេជំពាក់យើង' : 'Lent') : (widget.lang == 'km' ? 'យើងជំពាក់គេ' : 'Borrowed')})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.lang == 'km' ? 'នៅខ្វះ' : 'Remaining'}: ${formatCurrency(debt.remainingAmount, widget.currency, widget.rate)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amtCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: widget.lang == 'km' ? 'ចំនួនទឹកប្រាក់សង (\$)' : 'Payment Amount (\$)',
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: Text(widget.lang == 'km' ? 'បោះបង់' : 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final paid = parseAmount(amtCtrl.text);
              if (paid > 0) {
                final idx = _debts.indexWhere((d) => d.id == debt.id);
                if (idx != -1) {
                  final newPaid = (debt.paidAmount + paid).clamp(0.0, debt.amount);
                  setState(() {
                    _debts[idx] = debt.copyWith(paidAmount: newPaid);
                  });
                  widget.onDebtsChanged(_debts);
                }
                Navigator.pop(dctx);
              }
            },
            child: Text(widget.lang == 'km' ? 'យល់ព្រម' : 'Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredDebts;

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
          bottom: MediaQuery.of(context).viewInsets.bottom + 30,
        ),
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
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.handshake_rounded, color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.lang == 'km' ? 'តាមដានបំណុល & លុយខ្ចី' : 'Debt & Loan Tracker',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 28),
                      onPressed: _showAddDebtDialog,
                      tooltip: widget.lang == 'km' ? 'បន្ថែមបំណុល' : 'Add Debt',
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 22),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(34, 34),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

          // Summaries
          Row(
            children: [
              Expanded(
                child: _DebtSummaryCard(
                  label: widget.lang == 'km' ? 'គេជំពាក់យើង' : 'To Receive',
                  amount: formatCurrency(_totalLentPending, widget.currency, widget.rate),
                  color: AppColors.income,
                  icon: Icons.call_received_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DebtSummaryCard(
                  label: widget.lang == 'km' ? 'យើងជំពាក់គេ' : 'To Pay',
                  amount: formatCurrency(_totalBorrowedPending, widget.currency, widget.rate),
                  color: AppColors.expense,
                  icon: Icons.call_made_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('all', widget.lang == 'km' ? 'ទាំងអស់' : 'All'),
                const SizedBox(width: 8),
                _filterChip('lent', widget.lang == 'km' ? 'គេជំពាក់យើង' : 'To Receive'),
                const SizedBox(width: 8),
                _filterChip('borrowed', widget.lang == 'km' ? 'យើងជំពាក់គេ' : 'To Pay'),
                const SizedBox(width: 8),
                _filterChip('settled', widget.lang == 'km' ? 'សងរួច' : 'Settled'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 44, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    widget.lang == 'km'
                        ? 'មិនមានកំណត់ត្រាបំណុលនៅឡើយទេ'
                        : 'No debt or loan records found',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final debt = filtered[i];
                  final isLent = debt.type == DebtType.lent;
                  final typeColor = isLent ? AppColors.income : AppColors.expense;
                  final isDone = debt.isSettled;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isLent ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                color: typeColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        debt.personName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: typeColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isLent
                                              ? (widget.lang == 'km' ? 'គេជំពាក់' : 'Lent')
                                              : (widget.lang == 'km' ? 'ជំពាក់គេ' : 'Borrowed'),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: typeColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (debt.dueDate != null)
                                    Text(
                                      '${widget.lang == 'km' ? 'ថ្ងៃសង' : 'Due'}: ${debt.dueDate!.day}/${debt.dueDate!.month}/${debt.dueDate!.year}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatCurrency(debt.remainingAmount, widget.currency, widget.rate),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDone ? Colors.green : typeColor,
                                  ),
                                ),
                                if (debt.paidAmount > 0 && !isDone)
                                  Text(
                                    '${widget.lang == 'km' ? 'សងបាន' : 'Paid'} ${formatCurrency(debt.paidAmount, widget.currency, widget.rate)}',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        if (!isDone) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: debt.progress,
                              minHeight: 5,
                              backgroundColor: Colors.grey.withValues(alpha: 0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(typeColor),
                            ),
                          ),
                        ],

                        if (debt.notes != null && debt.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            debt.notes!,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                          ),
                        ],

                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!isDone)
                              OutlinedButton.icon(
                                icon: const Icon(Icons.payment_rounded, size: 15),
                                label: Text(widget.lang == 'km' ? 'កត់ត្រាការសង' : 'Repay', style: const TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _showRepayDialog(debt),
                              ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                setState(() => _debts.removeWhere((d) => d.id == debt.id));
                                widget.onDebtsChanged(_debts);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    ),
  );
}

  Widget _filterChip(String key, String label) {
    final selected = _filter == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary.withValues(alpha: 0.18),
      labelStyle: TextStyle(
        fontSize: 11,
        color: selected ? AppColors.primary : Colors.grey.shade600,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _filter = key),
    );
  }
}

class _DebtSummaryCard extends StatelessWidget {
  final String label, amount;
  final Color color;
  final IconData icon;

  const _DebtSummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    amount,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
