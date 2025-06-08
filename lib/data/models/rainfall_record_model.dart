import 'dart:math';

import 'weather_data_model.dart';

class RainfallRecord {
  /// [RainfallRecord] data model to store rainfall data
  final String postcode;
  final String stationId;
  final String monthYear;
  final int year;
  final int month;
  final double rainfall;
  final String quality;

  RainfallRecord({
    required this.postcode,
    required this.stationId,
    required this.monthYear,
    required this.year,
    required this.month,
    required this.rainfall,
    required this.quality,
  });

  // Convert JSON data to RainfallRecord
  factory RainfallRecord.fromJson(Map<String, dynamic> json, String postcode) {
    return RainfallRecord(
      postcode: postcode,
      stationId: json['station_id'] ?? '',
      monthYear: json['month_year'] ?? '',
      year: _parseYear(json['month_year'] ?? ''),
      month: _parseMonth(json['month_year'] ?? ''),
      rainfall: (json['precpt'] ?? 0).toDouble(),
      quality: json['quality'] ?? 'N',
    );
  }

  // Parse year from monthYear
  static int _parseYear(String monthYear) {
    try {
      return int.parse(monthYear.split('.')[1]);
    } catch (e) {
      return DateTime.now().year;
    }
  }

  // Parse month from monthYear
  static int _parseMonth(String monthYear) {
    try {
      return int.parse(monthYear.split('.')[0]);
    } catch (e) {
      return 1;
    }
  }

  // Convert to daily weather data
  List<WeatherData> toDailyWeatherData() {
    // Get number of days in month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Initialise list to hold daily weather data
    final List<WeatherData> dailyData = [];

    // For each day in month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);

      final temperature = _getSeasonalTemperature(month);

      // Add to daily data
      dailyData.add(
        WeatherData(
          postcode: postcode,
          date: date,
          rainfall: rainfall,
          temperature: temperature,
        ),
      );
    }

    return dailyData;
  }

  // Get seasonal temperature
  double _getSeasonalTemperature(int month) {
    // South Australian seasonal temperatures
    switch (month) {
      case 12:
      case 1:
      case 2: // Summer
        return 28 + (Random().nextDouble() * 12); // 28-40°C
      case 6:
      case 7:
      case 8: // Winter
        return 8 + (Random().nextDouble() * 10); // 8-18°C
      case 3:
      case 4:
      case 5: // Autumn
        return 18 + (Random().nextDouble() * 10); // 18-28°C
      default: // Spring
        return 20 + (Random().nextDouble() * 12); // 20-32°C
    }
  }
}
