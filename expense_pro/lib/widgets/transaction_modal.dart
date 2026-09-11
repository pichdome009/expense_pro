import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../utils/app_strings.dart';

class TransactionModal extends StatefulWidget {
  final Function(Transaction) onAdd;
  final Function(Transaction) onUpdate;
  final Transaction? editing;
  final List<Wallet> wallets;
  final List<Category> customCategories;
  final String currency;
  final double rate;
  final String lang;

  const TransactionModal({
    super.key,
    required this.onAdd,
    required this.onUpdate,
    this.editing,
    this.wallets = kDefaultWallets,
    this.customCategories = const [],
    this.currency = 'USD',
    this.rate = 4100.0,
    this.lang = 'km',
  });

  @override
  State<TransactionModal> createState() => _TransactionModalState();
}

class _TransactionModalState extends State<TransactionModal> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late DateTime _selectedDate;
  late String _selectedCategory;
  late String _selectedWalletId;
  String? _toWalletId;
  late TxType _type;
  late bool _recurring;
  late String _inputCurrency;
  String? _titleError;
  String? _amountError;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _type = e?.type ?? TxType.expense;
    _titleCtrl = TextEditingController(text: e?.title ?? '');

    // If previously saved with original currency/amount, restore it; otherwise default
    if (e != null) {
      if (e.originalCurrency == 'KHR' && e.originalAmount != null) {
        _inputCurrency = 'KHR';
        _amountCtrl = TextEditingController(
          text: NumberFormat('#,##0').format(e.originalAmount),
        );
      } else {
        _inputCurrency = 'USD';
        _amountCtrl = TextEditingController(text: e.amount.toString());
      }
    } else {
      _inputCurrency = widget.currency;
      _amountCtrl = TextEditingController();
    }

    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _selectedDate = e?.date ?? DateTime.now();
    _selectedWalletId = e?.walletId ??
        (widget.wallets.isNotEmpty ? widget.wallets.first.id : 'default_cash');

    if (e?.toWalletId != null) {
      _toWalletId = e!.toWalletId;
    } else if (widget.wallets.length > 1) {
      final other = widget.wallets.firstWhere((w) => w.id != _selectedWalletId);
      _toWalletId = other.id;
    } else {
      _toWalletId = null;
    }

    _selectedCategory = e?.category ??
        (_type == TxType.transfer ? 'ផ្ទេរប្រាក់' : _categoryList.first.name);
    _recurring = e?.isRecurring ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  List<Category> get _categoryList {
    final custom = widget.customCategories.where(
      (c) => _type == TxType.income ? !c.isExpense : c.isExpense,
    );
    final base = _type == TxType.income ? kIncomeCategories : kExpenseCategories;
    return [...custom, ...base];
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    String title = _titleCtrl.text.trim();
    final cleanInput = _amountCtrl.text.trim().replaceAll(',', '');
    final inputVal = double.tryParse(cleanInput);

    if (_type == TxType.transfer && title.isEmpty) {
      final fromW = widget.wallets.cast<Wallet?>().firstWhere(
            (w) => w?.id == _selectedWalletId,
            orElse: () => null,
          );
      final toW = widget.wallets.cast<Wallet?>().firstWhere(
            (w) => w?.id == _toWalletId,
            orElse: () => null,
          );
      title = widget.lang == 'km'
          ? 'ផ្ទេរពី ${fromW?.name ?? 'កាបូប'} ទៅ ${toW?.name ?? 'កាបូប'}'
          : 'Transfer from ${fromW?.name ?? 'Wallet'} to ${toW?.name ?? 'Wallet'}';
    }

    setState(() {
      _titleError = title.isEmpty
          ? (widget.lang == 'km' ? 'សូមបញ្ចូលឈ្មោះប្រតិបត្តិការ' : 'Please enter transaction title')
          : null;
      if (inputVal == null || inputVal <= 0) {
        _amountError = widget.lang == 'km'
            ? 'សូមបញ្ចូលចំនួនទឹកប្រាក់ត្រឹមត្រូវ (> 0)'
            : 'Please enter a valid amount (> 0)';
      } else {
        _amountError = null;
      }
    });

    if (_titleError != null || _amountError != null) return;

    if (_type == TxType.transfer && _selectedWalletId == _toWalletId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.lang == 'km'
                ? 'កាបូបផ្ទេរចេញ និងកាបូបទទួលមិនអាចដូចគ្នាបានទេ'
                : 'Source and destination wallets cannot be the same',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Convert to base USD amount
    final double baseUsdAmount;
    if (_inputCurrency == 'KHR') {
      baseUsdAmount = inputVal! / (widget.rate > 0 ? widget.rate : 4100.0);
    } else {
      baseUsdAmount = inputVal!;
    }

    final t = Transaction(
      id: widget.editing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      amount: baseUsdAmount,
      category: _type == TxType.transfer ? 'ផ្ទេរប្រាក់' : _selectedCategory,
      date: _selectedDate,
      type: _type,
      note: _noteCtrl.text.trim(),
      isRecurring: _recurring,
      walletId: _selectedWalletId,
      toWalletId: _type == TxType.transfer ? _toWalletId : null,
      originalCurrency: _inputCurrency,
      originalAmount: inputVal,
    );

    if (_isEditing) {
      widget.onUpdate(t);
    } else {
      widget.onAdd(t);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _type == TxType.income ? AppColors.income : AppColors.expense;
    return Container(
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
            Text(
              AppStrings.get(_isEditing ? 'edit_tx' : 'new_tx', widget.lang),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),

            // Type toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _typeTab(AppStrings.get('expense', widget.lang), TxType.expense, AppColors.expense),
                  _typeTab(AppStrings.get('income', widget.lang), TxType.income, AppColors.income),
                  _typeTab(AppStrings.get('transfer', widget.lang), TxType.transfer, AppColors.accent),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Wallet Selector: If transfer, show From and To wallets
            if (widget.wallets.isNotEmpty) ...[
              if (_type == TxType.transfer) ...[
                Text(
                  'ពីកាបូប (From Wallet)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.wallets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final w = widget.wallets[i];
                      final isSel = w.id == _selectedWalletId;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedWalletId = w.id;
                            if (_toWalletId == w.id) {
                              final other = widget.wallets.firstWhere((x) => x.id != w.id);
                              _toWalletId = other.id;
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? w.color : w.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(w.icon, size: 16, color: isSel ? Colors.white : w.color),
                              const SizedBox(width: 6),
                              Text(
                                w.name,
                                style: TextStyle(
                                  color: isSel ? Colors.white : w.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ទៅកាន់កាបូប (To Wallet)',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.wallets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final w = widget.wallets[i];
                      final isSel = w.id == _toWalletId;
                      final isSame = w.id == _selectedWalletId;
                      return InkWell(
                        onTap: isSame
                            ? null
                            : () => setState(() => _toWalletId = w.id),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.accent
                                : isSame
                                    ? Colors.grey.withValues(alpha: 0.05)
                                    : w.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                w.icon,
                                size: 16,
                                color: isSel
                                    ? Colors.white
                                    : isSame
                                        ? Colors.grey.shade400
                                        : w.color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                w.name,
                                style: TextStyle(
                                  color: isSel
                                      ? Colors.white
                                      : isSame
                                          ? Colors.grey.shade400
                                          : w.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  decoration: isSame ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                Text(
                  'កាបូបលុយ / គណនី',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.wallets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final w = widget.wallets[i];
                      final isSel = w.id == _selectedWalletId;
                      return InkWell(
                        onTap: () => setState(() => _selectedWalletId = w.id),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? w.color : w.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(w.icon, size: 16, color: isSel ? Colors.white : w.color),
                              const SizedBox(width: 6),
                              Text(
                                w.name,
                                style: TextStyle(
                                  color: isSel ? Colors.white : w.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 14),
            ],

            TextField(
              controller: _titleCtrl,
              decoration: _inputDecoration(
                'ឈ្មោះប្រតិបត្តិការ',
                errorText: _titleError,
              ),
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: _inputDecoration(
                      _inputCurrency == 'KHR' ? 'ចំនួនទឹកប្រាក់ (៛)' : 'ចំនួនទឹកប្រាក់ (\$)',
                      errorText: _amountError,
                    ),
                    onChanged: (_) {
                      setState(() {
                        if (_amountError != null) _amountError = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 54,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _currencyButton('USD', '\$'),
                      _currencyButton('KHR', '៛'),
                    ],
                  ),
                ),
              ],
            ),
            if (_amountCtrl.text.trim().isNotEmpty && _amountError == null) ...[
              Builder(
                builder: (context) {
                  final clean = _amountCtrl.text.trim().replaceAll(',', '');
                  final v = double.tryParse(clean);
                  if (v == null || v <= 0) return const SizedBox.shrink();
                  final String liveConversion;
                  if (_inputCurrency == 'KHR') {
                    final usd = v / (widget.rate > 0 ? widget.rate : 4100.0);
                    liveConversion = '≈ \$${usd.toStringAsFixed(2)} USD';
                  } else {
                    final khr = v * (widget.rate > 0 ? widget.rate : 4100.0);
                    liveConversion = '≈ ${NumberFormat('#,##0').format(khr)} ៛ KHR';
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      liveConversion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ],
            if (_type != TxType.transfer) ...[
              const SizedBox(height: 16),
              Text(
                'ប្រភេទ',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categoryList.map((c) {
                  final selected = c.name == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = c.name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? c.color : c.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            c.icon,
                            size: 16,
                            color: selected ? Colors.white : c.color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c.name,
                            style: TextStyle(
                              color: selected ? Colors.white : c.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: _inputDecoration('កំណត់ចំណាំ (មិនចាំបាច់)'),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18),
                    const SizedBox(width: 10),
                    Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _recurring,
              onChanged: (v) => setState(() => _recurring = v),
              title: const Text('កើតឡើងវិញរៀងរាល់ខែ', style: TextStyle(fontSize: 14)),
              secondary: Icon(Icons.autorenew_rounded, color: Colors.grey.shade500),
              activeThumbColor: accent,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isEditing
                      ? (widget.lang == 'km' ? 'កែប្រែ' : 'Update')
                      : AppStrings.get('save', widget.lang),
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _currencyButton(String code, String symbol) {
    final isSel = _inputCurrency == code;
    return GestureDetector(
      onTap: () {
        if (_inputCurrency != code) {
          final clean = _amountCtrl.text.trim().replaceAll(',', '');
          final val = double.tryParse(clean);
          setState(() {
            _inputCurrency = code;
            if (val != null && val > 0) {
              if (code == 'KHR') {
                final khr = val * (widget.rate > 0 ? widget.rate : 4100.0);
                _amountCtrl.text = khr.toStringAsFixed(0);
              } else {
                final usd = val / (widget.rate > 0 ? widget.rate : 4100.0);
                _amountCtrl.text = usd.toStringAsFixed(2);
              }
            }
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: isSel
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          symbol,
          style: TextStyle(
            color: isSel ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _typeTab(String label, TxType type, Color color) {
    final selected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          _selectedCategory = type == TxType.transfer
              ? 'ផ្ទេរប្រាក់'
              : (_categoryList.isNotEmpty ? _categoryList.first.name : 'ផ្សេងៗ');
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? errorText}) =>
      InputDecoration(
        labelText: label,
        errorText: errorText,
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      );
}
