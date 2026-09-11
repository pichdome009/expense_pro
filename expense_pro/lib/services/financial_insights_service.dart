import '../models/transaction.dart';

class FinancialInsightsData {
  final double dailyAverage;
  final String peakWeekdayName;
  final double peakWeekdayAmount;
  final String topCategory;
  final double topCategoryAmount;
  final double topCategoryPercentage;
  final double totalIncome;
  final double totalExpense;
  final double savingsRate;
  final String smartTip;

  const FinancialInsightsData({
    required this.dailyAverage,
    required this.peakWeekdayName,
    required this.peakWeekdayAmount,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.topCategoryPercentage,
    required this.totalIncome,
    required this.totalExpense,
    required this.savingsRate,
    required this.smartTip,
  });
}

class FinancialInsightsService {
  static const Map<int, String> _kmWeekdays = {
    1: 'ថ្ងៃចន្ទ',
    2: 'ថ្ងៃអង្គារ',
    3: 'ថ្ងៃពុធ',
    4: 'ថ្ងៃព្រហស្បតិ៍',
    5: 'ថ្ងៃសុក្រ',
    6: 'ថ្ងៃសៅរ៍',
    7: 'ថ្ងៃអាទិត្យ',
  };

  static const Map<int, String> _enWeekdays = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  /// Computes smart insights from a list of transactions for a specific period
  static FinancialInsightsData computeInsights({
    required List<Transaction> transactions,
    required int daysInPeriod,
    String lang = 'km',
  }) {
    final expenses = transactions.where((t) => t.type == TxType.expense).toList();
    final incomes = transactions.where((t) => t.type == TxType.income).toList();

    final totalExpense = expenses.fold(0.0, (s, t) => s + t.amount);
    final totalIncome = incomes.fold(0.0, (s, t) => s + t.amount);

    final safeDays = daysInPeriod > 0 ? daysInPeriod : 1;
    final dailyAvg = totalExpense / safeDays;

    // 1. Group expense by weekday (1..7)
    final weekdayMap = <int, double>{};
    for (int d = 1; d <= 7; d++) {
      weekdayMap[d] = 0.0;
    }
    for (final t in expenses) {
      final wd = t.date.weekday;
      weekdayMap[wd] = (weekdayMap[wd] ?? 0.0) + t.amount;
    }

    int peakWeekday = 6; // Default Saturday
    double peakWeekdayAmount = 0.0;
    for (final entry in weekdayMap.entries) {
      if (entry.value > peakWeekdayAmount) {
        peakWeekdayAmount = entry.value;
        peakWeekday = entry.key;
      }
    }

    final peakWeekdayName = (lang == 'en' ? _enWeekdays[peakWeekday] : _kmWeekdays[peakWeekday]) ??
        (lang == 'en' ? 'Saturday' : 'ថ្ងៃសៅរ៍');

    // 2. Top category breakdown
    final catMap = <String, double>{};
    for (final t in expenses) {
      catMap[t.category] = (catMap[t.category] ?? 0.0) + t.amount;
    }

    String topCategory = '';
    double topCategoryAmount = 0.0;
    for (final entry in catMap.entries) {
      if (entry.value > topCategoryAmount) {
        topCategoryAmount = entry.value;
        topCategory = entry.key;
      }
    }

    final topCategoryPercentage =
        totalExpense > 0 ? (topCategoryAmount / totalExpense) * 100 : 0.0;

    // 3. Savings rate
    final savingsRate = totalIncome > 0
        ? (((totalIncome - totalExpense) / totalIncome) * 100).clamp(-100.0, 100.0)
        : 0.0;

    // 4. Generate dynamic smart tip
    final String tip;
    final isKm = lang == 'km';

    if (totalExpense == 0) {
      tip = isKm
          ? 'គ្មានការចំណាយក្នុងកំឡុងពេលនេះទេ អស្ចារ្យណាស់! 🎉'
          : 'No expenses recorded for this period. Great job! 🎉';
    } else if (totalExpense > totalIncome && totalIncome > 0) {
      tip = isKm
          ? 'ការចំណាយខែនេះលើសចំណូល! សូមពិនិត្យកាត់បន្ថយលើ "$topCategory" ដើម្បីរក្សាសមតុល្យ 🛡️'
          : 'Expenses exceed income this period! Consider optimizing "$topCategory" spending 🛡️';
    } else if (topCategoryPercentage >= 40 && topCategory.isNotEmpty) {
      tip = isKm
          ? 'ប្រភេទ "$topCategory" ក្តោបចំណាយដល់ទៅ ${topCategoryPercentage.toStringAsFixed(0)}%! គួរកំណត់កញ្ចប់ថវិកាលើវា 🎯'
          : '"$topCategory" accounts for ${topCategoryPercentage.toStringAsFixed(0)}% of your spending! Consider setting a budget 🎯';
    } else if (savingsRate >= 20) {
      tip = isKm
          ? 'អត្រាសន្សំរបស់អ្នកល្អណាស់ (${savingsRate.toStringAsFixed(0)}%)! កុំភ្លេចផ្ទេរចូលកូនជ្រូកសន្សំប្រាក់ 🐖'
          : 'Great savings rate (${savingsRate.toStringAsFixed(0)}%)! Consider depositing into your Savings Goals 🐖';
    } else {
      tip = isKm
          ? 'បន្តកត់ត្រាជាប្រចាំដើម្បីគ្រប់គ្រងលំហូរសាច់ប្រាក់របស់អ្នកឲ្យកាន់តែមានប្រសិទ្ធភាព ✨'
          : 'Keep logging transactions consistently to master your personal cash flow ✨';
    }

    return FinancialInsightsData(
      dailyAverage: dailyAvg,
      peakWeekdayName: peakWeekdayName,
      peakWeekdayAmount: peakWeekdayAmount,
      topCategory: topCategory.isNotEmpty ? topCategory : (isKm ? 'គ្មាន' : 'None'),
      topCategoryAmount: topCategoryAmount,
      topCategoryPercentage: topCategoryPercentage,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      savingsRate: savingsRate,
      smartTip: tip,
    );
  }
}
