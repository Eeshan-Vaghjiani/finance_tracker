class MonthlyAnalytics {
  final String monthYear; // e.g., 'Jan 2024'
  final double income;
  final double expense;

  MonthlyAnalytics({
    required this.monthYear,
    required this.income,
    required this.expense,
  });

  @override
  String toString() {
    return 'MonthlyAnalytics(monthYear: $monthYear, income: $income, expense: $expense)';
  }
}
