import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../utils/formatters.dart';

class WalletSelectorBar extends StatelessWidget {
  final List<Wallet> wallets;
  final String? selectedWalletId;
  final List<Transaction> transactions;
  final String currency;
  final double rate;
  final ValueChanged<String?> onSelectWallet;
  final ValueChanged<List<Wallet>> onWalletsChanged;

  const WalletSelectorBar({
    super.key,
    required this.wallets,
    required this.selectedWalletId,
    required this.transactions,
    required this.currency,
    required this.rate,
    required this.onSelectWallet,
    required this.onWalletsChanged,
  });

  double _getWalletBalance(Wallet wallet) {
    double bal = wallet.initialBalance;
    for (final t in transactions) {
      if (t.type == TxType.transfer) {
        if (t.walletId == wallet.id) {
          bal -= t.amount; // Sender wallet
        }
        if (t.toWalletId == wallet.id) {
          bal += t.amount; // Receiver wallet
        }
      } else if (t.walletId == wallet.id) {
        if (t.type == TxType.income) {
          bal += t.amount;
        } else if (t.type == TxType.expense) {
          bal -= t.amount;
        }
      }
    }
    return bal;
  }

  void _showAddWalletModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    IconData selectedIcon = Icons.account_balance_wallet_rounded;
    Color selectedColor = const Color(0xFF10B981);

    final availableIcons = [
      Icons.account_balance_wallet_rounded,
      Icons.account_balance_rounded,
      Icons.credit_card_rounded,
      Icons.savings_rounded,
      Icons.payments_rounded,
      Icons.currency_exchange_rounded,
    ];

    final availableColors = [
      const Color(0xFF10B981),
      const Color(0xFF005477),
      const Color(0xFF1D3557),
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) => Container(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'បន្ថែមកាបូបលុយថ្មី (New Wallet)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'ឈ្មោះកាបូប (ឧ. ABA, Wing, សាច់ប្រាក់)',
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
                  controller: balanceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'សមតុល្យដំបូង (\$) (មិនចាំបាច់)',
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('ជ្រើសរើស Icon', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: availableIcons.map((ic) {
                    final isSel = ic == selectedIcon;
                    return InkWell(
                      onTap: () => setMState(() => selectedIcon = ic),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSel ? selectedColor.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: isSel ? Border.all(color: selectedColor, width: 2) : null,
                        ),
                        child: Icon(ic, color: isSel ? selectedColor : Colors.grey),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                const Text('ជ្រើសរើស ពណ៌', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: availableColors.map((cl) {
                    final isSel = cl == selectedColor;
                    return InkWell(
                      onTap: () => setMState(() => selectedColor = cl),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: cl,
                          shape: BoxShape.circle,
                          border: isSel ? Border.all(color: Colors.white, width: 3) : null,
                        ),
                        child: isSel ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      final initBal = double.tryParse(balanceCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
                      final newWallet = Wallet(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        name: name,
                        icon: selectedIcon,
                        color: selectedColor,
                        initialBalance: initBal,
                      );
                      final updated = List<Wallet>.from(wallets)..add(newWallet);
                      onWalletsChanged(updated);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('បង្កើតកាបូបលុយ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 78,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // All Wallets item
          _walletChip(
            context,
            isSelected: selectedWalletId == null,
            icon: Icons.all_inclusive_rounded,
            color: AppColors.accent,
            name: 'ទាំងអស់',
            balanceText: 'កាបូបទាំងអស់',
            onTap: () => onSelectWallet(null),
          ),
          ...wallets.map((w) {
            final isSel = selectedWalletId == w.id;
            final bal = _getWalletBalance(w);
            return _walletChip(
              context,
              isSelected: isSel,
              icon: w.icon,
              color: w.color,
              name: w.name,
              balanceText: formatCurrency(bal, currency, rate),
              onTap: () => onSelectWallet(w.id),
            );
          }),
          // Add Wallet Button
          GestureDetector(
            onTap: () => _showAddWalletModal(context),
            child: Container(
              margin: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2), style: BorderStyle.solid),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 20, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text('បន្ថែមកាបូប', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletChip(
    BuildContext context, {
    required bool isSelected,
    required IconData icon,
    required Color color,
    required String name,
    required String balanceText,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? color : Colors.black).withValues(alpha: isSelected ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isSelected
              ? null
              : Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: isSelected ? Colors.white : color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.navy),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  balanceText,
                  style: TextStyle(
                    color: isSelected ? Colors.white.withValues(alpha: 0.8) : Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
