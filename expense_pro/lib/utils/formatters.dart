import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';
import '../models/transaction.dart';

String formatCurrency(double usdAmount, String currency, double rate) {
  final isNegative = usdAmount < 0;
  final absAmount = usdAmount.abs();
  if (currency == 'KHR') {
    final khr = absAmount * rate;
    final formatted = '${NumberFormat('#,##0').format(khr)} ៛';
    return isNegative ? '-$formatted' : formatted;
  }
  final formatted = '\$${absAmount.toStringAsFixed(2)}';
  return isNegative ? '-$formatted' : formatted;
}

String greetingForNow([String lang = 'km']) {
  final h = DateTime.now().hour;
  if (lang == 'en') {
    if (h < 12) return 'Good Morning ☀️';
    if (h < 18) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }
  if (h < 12) return 'អរុណសួស្តី ☀️';
  if (h < 18) return 'ទិវាសួស្តី 🌤️';
  return 'សាយណ្ហសួស្តី 🌙';
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool matchesDateRange(
  DateTime date,
  DateRangeFilter filter, {
  DateTimeRange? customRange,
}) {
  if (customRange != null) {
    final start = DateTime(
      customRange.start.year,
      customRange.start.month,
      customRange.start.day,
    );
    final end = DateTime(
      customRange.end.year,
      customRange.end.month,
      customRange.end.day,
      23,
      59,
      59,
    );
    return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
        date.isBefore(end.add(const Duration(seconds: 1)));
  }

  final now = DateTime.now();
  switch (filter) {
    case DateRangeFilter.today:
      return isSameDay(date, now);
    case DateRangeFilter.week:
      final diffDays = now.difference(date).inDays;
      return diffDays >= 0 && diffDays <= 7;
    case DateRangeFilter.month:
      return date.year == now.year && date.month == now.month;
    case DateRangeFilter.all:
      return true;
  }
}
