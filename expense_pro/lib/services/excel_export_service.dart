import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/transaction.dart';
import '../models/wallet.dart';

class ExcelExportService {
  static Future<List<int>> generateExcelBytes({
    required List<Transaction> transactions,
    required List<Wallet> wallets,
    required double rate,
    DateTimeRange? dateRange,
  }) async {
    final excel = Excel.createExcel();

    // Default sheet is usually 'Sheet1'
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheet, 'ប្រតិបត្តិការ (Transactions)');
    final txSheet = excel['ប្រតិបត្តិការ (Transactions)'];

    // Filter by date range if provided
    final filtered = dateRange == null
        ? transactions
        : transactions.where((t) {
            return t.date.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) &&
                t.date.isBefore(dateRange.end.add(const Duration(days: 1)));
          }).toList();

    String getWalletName(String? walletId) {
      final match = wallets.cast<Wallet?>().firstWhere(
            (w) => w?.id == walletId,
            orElse: () => null,
          );
      return match?.name ?? 'សាច់ប្រាក់';
    }

    // 1. Setup Header Row for Transactions
    final headers = [
      'ល.រ',
      'កាលបរិច្ឆេទ',
      'ចំណងជើង',
      'ប្រភេទ (Type)',
      'ប្រភេទទំនិញ (Category)',
      'កាបូបលុយ (Wallet)',
      'ចំនួនទឹកប្រាក់ (\$ USD)',
      'ចំនួនទឹកប្រាក់ (៛ KHR)',
      'ចំណាំ (Note)',
    ];

    for (var col = 0; col < headers.length; col++) {
      final cell = txSheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1E293B'),
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
    }

    // 2. Fill Data Rows
    for (var i = 0; i < filtered.length; i++) {
      final t = filtered[i];
      final rowIndex = i + 1;
      final isIncome = t.type == TxType.income;
      final isTransfer = t.type == TxType.transfer;
      final typeLabel = isTransfer
          ? 'ផ្ទេរប្រាក់ (Transfer)'
          : isIncome
              ? 'ចំណូល (Income)'
              : 'ចំណាយ (Expense)';
      final amtUsd = t.amount;
      final amtKhr = t.amount * rate;

      txSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        ..value = IntCellValue(i + 1)
        ..cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Center);

      txSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        ..value = TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(t.date))
        ..cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Center);

      txSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(t.title);

      txSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
        ..value = TextCellValue(typeLabel)
        ..cellStyle = CellStyle(
          fontColorHex: isTransfer
              ? ExcelColor.fromHexString('#6366F1')
              : isIncome
                  ? ExcelColor.fromHexString('#15803D')
                  : ExcelColor.fromHexString('#B91C1C'),
          bold: true,
        );

      txSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(t.category);

      txSheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(
            isTransfer && t.toWalletId != null
                ? '${getWalletName(t.walletId)} ➔ ${getWalletName(t.toWalletId)}'
                : getWalletName(t.walletId),
          );

      txSheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
        ..value = DoubleCellValue(amtUsd)
        ..cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Right);

      txSheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
        ..value = DoubleCellValue(amtKhr)
        ..cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Right);

      txSheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(t.note);
    }

    // 3. Create Summary Sheet
    final summarySheet = excel['សង្ខេប (Summary)'];

    // Calculate Totals
    double totalIncome = 0;
    double totalExpense = 0;
    for (final t in filtered) {
      if (t.type == TxType.income) {
        totalIncome += t.amount;
      } else if (t.type == TxType.expense) {
        totalExpense += t.amount;
      }
    }
    final netBalance = totalIncome - totalExpense;

    // Summary Header
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue('របាយការណ៍សង្ខេប (Financial Summary)')
      ..cellStyle = CellStyle(bold: true, fontSize: 14);

    final summaryRows = [
      ['ចំណូលសរុប (Total Income)', totalIncome, totalIncome * rate],
      ['ចំណាយសរុប (Total Expense)', totalExpense, totalExpense * rate],
      ['សមតុល្យសុទ្ធ (Net Balance)', netBalance, netBalance * rate],
    ];

    final sumHeaders = ['ព័ត៌មាន', 'សរុប (\$ USD)', 'សរុប (៛ KHR)'];
    for (var col = 0; col < sumHeaders.length; col++) {
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 2))
        ..value = TextCellValue(sumHeaders[col])
        ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#334155'),
          fontColorHex: ExcelColor.white,
        );
    }

    for (var i = 0; i < summaryRows.length; i++) {
      final rIndex = 3 + i;
      final row = summaryRows[i];

      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rIndex))
        ..value = TextCellValue(row[0] as String)
        ..cellStyle = CellStyle(bold: true);

      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rIndex))
        ..value = DoubleCellValue(row[1] as double)
        ..cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Right);

      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rIndex))
        ..value = DoubleCellValue(row[2] as double)
        ..cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Right);
    }

    // Wallets table
    const walletStartRow = 8;
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: walletStartRow))
      ..value = TextCellValue('សមតុល្យតាមកាបូបនីមួយៗ (Wallets)')
      ..cellStyle = CellStyle(bold: true, fontSize: 13);

    final walletHeaders = ['ឈ្មោះកាបូប', 'សមតុល្យ (\$ USD)', 'សមតុល្យ (៛ KHR)'];
    for (var col = 0; col < walletHeaders.length; col++) {
      summarySheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: walletStartRow + 1),
      )
        ..value = TextCellValue(walletHeaders[col])
        ..cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#475569'),
          fontColorHex: ExcelColor.white,
        );
    }

    double getWalletBalance(Wallet wallet) {
      double bal = wallet.initialBalance;
      for (final t in transactions) {
        if (t.walletId == wallet.id) {
          if (t.type == TxType.income) {
            bal += t.amount;
          } else {
            bal -= t.amount;
          }
        }
      }
      return bal;
    }

    for (var i = 0; i < wallets.length; i++) {
      final w = wallets[i];
      final rIndex = walletStartRow + 2 + i;
      final bal = getWalletBalance(w);

      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rIndex))
        .value = TextCellValue(w.name);

      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rIndex))
        ..value = DoubleCellValue(bal)
        ..cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Right);

      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rIndex))
        ..value = DoubleCellValue(bal * rate)
        ..cellStyle = CellStyle(horizontalAlign: HorizontalAlign.Right);
    }

    final bytes = excel.encode();
    return bytes ?? [];
  }

  /// Export and share Excel file via share dialog
  static Future<void> exportAndShareExcel({
    required List<Transaction> transactions,
    required List<Wallet> wallets,
    required double rate,
    DateTimeRange? dateRange,
  }) async {
    final bytes = await generateExcelBytes(
      transactions: transactions,
      wallets: wallets,
      rate: rate,
      dateRange: dateRange,
    );

    if (bytes.isEmpty) return;

    final tempDir = await getTemporaryDirectory();
    final fileName =
        'expense_pro_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final filePath = '${tempDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: 'របាយការណ៍ហិរញ្ញវត្ថុ Expense Pro Excel',
        text: 'របាយការណ៍ហិរញ្ញវត្ថុ Expense Pro (Excel .xlsx)',
      ),
    );
  }
}
