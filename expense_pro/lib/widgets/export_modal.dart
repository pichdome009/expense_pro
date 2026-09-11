import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_colors.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../services/excel_export_service.dart';
import '../services/pdf_export_service.dart';

class ExportModal extends StatefulWidget {
  final List<Transaction> transactions;
  final List<Wallet> wallets;
  final String currency;
  final double rate;

  const ExportModal({
    super.key,
    required this.transactions,
    required this.wallets,
    required this.currency,
    required this.rate,
  });

  @override
  State<ExportModal> createState() => _ExportModalState();
}

enum _ExportPeriod { thisMonth, allTime, custom }

class _ExportModalState extends State<ExportModal> {
  _ExportPeriod _period = _ExportPeriod.thisMonth;
  DateTimeRange? _customDateRange;
  bool _isExporting = false;

  DateTimeRange? get _activeRange {
    if (_period == _ExportPeriod.allTime) return null;
    if (_period == _ExportPeriod.thisMonth) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      return DateTimeRange(start: start, end: end);
    }
    return _customDateRange;
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _period = _ExportPeriod.custom;
      });
    }
  }

  Future<void> _exportPdf({bool previewOnly = false}) async {
    setState(() => _isExporting = true);
    try {
      if (previewOnly) {
        await PdfExportService.printOrPreviewPdf(
          transactions: widget.transactions,
          wallets: widget.wallets,
          currency: widget.currency,
          rate: widget.rate,
          dateRange: _activeRange,
        );
      } else {
        await PdfExportService.sharePdf(
          transactions: widget.transactions,
          wallets: widget.wallets,
          currency: widget.currency,
          rate: widget.rate,
          dateRange: _activeRange,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('បរាជ័យក្នុងការនាំចេញ PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportExcel() async {
    setState(() => _isExporting = true);
    try {
      await ExcelExportService.exportAndShareExcel(
        transactions: widget.transactions,
        wallets: widget.wallets,
        rate: widget.rate,
        dateRange: _activeRange,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('បរាជ័យក្នុងការនាំចេញ Excel: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isExporting = true);
    try {
      final range = _activeRange;
      final filtered = range == null
          ? widget.transactions
          : widget.transactions.where((t) {
              return t.date.isAfter(range.start.subtract(const Duration(seconds: 1))) &&
                  t.date.isBefore(range.end.add(const Duration(days: 1)));
            }).toList();

      final buffer = StringBuffer(
        'ល.រ,កាលបរិច្ឆេទ,ចំណងជើង,ប្រភេទ,ប្រភេទទំនិញ,កាបូបលុយ,ចំនួនទឹកប្រាក់ USD,ចំនួនទឹកប្រាក់ KHR,ចំណាំ\n',
      );

      String getWalletName(String? walletId) {
        final match = widget.wallets.cast<Wallet?>().firstWhere(
              (w) => w?.id == walletId,
              orElse: () => null,
            );
        return match?.name ?? 'សាច់ប្រាក់';
      }

      for (var i = 0; i < filtered.length; i++) {
        final t = filtered[i];
        final typeLabel = t.type == TxType.transfer
            ? 'ផ្ទេរប្រាក់'
            : t.type == TxType.income
                ? 'ចំណូល'
                : 'ចំណាយ';
        final walletLabel = t.type == TxType.transfer && t.toWalletId != null
            ? '${getWalletName(t.walletId)} -> ${getWalletName(t.toWalletId)}'
            : getWalletName(t.walletId);
        final amtKhr = (t.amount * widget.rate).toStringAsFixed(0);
        buffer.writeln(
          '${i + 1},"${DateFormat('yyyy-MM-dd HH:mm').format(t.date)}","${t.title}","$typeLabel","${t.category}","$walletLabel",${t.amount},$amtKhr,"${t.note.replaceAll('"', '""')}"',
        );
      }

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/expense_pro_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File(filePath);
      await file.writeAsString(buffer.toString(), flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'របាយការណ៍ Expense Pro CSV',
          text: 'ទិន្នន័យប្រតិបត្តិការ Expense Pro (CSV)',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('បរាជ័យក្នុងការនាំចេញ CSV: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
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
          // Drag Handle
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
              const Text(
                'នាំចេញទិន្នន័យ (Export)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (_isExporting)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Period Selector
          const Text(
            'ជ្រើសរើសចន្លោះកាលបរិច្ឆេទ',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _periodChip('ខែនេះ', _ExportPeriod.thisMonth),
                const SizedBox(width: 8),
                _periodChip('ទិន្នន័យទាំងអស់', _ExportPeriod.allTime),
                const SizedBox(width: 8),
                ActionChip(
                  avatar: const Icon(Icons.date_range_rounded, size: 16),
                  label: Text(
                    _period == _ExportPeriod.custom && _customDateRange != null
                        ? '${DateFormat('dd/MM').format(_customDateRange!.start)} - ${DateFormat('dd/MM').format(_customDateRange!.end)}'
                        : 'កំណត់ថ្ងៃ...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _period == _ExportPeriod.custom
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _period == _ExportPeriod.custom
                          ? AppColors.primary
                          : null,
                    ),
                  ),
                  backgroundColor: _period == _ExportPeriod.custom
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: _period == _ExportPeriod.custom
                          ? AppColors.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  onPressed: _pickCustomDateRange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Option 1: PDF
          _exportOptionCard(
            isDark: isDark,
            icon: Icons.picture_as_pdf_rounded,
            iconColor: Colors.red.shade600,
            iconBg: Colors.red.shade50,
            title: 'របាយការណ៍ PDF (PDF Statement)',
            subtitle: 'របាយការណ៍ផ្លូវការ មានតារាងទិន្នន័យ និងសង្ខេបចំណូលចំណាយ',
            actions: [
              OutlinedButton.icon(
                onPressed: _isExporting ? null : () => _exportPdf(previewOnly: true),
                icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                label: const Text('មើលជាមុន'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isExporting ? null : () => _exportPdf(previewOnly: false),
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text('ចែករំលែក PDF'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Option 2: Excel
          _exportOptionCard(
            isDark: isDark,
            icon: Icons.table_chart_rounded,
            iconColor: const Color(0xFF107C41),
            iconBg: const Color(0xFFE8F5E9),
            title: 'សៀវភៅបញ្ជី Excel (.xlsx)',
            subtitle: 'ឯកសារ Microsoft Excel មាន ២ Sheets (Transactions & Summary)',
            actions: [
              FilledButton.icon(
                onPressed: _isExporting ? null : _exportExcel,
                icon: const Icon(Icons.ios_share_rounded, size: 16),
                label: const Text('នាំចេញជា Excel (.xlsx)'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF107C41),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Option 3: CSV
          _exportOptionCard(
            isDark: isDark,
            icon: Icons.insert_drive_file_rounded,
            iconColor: Colors.blue.shade600,
            iconBg: Colors.blue.shade50,
            title: 'ឯកសារ CSV (.csv)',
            subtitle: 'ទម្រង់ឯកសារទិន្នន័យដើម ងាយស្រួលនាំចូលកម្មវិធីផ្សេងៗ',
            actions: [
              OutlinedButton.icon(
                onPressed: _isExporting ? null : _exportCsv,
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text('ចែករំលែក CSV'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodChip(String label, _ExportPeriod period) {
    final isSelected = _period == period;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
      onSelected: (selected) {
        if (selected) {
          setState(() => _period = period);
        }
      },
    );
  }

  Widget _exportOptionCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required List<Widget> actions,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? iconColor.withValues(alpha: 0.15) : iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: actions,
          ),
        ],
      ),
    );
  }
}
