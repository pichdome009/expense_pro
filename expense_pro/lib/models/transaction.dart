enum TxType { income, expense, transfer }

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
  final String walletId;
  final String? toWalletId;
  final String? originalCurrency;
  final double? originalAmount;
  final double? exchangeRate;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.type = TxType.expense,
    this.note = '',
    this.isRecurring = false,
    this.walletId = 'default_cash',
    this.toWalletId,
    this.originalCurrency,
    this.originalAmount,
    this.exchangeRate,
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
        'walletId': walletId,
        'toWalletId': toWalletId,
        'originalCurrency': originalCurrency,
        'originalAmount': originalAmount,
        'exchangeRate': exchangeRate,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    final TxType type;
    if (typeStr == 'income') {
      type = TxType.income;
    } else if (typeStr == 'transfer') {
      type = TxType.transfer;
    } else {
      type = TxType.expense;
    }

    final double amount = (json['amount'] as num).toDouble();
    final double? origAmt = json['originalAmount'] != null
        ? (json['originalAmount'] as num).toDouble()
        : null;
    final String? origCur = json['originalCurrency'];
    double? exRate = (json['exchangeRate'] as num?)?.toDouble();

    // Auto-derive historical exchange rate if missing from legacy records
    if (exRate == null && origCur == 'KHR' && origAmt != null && amount > 0) {
      exRate = origAmt / amount;
    }

    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: amount,
      category: json['category'],
      date: DateTime.parse(json['date']),
      type: type,
      note: json['note'] ?? '',
      isRecurring: json['isRecurring'] ?? false,
      walletId: json['walletId'] ?? 'default_cash',
      toWalletId: json['toWalletId'],
      originalCurrency: origCur,
      originalAmount: origAmt,
      exchangeRate: exRate,
    );
  }

  static const _sentinel = Object();

  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    TxType? type,
    String? note,
    bool? isRecurring,
    String? walletId,
    Object? toWalletId = _sentinel,
    Object? originalCurrency = _sentinel,
    Object? originalAmount = _sentinel,
    Object? exchangeRate = _sentinel,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      type: type ?? this.type,
      note: note ?? this.note,
      isRecurring: isRecurring ?? this.isRecurring,
      walletId: walletId ?? this.walletId,
      toWalletId: identical(toWalletId, _sentinel) ? this.toWalletId : toWalletId as String?,
      originalCurrency: identical(originalCurrency, _sentinel) ? this.originalCurrency : originalCurrency as String?,
      originalAmount: identical(originalAmount, _sentinel) ? this.originalAmount : originalAmount as double?,
      exchangeRate: identical(exchangeRate, _sentinel) ? this.exchangeRate : exchangeRate as double?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
