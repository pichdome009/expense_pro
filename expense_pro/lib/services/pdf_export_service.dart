import 'dart:typed_data';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/transaction.dart';
import '../models/wallet.dart';

class PdfExportService {
  static Future<Uint8List> generatePdfBytes({
    required List<Transaction> transactions,
    required List<Wallet> wallets,
    required String currency,
    required double rate,
    DateTimeRange? dateRange,
  }) async {
    final pdf = pw.Document();

    // Load Kantumruy Pro font from Google Fonts for flawless Khmer text rendering
    final fontRegular = await PdfGoogleFonts.kantumruyProRegular();
    final fontBold = await PdfGoogleFonts.kantumruyProBold();

    // Filter by date range if provided
    final filtered = dateRange == null
        ? transactions
        : transactions.where((t) {
            return t.date.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) &&
                t.date.isBefore(dateRange.end.add(const Duration(days: 1)));
          }).toList();

    // Calculate totals
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

    String formatAmt(double amt) {
      if (currency == 'KHR') {
        return '${NumberFormat('#,###').format(amt * rate)} ៛';
      }
      return '\$${amt.toStringAsFixed(2)}';
    }

    String getWalletName(String? walletId) {
      final match = wallets.cast<Wallet?>().firstWhere(
            (w) => w?.id == walletId,
            orElse: () => null,
          );
      return match?.name ?? 'សាច់ប្រាក់';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Expense Pro',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 22,
                          color: PdfColors.indigo900,
                        ),
                      ),
                      pw.Text(
                        'របាយការណ៍សង្ខេបហិរញ្ញវត្ថុ',
                        style: const pw.TextStyle(
                          fontSize: 13,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'កាលបរិច្ឆេទបង្កើត:',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                        style: pw.TextStyle(font: fontBold, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.indigo100, thickness: 1.5),
              pw.SizedBox(height: 12),
            ],
          );
        },
        footer: (context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Expense Pro - របាយការណ៍ចំណូលចំណាយ',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
              pw.Text(
                'ទំព័រ ${context.pageNumber} នៃ ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          );
        },
        build: (context) {
          return [
            // Period badge
            if (dateRange != null)
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 12),
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'កាលបរិច្ឆេទ: ${DateFormat('dd/MM/yyyy').format(dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(dateRange.end)}',
                  style: pw.TextStyle(fontSize: 10, font: fontBold),
                ),
              ),

            // Summary Cards Row
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildSummaryBox(
                    title: 'ចំណូលសរុប',
                    amount: formatAmt(totalIncome),
                    color: PdfColors.green700,
                    bgColor: PdfColors.green50,
                    fontBold: fontBold,
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _buildSummaryBox(
                    title: 'ចំណាយសរុប',
                    amount: formatAmt(totalExpense),
                    color: PdfColors.red700,
                    bgColor: PdfColors.red50,
                    fontBold: fontBold,
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: _buildSummaryBox(
                    title: 'សមតុល្យសុទ្ធ',
                    amount: formatAmt(netBalance),
                    color: netBalance >= 0 ? PdfColors.blue700 : PdfColors.orange700,
                    bgColor: netBalance >= 0 ? PdfColors.blue50 : PdfColors.orange50,
                    fontBold: fontBold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Transactions Table
            pw.Text(
              'បញ្ជីប្រតិបត្តិការ (${filtered.length})',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 13,
                color: PdfColors.grey800,
              ),
            ),
            pw.SizedBox(height: 8),

            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['ល.រ', 'កាលបរិច្ឆេទ', 'ចំណងជើង', 'ប្រភេទ', 'កាបូប', 'ចំនួនទឹកប្រាក់', 'ចំណាំ'],
              headerStyle: pw.TextStyle(
                font: fontBold,
                fontSize: 9,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.indigo800,
              ),
              headerHeight: 24,
              cellHeight: 22,
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellAlignment: pw.Alignment.centerLeft,
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                5: pw.Alignment.centerRight,
              },
              data: List.generate(filtered.length, (i) {
                final t = filtered[i];
                final isIncome = t.type == TxType.income;
                final isTransfer = t.type == TxType.transfer;
                final sign = isTransfer ? '⇄' : (isIncome ? '+' : '-');
                final walletStr = isTransfer && t.toWalletId != null
                    ? '${getWalletName(t.walletId)} ➔ ${getWalletName(t.toWalletId)}'
                    : getWalletName(t.walletId);
                return [
                  '${i + 1}',
                  DateFormat('dd/MM/yy').format(t.date),
                  t.title,
                  isTransfer ? 'ផ្ទេរប្រាក់' : t.category,
                  walletStr,
                  '$sign ${formatAmt(t.amount)}',
                  t.note.isNotEmpty ? t.note : '-',
                ];
              }),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryBox({
    required String title,
    required String amount,
    required PdfColor color,
    required PdfColor bgColor,
    required pw.Font fontBold,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            amount,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Print or show preview sheet
  static Future<void> printOrPreviewPdf({
    required List<Transaction> transactions,
    required List<Wallet> wallets,
    required String currency,
    required double rate,
    DateTimeRange? dateRange,
  }) async {
    await Printing.layoutPdf(
      name: 'expense_pro_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      onLayout: (format) => generatePdfBytes(
        transactions: transactions,
        wallets: wallets,
        currency: currency,
        rate: rate,
        dateRange: dateRange,
      ),
    );
  }

  /// Share PDF file directly
  static Future<void> sharePdf({
    required List<Transaction> transactions,
    required List<Wallet> wallets,
    required String currency,
    required double rate,
    DateTimeRange? dateRange,
  }) async {
    final bytes = await generatePdfBytes(
      transactions: transactions,
      wallets: wallets,
      currency: currency,
      rate: rate,
      dateRange: dateRange,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'expense_pro_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }
}
