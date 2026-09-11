import 'package:flutter/material.dart';

class SavingGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final IconData icon;
  final Color color;

  const SavingGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    this.icon = Icons.savings_rounded,
    this.color = const Color(0xFF10B981),
  });

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => currentAmount >= targetAmount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': targetDate?.toIso8601String(),
        'iconCode': icon.codePoint,
        'colorValue': color.toARGB32(),
      };

  factory SavingGoal.fromJson(Map<String, dynamic> json) {
    return SavingGoal(
      id: json['id'],
      title: json['title'],
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate']) : null,
      icon: iconFromCode(json['iconCode'] as int?),
      color: Color(json['colorValue'] ?? 0xFF10B981),
    );
  }

  static IconData iconFromCode(int? code) {
    if (code == Icons.laptop_mac_rounded.codePoint) return Icons.laptop_mac_rounded;
    if (code == Icons.directions_car_rounded.codePoint) return Icons.directions_car_rounded;
    if (code == Icons.home_rounded.codePoint) return Icons.home_rounded;
    if (code == Icons.flight_takeoff_rounded.codePoint) return Icons.flight_takeoff_rounded;
    if (code == Icons.smartphone_rounded.codePoint) return Icons.smartphone_rounded;
    if (code == Icons.fitness_center_rounded.codePoint) return Icons.fitness_center_rounded;
    if (code == Icons.school_rounded.codePoint) return Icons.school_rounded;
    return Icons.savings_rounded;
  }

  SavingGoal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    IconData? icon,
    Color? color,
  }) {
    return SavingGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }
}
