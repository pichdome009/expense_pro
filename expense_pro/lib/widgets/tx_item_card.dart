import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';

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
                    '${isTransfer ? '⇄ ' : isIncome ? '+' : '-'}${formatCurrency(tx.amount, currency, rate)}',
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (tx.originalCurrency != null &&
                      tx.originalCurrency != currency &&
                      tx.originalAmount != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      tx.originalCurrency == 'KHR'
                          ? '(${NumberFormat('#,##0').format(tx.originalAmount)} ៛)'
                          : '(\$${tx.originalAmount!.toStringAsFixed(2)})',
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
