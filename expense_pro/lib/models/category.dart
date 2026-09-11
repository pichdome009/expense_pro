import 'package:flutter/material.dart';
import '../constants/app_icons.dart';

class Category {
  final String name;
  final IconData icon;
  final Color color;
  final bool isExpense;
  final bool isCustom;

  const Category(
    this.name,
    this.icon,
    this.color, {
    this.isExpense = true,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'iconCode': icon.codePoint,
        'colorValue': color.toARGB32(),
        'isExpense': isExpense,
        'isCustom': isCustom,
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        json['name'] as String,
        iconFromCodePoint(json['iconCode'] as int),
        Color(json['colorValue'] as int),
        isExpense: json['isExpense'] as bool? ?? true,
        isCustom: json['isCustom'] as bool? ?? true,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}
