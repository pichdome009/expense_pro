enum DebtType {
  lent, // គេជំពាក់យើង (I lent money)
  borrowed, // យើងជំពាក់គេ (I borrowed money)
}

class DebtLoan {
  final String id;
  final String personName;
  final double amount;
  final double paidAmount;
  final DebtType type;
  final DateTime? dueDate;
  final DateTime createdAt;
  final String? notes;
  final String? walletId;

  const DebtLoan({
    required this.id,
    required this.personName,
    required this.amount,
    this.paidAmount = 0.0,
    required this.type,
    this.dueDate,
    required this.createdAt,
    this.notes,
    this.walletId,
  });

  double get remainingAmount => (amount - paidAmount).clamp(0.0, double.infinity);
  bool get isSettled => paidAmount >= amount;
  double get progress => amount > 0 ? (paidAmount / amount).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'personName': personName,
        'amount': amount,
        'paidAmount': paidAmount,
        'type': type.name,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
        'walletId': walletId,
      };

  factory DebtLoan.fromJson(Map<String, dynamic> json) {
    return DebtLoan(
      id: json['id'] as String,
      personName: json['personName'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] == 'borrowed' ? DebtType.borrowed : DebtType.lent,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      notes: json['notes'] as String?,
      walletId: json['walletId'] as String?,
    );
  }

  DebtLoan copyWith({
    String? id,
    String? personName,
    double? amount,
    double? paidAmount,
    DebtType? type,
    DateTime? dueDate,
    DateTime? createdAt,
    String? notes,
    String? walletId,
  }) {
    return DebtLoan(
      id: id ?? this.id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      walletId: walletId ?? this.walletId,
    );
  }
}
