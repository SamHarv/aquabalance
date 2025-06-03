class WeatherData {
  /// [WeatherData] class to hold data for a single day
  final String postcode;
  final DateTime date;
  final double rainfall;
  final double temperature;

  WeatherData({
    required this.postcode,
    required this.date,
    required this.rainfall,
    required this.temperature,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      postcode: json['postcode'],
      date: DateTime.parse(json['date']),
      rainfall: (json['rainfall'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
    );
  }
}
