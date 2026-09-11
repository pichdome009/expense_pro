import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../services/security_service.dart';
import '../widgets/pin_setup_dialog.dart';

class SettingsSheet extends StatefulWidget {
  final bool isDark;
  final void Function(bool) onToggleTheme;
  final String currency;
  final double rate;
  final double monthlyBudget;
  final void Function(String) onSetCurrency;
  final void Function(double) onSetRate;
  final void Function(double) onSetBudget;
  final VoidCallback onExport;
  final VoidCallback onClearAll;
  final VoidCallback onOpenCategoryManager;
  final VoidCallback onOpenCategoryBudgets;
  final VoidCallback onOpenSavingsGoals;
  final VoidCallback onOpenDebtTracker;
  final String lang;
  final void Function(String) onSetLanguage;
  final VoidCallback? onSecurityChanged;
  final VoidCallback? onDataRestored;

  const SettingsSheet({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.currency,
    required this.rate,
    required this.monthlyBudget,
    required this.onSetCurrency,
    required this.onSetRate,
    required this.onSetBudget,
    required this.onExport,
    required this.onClearAll,
    required this.onOpenCategoryManager,
    required this.onOpenCategoryBudgets,
    required this.onOpenSavingsGoals,
    required this.onOpenDebtTracker,
    this.lang = 'km',
    required this.onSetLanguage,
    this.onSecurityChanged,
    this.onDataRestored,
  });

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late TextEditingController _budgetCtrl;
  late TextEditingController _rateCtrl;
  late String _currentCurrency;
  late String _currentLang;
  bool _appLockEnabled = false;
  bool _biometricsEnabled = false;
  bool _canCheckBio = false;
  bool _dailyReminderEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _budgetAlertsEnabled = true;

  @override
  void initState() {
    super.initState();
    _currentCurrency = widget.currency;
    _currentLang = widget.lang;
    _budgetCtrl = TextEditingController(
      text: widget.monthlyBudget > 0 ? widget.monthlyBudget.toStringAsFixed(2) : '',
    );
    _rateCtrl = TextEditingController(text: widget.rate.toStringAsFixed(0));

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final lock = await SecurityService.isAppLockEnabled();
    final bio = await SecurityService.isBiometricsEnabled();
    final canBio = await SecurityService.canCheckBiometrics();
    final daily = await NotificationService.isDailyReminderEnabled();
    final h = await NotificationService.getDailyReminderHour();
    final m = await NotificationService.getDailyReminderMinute();
    final budgetAlert = await NotificationService.isBudgetAlertsEnabled();

    if (mounted) {
      setState(() {
        _appLockEnabled = lock;
        _biometricsEnabled = bio;
        _canCheckBio = canBio;
        _dailyReminderEnabled = daily;
        _reminderTime = TimeOfDay(hour: h, minute: m);
        _budgetAlertsEnabled = budgetAlert;
      });
    }
  }

  @override
  void didUpdateWidget(covariant SettingsSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currency != widget.currency) {
      _currentCurrency = widget.currency;
    }
    if (oldWidget.lang != widget.lang) {
      _currentLang = widget.lang;
    }
  }

  @override
  void dispose() {
    _budgetCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              'ការកំណត់',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: widget.isDark,
              onChanged: widget.onToggleTheme,
              title: Text(_currentLang == 'km' ? 'របៀបងងឹត (Dark Mode)' : 'Dark Mode'),
              secondary: const Icon(Icons.dark_mode_rounded),
              activeThumbColor: AppColors.primary,
            ),
            const Divider(),

            Text(
              _currentLang == 'km' ? 'ភាសា (Language)' : 'Language',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _langTab('ភាសាខ្មែរ 🇰🇭', 'km')),
                const SizedBox(width: 10),
                Expanded(child: _langTab('English 🇺🇸', 'en')),
              ],
            ),
            const Divider(),

            const Text(
              'រូបិយប័ណ្ណបង្ហាញ',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _currencyTab('USD (\$)', 'USD')),
                const SizedBox(width: 10),
                Expanded(child: _currencyTab('KHR (៛)', 'KHR')),
              ],
            ),
            if (_currentCurrency == 'KHR') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _rateCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'អត្រាប្តូរប្រាក់ (1\$ = ? ៛)',
                  filled: true,
                  fillColor: Colors.grey.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) {
                  final r = double.tryParse(v.trim());
                  if (r != null && r > 0) widget.onSetRate(r);
                },
                onSubmitted: (v) {
                  final r = double.tryParse(v.trim());
                  if (r != null && r > 0) widget.onSetRate(r);
                },
              ),
            ],
            const SizedBox(height: 20),

            const Text(
              'ថវិកាប្រចាំខែសរុប',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _budgetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'ថវិកា (\$)',
                filled: true,
                fillColor: Colors.grey.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                final sanitized = v.trim().replaceAll(',', '.');
                final b = double.tryParse(sanitized);
                if (b != null && b >= 0) {
                  widget.onSetBudget(b);
                } else if (v.trim().isEmpty) {
                  widget.onSetBudget(0.0);
                }
              },
              onSubmitted: (v) {
                final sanitized = v.trim().replaceAll(',', '.');
                final b = double.tryParse(sanitized) ?? 0.0;
                widget.onSetBudget(b);
              },
            ),
            const SizedBox(height: 20),

            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.category_rounded, color: AppColors.accent),
              title: const Text('គ្រប់គ្រងប្រភេទ (Custom Categories)'),
              subtitle: const Text('បង្កើតប្រភេទចំណូល និងចំណាយថ្មីៗ', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: widget.onOpenCategoryManager,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.pie_chart_rounded, color: AppColors.primary),
              title: const Text('ថវិកាតាមប្រភេទ (Category Budgets)'),
              subtitle: const Text('កំណត់កម្រិតចំណាយសម្រាប់ប្រភេទនីមួយៗ', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: widget.onOpenCategoryBudgets,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.savings_rounded, color: AppColors.income),
              title: Text(_currentLang == 'km' ? 'គោលដៅសន្សំប្រាក់ (Savings Goals)' : 'Savings Goals & Piggy Bank'),
              subtitle: Text(_currentLang == 'km' ? 'កំណត់គោលដៅសន្សំ និងកូនជ្រូកសន្សំប្រាក់' : 'Manage your saving targets', style: const TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenSavingsGoals();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.handshake_rounded, color: Colors.indigo),
              title: Text(_currentLang == 'km' ? 'តាមដានបំណុល និងលុយខ្ចី (Debt & Loan)' : 'Debt & Loan Tracker'),
              subtitle: Text(_currentLang == 'km' ? 'កត់ត្រាលុយខ្ចីគេ និងលុយគេខ្ចី' : 'Track money lent and borrowed', style: const TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
                widget.onOpenDebtTracker();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.widgets_rounded, color: Colors.teal),
              title: Text(_currentLang == 'km' ? 'Widget & ផ្លូវកាត់លើអេក្រង់ (Widget & Shortcuts)' : 'Home Screen Widget & Shortcuts'),
              subtitle: Text(_currentLang == 'km' ? 'របៀបដាក់ Widget និងផ្លូវកាត់ប្រតិបត្តិការរហ័ស' : 'How to use quick widgets and shortcuts', style: const TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    title: Row(
                      children: [
                        const Icon(Icons.widgets_rounded, color: Colors.teal),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _currentLang == 'km' ? 'Widget លើអេក្រង់' : 'Home Screen Widget',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentLang == 'km'
                              ? '📱 របៀបដាក់ Widget លើអេក្រង់ទូរស័ព្ទ (Android):\n1. ចុចសង្កត់លើអេក្រង់ទូរស័ព្ទ (Home screen)\n2. ជ្រើសរើស "Widgets"\n3. ស្វែងរក "ExpensePro" រួចអូសដាក់លើអេក្រង់\n\n⚡ ផ្លូវកាត់រហ័ស (Quick Shortcuts):\n• ចុចសង្កត់ (Long-press) លើរូប Icon កម្មវិធី ដើម្បីបើក "កត់ត្រាថ្មី", "ស្ថិតិ" ឬ "បំណុល" ភ្លាមៗ!'
                              : '📱 How to add the Home Screen Widget:\n1. Long-press on your device Home screen\n2. Select "Widgets"\n3. Locate "ExpensePro" and drag it onto your screen\n\n⚡ Quick App Shortcuts:\n• Long-press the ExpensePro app icon to directly launch "Add Transaction", "Statistics", or "Debt Tracker"!',
                          style: const TextStyle(fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(_currentLang == 'km' ? 'យល់ព្រម' : 'OK'),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'សុវត្ថិភាព និងការចាក់សោ (Security)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
              title: const Text('ចាក់សោកម្មវិធី (App Lock)'),
              subtitle: const Text('ការពារទិន្នន័យដោយលេខកូដ PIN', style: TextStyle(fontSize: 11)),
              value: _appLockEnabled,
              onChanged: (val) async {
                if (val) {
                  final hasPin = await SecurityService.hasPinCode();
                  if (!hasPin) {
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (_) => PinSetupDialog(
                          onPinSet: () {
                            setState(() => _appLockEnabled = true);
                            widget.onSecurityChanged?.call();
                          },
                        ),
                      );
                    }
                  } else {
                    await SecurityService.setAppLockEnabled(true);
                    setState(() => _appLockEnabled = true);
                    widget.onSecurityChanged?.call();
                  }
                } else {
                  await SecurityService.setAppLockEnabled(false);
                  setState(() => _appLockEnabled = false);
                  widget.onSecurityChanged?.call();
                }
              },
            ),
            if (_appLockEnabled && _canCheckBio)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                title: const Text('Face ID / ស្នាមម្រាមដៃ'),
                subtitle: const Text('ដោះសោរហ័សដោយជីវមាត្រ', style: TextStyle(fontSize: 11)),
                value: _biometricsEnabled,
                onChanged: (val) async {
                  await SecurityService.setBiometricsEnabled(val);
                  setState(() => _biometricsEnabled = val);
                },
              ),
            if (_appLockEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.pin_outlined, color: AppColors.primary),
                title: const Text('ប្តូរលេខកូដ PIN ថ្មី'),
                subtitle: const Text('ផ្លាស់ប្តូរលេខសម្ងាត់ ៤ ខ្ទង់', style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => PinSetupDialog(
                      onPinSet: () {
                        widget.onSecurityChanged?.call();
                      },
                    ),
                  );
                },
              ),

            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'ការជូនដំណឹង (Notifications & Reminders)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
              title: const Text('រំលឹកកត់ត្រាចំណាយប្រចាំថ្ងៃ'),
              subtitle: const Text('«តើថ្ងៃនេះអ្នកបានចំណាយអ្វីខ្លះ? កុំភ្លេចកត់ត្រាទុកណា៎!»', style: TextStyle(fontSize: 11)),
              value: _dailyReminderEnabled,
              onChanged: (val) async {
                if (val) {
                  await NotificationService.requestPermissions();
                  await NotificationService.setDailyReminderEnabled(true);
                  await NotificationService.scheduleDailyReminder(
                    hour: _reminderTime.hour,
                    minute: _reminderTime.minute,
                  );
                } else {
                  await NotificationService.setDailyReminderEnabled(false);
                  await NotificationService.cancelDailyReminder();
                }
                setState(() => _dailyReminderEnabled = val);
              },
            ),
            if (_dailyReminderEnabled)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time_rounded, color: AppColors.primary),
                title: const Text('ម៉ោងរំលឹកប្រចាំថ្ងៃ'),
                subtitle: Text(
                  _reminderTime.format(context),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime,
                  );
                  if (picked != null) {
                    setState(() => _reminderTime = picked);
                    await NotificationService.setDailyReminderTime(picked.hour, picked.minute);
                    await NotificationService.scheduleDailyReminder(
                      hour: picked.hour,
                      minute: picked.minute,
                    );
                  }
                },
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.warning_amber_rounded, color: AppColors.primary),
              title: const Text('ការជូនដំណឹងពីកញ្ចប់ថវិកា (Budget Alerts)'),
              subtitle: const Text('Push Notification ពេលចំណាយជិតដល់ 80% ឬលើស 100%', style: TextStyle(fontSize: 11)),
              value: _budgetAlertsEnabled,
              onChanged: (val) async {
                if (val) {
                  await NotificationService.requestPermissions();
                }
                await NotificationService.setBudgetAlertsEnabled(val);
                setState(() => _budgetAlertsEnabled = val);
              },
            ),

            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'ទិន្នន័យ និងការបម្រុងទុក (Data & Backup)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.cloud_upload_outlined,
                color: AppColors.primary,
              ),
              title: const Text('បម្រុងទុកទិន្នន័យ (Cloud / Drive Backup)'),
              subtitle: const Text('រក្សាទុកឯកសារ Backup .json ទៅ Google Drive ឬ Files', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                try {
                  await BackupService.shareBackupFile();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('បរាជ័យក្នុងការ Backup: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.settings_backup_restore_rounded,
                color: Colors.teal,
              ),
              title: const Text('ស្តារទិន្នន័យឡើងវិញ (Restore Data)'),
              subtitle: const Text('នាំចូលទិន្នន័យពីឯកសារ Backup .json', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showRestoreDialog(context),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.file_download_outlined,
                color: AppColors.primary,
              ),
              title: const Text('នាំចេញរបាយការណ៍ (Export PDF / Excel / CSV)'),
              subtitle: const Text('ទាញយករបាយការណ៍ជា PDF, Excel ឬ CSV', style: TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: widget.onExport,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.red,
              ),
              title: Text(
                _currentLang == 'km' ? 'លុបទិន្នន័យទាំងអស់' : 'Clear All Data',
                style: const TextStyle(color: Colors.red),
              ),
              onTap: widget.onClearAll,
            ),

            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
              title: Text(_currentLang == 'km' ? 'អំពីកម្មវិធី (About)' : 'About ExpensePro'),
              subtitle: Text(
                _currentLang == 'km'
                    ? 'កំណែ 1.0.0 · Develop by PICH UDOM'
                    : 'Version 1.0.0 · Develop by PICH UDOM',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.accent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ExpensePro',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version 1.0.0',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.code_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text(
                                'Develop by PICH UDOM',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _currentLang == 'km'
                              ? 'កម្មវិធីគ្រប់គ្រងចំណូល ចំណាយ ថវិកា គោលដៅសន្សំប្រាក់ និងបំណុល យ៉ាងឆ្លាតវៃ និងមានសុវត្ថិភាពខ្ពស់។'
                              : 'Smart, secure, and modern personal finance manager with multi-wallet, savings, and debt tracking.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(_currentLang == 'km' ? 'បិទ' : 'Close'),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    'ExpensePro v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_rounded, size: 13, color: Colors.red.shade400),
                      const SizedBox(width: 5),
                      Text(
                        'Develop by PICH UDOM',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _currencyTab(String label, String value) {
    final selected = _currentCurrency == value;
    return GestureDetector(
      onTap: () {
        setState(() => _currentCurrency = value);
        widget.onSetCurrency(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _langTab(String label, String value) {
    final selected = _currentLang == value;
    return GestureDetector(
      onTap: () {
        setState(() => _currentLang = value);
        widget.onSetLanguage(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    final jsonCtrl = TextEditingController();
    String? errorMsg;

    showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.settings_backup_restore_rounded, color: Colors.teal),
              SizedBox(width: 10),
              Text('ស្តារទិន្នន័យ (Restore)'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'សូមបិទភ្ជាប់ (Paste) កូដ Backup JSON របស់អ្នកនៅខាងក្រោម ដើម្បីស្តារទិន្នន័យត្រឡប់មកវិញ៖',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: jsonCtrl,
                maxLines: 6,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: '{\n  "version": 1,\n  "app": "Expense Pro",\n  ...\n}',
                  errorText: errorMsg,
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
              style: FilledButton.styleFrom(backgroundColor: Colors.teal),
              onPressed: () async {
                final text = jsonCtrl.text.trim();
                if (text.isEmpty) {
                  setDState(() => errorMsg = 'សូមបញ្ចូលទិន្នន័យ JSON');
                  return;
                }
                try {
                  final backupData = BackupService.parseBackupJson(text);
                  await BackupService.restoreFromBackup(backupData);
                  if (dctx.mounted) Navigator.pop(dctx);
                  if (context.mounted) {
                    Navigator.pop(context); // close settings sheet
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'បានស្តារទិន្នន័យជោគជ័យ! (${backupData.transactions.length} ប្រតិបត្តិការ, ${backupData.wallets.length} កាបូប)',
                        ),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  }
                  widget.onDataRestored?.call();
                } catch (e) {
                  setDState(() => errorMsg = 'ឯកសារ JSON មិនត្រឹមត្រូវ: $e');
                }
              },
              child: const Text('ស្តារទិន្នន័យ'),
            ),
          ],
        ),
      ),
    );
  }
}
