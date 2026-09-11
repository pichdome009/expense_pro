import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/saving_goal.dart';
import '../utils/formatters.dart';

class SavingsManagerModal extends StatefulWidget {
  final List<SavingGoal> goals;
  final String currency;
  final double rate;
  final ValueChanged<List<SavingGoal>> onGoalsChanged;

  const SavingsManagerModal({
    super.key,
    required this.goals,
    required this.currency,
    required this.rate,
    required this.onGoalsChanged,
  });

  @override
  State<SavingsManagerModal> createState() => _SavingsManagerModalState();
}

class _SavingsManagerModalState extends State<SavingsManagerModal> {
  late List<SavingGoal> _goals;

  @override
  void initState() {
    super.initState();
    _goals = List<SavingGoal>.from(widget.goals);
  }

  void _showAddGoalDialog() {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final currentCtrl = TextEditingController();
    IconData selectedIcon = Icons.savings_rounded;
    Color selectedColor = const Color(0xFF10B981);

    final availableIcons = [
      Icons.savings_rounded,
      Icons.laptop_mac_rounded,
      Icons.directions_car_rounded,
      Icons.home_rounded,
      Icons.flight_takeoff_rounded,
      Icons.smartphone_rounded,
      Icons.fitness_center_rounded,
      Icons.school_rounded,
    ];

    final availableColors = [
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF06B6D4),
    ];

    showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('បង្កើតគោលដៅសន្សំថ្មី'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'ឈ្មោះគោលដៅ (ឧ. ទិញកុំព្យូទ័រ)',
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
                  controller: targetCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'ចំនួនទឹកប្រាក់គោលដៅ (\$)',
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
                  controller: currentCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'សន្សំបានដំបូង (\$) (មិនចាំបាច់)',
                    filled: true,
                    fillColor: Colors.grey.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('ជ្រើសរើស Icon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: availableIcons.map((ic) {
                    final isSel = ic == selectedIcon;
                    return InkWell(
                      onTap: () => setDState(() => selectedIcon = ic),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel ? selectedColor : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(ic, size: 20, color: isSel ? Colors.white : Colors.grey.shade600),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                const Text('ជ្រើសរើស ពណ៌', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: availableColors.map((col) {
                    final isSel = col == selectedColor;
                    return InkWell(
                      onTap: () => setDState(() => selectedColor = col),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: col,
                          shape: BoxShape.circle,
                          border: isSel ? Border.all(color: Colors.white, width: 2.5) : null,
                          boxShadow: isSel ? [BoxShadow(color: col.withValues(alpha: 0.5), blurRadius: 6)] : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('បោះបង់'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                final title = titleCtrl.text.trim();
                final target = double.tryParse(targetCtrl.text.trim().replaceAll(',', '')) ?? 0.0;
                final cur = double.tryParse(currentCtrl.text.trim().replaceAll(',', '')) ?? 0.0;
                if (title.isNotEmpty && target > 0) {
                  final newGoal = SavingGoal(
                    id: 'goal_${DateTime.now().microsecondsSinceEpoch}',
                    title: title,
                    targetAmount: target,
                    currentAmount: cur,
                    icon: selectedIcon,
                    color: selectedColor,
                  );
                  setState(() => _goals.add(newGoal));
                  widget.onGoalsChanged(_goals);
                  Navigator.pop(dctx);
                }
              },
              child: const Text('បង្កើត'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDepositDialog(SavingGoal goal) {
    final amtCtrl = TextEditingController();
    bool isWithdraw = false;

    showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isWithdraw ? 'ដកប្រាក់ពី "${goal.title}"' : 'សន្សំប្រាក់ចូល "${goal.title}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('ដាក់ប្រាក់ (+)', style: TextStyle(fontSize: 12)),
                      selected: !isWithdraw,
                      selectedColor: AppColors.primary,
                      onSelected: (val) => setDState(() => isWithdraw = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('ដកប្រាក់ (-)', style: TextStyle(fontSize: 12)),
                      selected: isWithdraw,
                      selectedColor: Colors.red,
                      onSelected: (val) => setDState(() => isWithdraw = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amtCtrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'ចំនួនទឹកប្រាក់ (\$)',
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('បោះបង់'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: isWithdraw ? Colors.red : AppColors.primary),
              onPressed: () {
                final amt = double.tryParse(amtCtrl.text.trim().replaceAll(',', '')) ?? 0.0;
                if (amt > 0) {
                  final newCur = isWithdraw
                      ? (goal.currentAmount - amt).clamp(0.0, double.infinity)
                      : (goal.currentAmount + amt);
                  final idx = _goals.indexWhere((g) => g.id == goal.id);
                  if (idx != -1) {
                    setState(() {
                      _goals[idx] = goal.copyWith(currentAmount: newCur);
                    });
                    widget.onGoalsChanged(_goals);
                  }
                  Navigator.pop(dctx);
                }
              },
              child: Text(isWithdraw ? 'ដកប្រាក់' : 'ដាក់ប្រាក់'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 22,
        right: 22,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
      ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.savings_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'គោលដៅសន្សំប្រាក់ (Savings Goals)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 28),
                onPressed: _showAddGoalDialog,
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_goals.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.savings_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'មិនទាន់មានគោលដៅសន្សំនៅឡើយទេ\nចុចសញ្ញា (+) ខាងលើដើម្បីបង្កើតគោលដៅដំបូងរបស់អ្នក!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _goals.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final goal = _goals[i];
                  final progress = goal.progress;
                  final isDone = goal.isCompleted;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: goal.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(goal.icon, color: goal.color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          goal.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
                                      if (isDone)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text('ជោគជ័យ 🎉', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${formatCurrency(goal.currentAmount, widget.currency, widget.rate)} / ${formatCurrency(goal.targetAmount, widget.currency, widget.rate)} (${(progress * 100).toStringAsFixed(0)}%)',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                              onPressed: () {
                                setState(() => _goals.removeAt(i));
                                widget.onGoalsChanged(_goals);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.grey.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(goal.color),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                              label: const Text('ដាក់ / ដកប្រាក់', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => _showDepositDialog(goal),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
