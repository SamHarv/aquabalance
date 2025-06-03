class MonthlyRainfall {
  /// [MonthlyRainfall] class to hold data for a single month
  final int month;
  final double totalRainfall;

  MonthlyRainfall({required this.month, required this.totalRainfall});

  String get monthName {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  String toString() =>
      'MonthlyRainfall(month: $month, totalRainfall: $totalRainfall)';
}
