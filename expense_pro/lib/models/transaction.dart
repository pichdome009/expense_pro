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

    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      date: DateTime.parse(json['date']),
      type: type,
      note: json['note'] ?? '',
      isRecurring: json['isRecurring'] ?? false,
      walletId: json['walletId'] ?? 'default_cash',
      toWalletId: json['toWalletId'],
      originalCurrency: json['originalCurrency'],
      originalAmount: json['originalAmount'] != null
          ? (json['originalAmount'] as num).toDouble()
          : null,
    );
  }

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
    String? toWalletId,
    String? originalCurrency,
    double? originalAmount,
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
      toWalletId: toWalletId ?? this.toWalletId,
      originalCurrency: originalCurrency ?? this.originalCurrency,
      originalAmount: originalAmount ?? this.originalAmount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
