import 'package:flutter/material.dart';
import '../constants/app_icons.dart';

class Wallet {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double initialBalance;

  const Wallet({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.initialBalance = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCode': icon.codePoint,
        'colorValue': color.toARGB32(),
        'initialBalance': initialBalance,
      };

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        id: json['id'],
        name: json['name'],
        icon: iconFromCodePoint(json['iconCode'] as int),
        color: Color(json['colorValue']),
        initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const List<Wallet> kDefaultWallets = [
  Wallet(
    id: 'default_cash',
    name: 'សាច់ប្រាក់សុទ្ធ',
    icon: Icons.payments_rounded,
    color: Color(0xFF10B981),
  ),
  Wallet(
    id: 'aba_bank',
    name: 'ធនាគារ ABA',
    icon: Icons.account_balance_rounded,
    color: Color(0xFF005477),
  ),
  Wallet(
    id: 'acleda_bank',
    name: 'ធនាគារ អេស៊ីលីដា',
    icon: Icons.account_balance_rounded,
    color: Color(0xFF1D3557),
  ),
];
