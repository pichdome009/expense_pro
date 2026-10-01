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
  final void Function(Wallet wallet, {String? reassignToWalletId, bool deleteTransactions})? onDeleteWallet;

  const WalletSelectorBar({
    super.key,
    required this.wallets,
    required this.selectedWalletId,
    required this.transactions,
    required this.currency,
    required this.rate,
    required this.onSelectWallet,
    required this.onWalletsChanged,
    this.onDeleteWallet,
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
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) => GestureDetector(
          onTap: () => FocusScope.of(ctx).unfocus(),
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
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
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
                      const Text(
                        'បន្ថែមកាបូបលុយថ្មី',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded, size: 22),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.withValues(alpha: 0.1),
                          padding: const EdgeInsets.all(6),
                          minimumSize: const Size(34, 34),
                        ),
                      ),
                    ],
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(ic, color: isSel ? Colors.white : Colors.grey.shade600, size: 22),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('ជ្រើសរើស ពណ៌', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: availableColors.map((col) {
                      final isSel = col == selectedColor;
                      return InkWell(
                        onTap: () => setMState(() => selectedColor = col),
                        customBorder: const CircleBorder(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: isSel ? Border.all(color: Colors.white, width: 3) : null,
                            boxShadow: isSel ? [BoxShadow(color: col.withValues(alpha: 0.5), blurRadius: 8)] : null,
                          ),
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
                        final initBal = parseAmount(balanceCtrl.text);
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
      ),
    );
  }

  void _confirmDeleteWallet(BuildContext context, Wallet w) async {
    if (wallets.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('មិនអាចលុបបានទេ ត្រូវមានកាបូបយ៉ាងហោចណាស់មួយ!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final tiedTxs = transactions.where((t) => t.walletId == w.id || t.toWalletId == w.id).toList();
    final otherWallets = wallets.where((x) => x.id != w.id).toList();

    if (tiedTxs.isEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('លុបកាបូប "${w.name}"?'),
          content: const Text('កាបូបនេះគ្មានប្រតិបត្តិការកត់ត្រាឡើយ។ តើអ្នកពិតជាចង់លុបមែនទេ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('បោះបង់'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('លុប', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        if (onDeleteWallet != null) {
          onDeleteWallet!(w, reassignToWalletId: null, deleteTransactions: false);
        } else {
          final updated = List<Wallet>.from(wallets)..removeWhere((x) => x.id == w.id);
          if (selectedWalletId == w.id) {
            onSelectWallet(null);
          }
          onWalletsChanged(updated);
        }
      }
      return;
    }

    // Tied transactions exist: show interactive orphan protection dialog
    String targetWalletId = otherWallets.first.id;
    int actionChoice = 0; // 0 = Reassign, 1 = Delete transactions

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('លុបកាបូប "${w.name}"?')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'កាបូបនេះមានប្រតិបត្តិការចំនួន ${tiedTxs.length} ដែលកំពុងប្រើប្រាស់។ សូមជ្រើសរើសដំណោះស្រាយការពារទិន្នន័យ៖',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),

              // Option 0: Reassign (Recommended)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setDialogState(() => actionChoice = 0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: actionChoice == 0
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: actionChoice == 0
                          ? AppColors.primary
                          : Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            actionChoice == 0
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: actionChoice == 0 ? AppColors.primary : Colors.grey,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'ផ្ទេរប្រតិបត្តិការទៅកាបូបផ្សេង (ណែនាំ)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      if (actionChoice == 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: targetWalletId,
                              items: otherWallets
                                  .map((ow) => DropdownMenuItem(
                                        value: ow.id,
                                        child: Row(
                                          children: [
                                            Icon(ow.icon, size: 16, color: ow.color),
                                            const SizedBox(width: 8),
                                            Text(ow.name, style: const TextStyle(fontSize: 13)),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => targetWalletId = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Option 1: Delete all transactions tied to this wallet
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setDialogState(() => actionChoice = 1),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: actionChoice == 1
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: actionChoice == 1
                          ? Colors.red
                          : Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        actionChoice == 1
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: actionChoice == 1 ? Colors.red : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'លុបប្រតិបត្តិការទាំង ${tiedTxs.length} ចោលទាំងអស់',
                          style: TextStyle(
                            color: actionChoice == 1 ? Colors.red : null,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('បោះបង់'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (actionChoice == 0) {
                  if (onDeleteWallet != null) {
                    onDeleteWallet!(w, reassignToWalletId: targetWalletId, deleteTransactions: false);
                  }
                } else {
                  if (onDeleteWallet != null) {
                    onDeleteWallet!(w, reassignToWalletId: null, deleteTransactions: true);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: actionChoice == 1 ? Colors.red : AppColors.primary,
              ),
              child: Text(
                actionChoice == 1 ? 'លុបទាំងអស់' : 'បញ្ជាក់ការផ្ទេរ & លុប',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
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
            final isCustom = !kDefaultWallets.any((d) => d.id == w.id);
            return _walletChip(
              context,
              isSelected: isSel,
              icon: w.icon,
              color: w.color,
              name: w.name,
              balanceText: formatCurrency(bal, currency, rate),
              onTap: () => onSelectWallet(w.id),
              onLongPress: isCustom ? () => _confirmDeleteWallet(context, w) : null,
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
    VoidCallback? onLongPress,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? AppColors.cardDark : Colors.white),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: (isSelected ? color : Colors.black).withValues(alpha: isSelected ? 0.28 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.22)
                    : color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 15, color: isSelected ? Colors.white : color),
            ),
            const SizedBox(width: 8),
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
                    color: isSelected ? Colors.white.withValues(alpha: 0.85) : Colors.grey.shade500,
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
