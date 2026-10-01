import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/transaction.dart';

class TxItemCard extends StatelessWidget {
  final Transaction tx;
  final Function(Transaction) onRemove;
  final Function(Transaction) onEdit;
  final String currency;
  final double rate;

  const TxItemCard({
    super.key,
    required this.tx,
    required this.onRemove,
    required this.onEdit,
    required this.currency,
    required this.rate,
  });

  String _formatPrimaryAmount(bool isTransfer, bool isIncome) {
    final sign = isTransfer ? '⇄ ' : (isIncome ? '+' : '-');
    if (currency == 'KHR') {
      // If transaction was originally recorded in KHR, always display exact historical KHR!
      if (tx.originalCurrency == 'KHR' && tx.originalAmount != null) {
        return '$sign${NumberFormat('#,##0').format(tx.originalAmount)} ៛';
      }
      // If transaction was originally in USD, convert using historical rate if available
      final usedRate = tx.exchangeRate ?? rate;
      return '$sign${NumberFormat('#,##0').format(tx.amount * usedRate)} ៛';
    } else {
      // Display currency is USD
      return '$sign\$${tx.amount.toStringAsFixed(2)}';
    }
  }

  String? _formatSecondaryAmount() {
    if (currency == 'KHR') {
      // In KHR view: show USD reference
      return '(\$${tx.amount.toStringAsFixed(2)})';
    } else {
      // In USD view: show KHR equivalent (historical if originally KHR)
      if (tx.originalCurrency == 'KHR' && tx.originalAmount != null) {
        return '(${NumberFormat('#,##0').format(tx.originalAmount)} ៛)';
      }
      final usedRate = tx.exchangeRate ?? rate;
      return '(${NumberFormat('#,##0').format(tx.amount * usedRate)} ៛)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cat = categoryByName(tx.category, tx.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isIncome = tx.type == TxType.income;
    final isTransfer = tx.type == TxType.transfer;
    final amountColor = isTransfer
        ? AppColors.accent
        : isIncome
            ? AppColors.income
            : AppColors.expense;

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(tx),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
      child: GestureDetector(
        onTap: () => onEdit(tx),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 7),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(cat.icon, color: cat.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tx.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (tx.isRecurring) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.autorenew_rounded,
                            size: 13,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cat.name} · ${DateFormat('dd MMM').format(tx.date)}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    if (tx.note.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        tx.note,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPrimaryAmount(isTransfer, isIncome),
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_formatSecondaryAmount() != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatSecondaryAmount()!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
