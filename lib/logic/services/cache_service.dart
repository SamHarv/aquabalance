import '../../data/models/monthly_rainfall_model.dart';
import '../../data/models/weather_data_model.dart';

class CacheService {
  /// [CacheService] to handle caching of data from APIs

  // Private cache storage
  static final Map<String, CacheEntry> _cache = {};
  // Default timeout
  static const Duration _defaultTimeout = Duration(hours: 1);

  // Check cache is valid
  static bool isValid(String key, {Duration? timeout}) {
    final entry = _cache[key];
    if (entry == null) return false;
    final actualTimeout = timeout ?? _defaultTimeout;
    return DateTime.now().difference(entry.timestamp) < actualTimeout;
  }

  // Set cache
  static void set(String key, dynamic data, {Duration? timeout}) {
    _cache[key] = CacheEntry(
      data: data,
      timestamp: DateTime.now(),
      timeout: timeout ?? _defaultTimeout,
    );
  }

  // Get cache
  static T? get<T>(String key, {Duration? timeout}) {
    if (isValid(key, timeout: timeout)) {
      return _cache[key]?.data as T?;
    }
    return null;
  }

  // Remove cache
  static void remove(String key) {
    _cache.remove(key);
  }

  // Clear cache
  static void clear() {
    _cache.clear();
  }

  // Weather cache key
  static String weatherCacheKey(String postcode, int startYear, int endYear) {
    return 'weather_api_${postcode}_${startYear}_$endYear';
  }

  // Monthly rainfall cache key
  static String monthlyRainfallCacheKey(String postcode, int year) {
    return 'monthly_rainfall_api_${postcode}_$year';
  }

  // Cache weather data
  static void cacheWeatherData(
    String postcode,
    int startYear,
    int endYear,
    List<WeatherData> data,
  ) {
    final key = weatherCacheKey(postcode, startYear, endYear);
    set(
      key,
      data,
      timeout: Duration(hours: 2),
    ); // Weather data can be cached longer
  }

  // Get weather data from cache
  static List<WeatherData>? getCachedWeatherData(
    String postcode,
    int startYear,
    int endYear,
  ) {
    final key = weatherCacheKey(postcode, startYear, endYear);
    return get<List<WeatherData>>(key, timeout: Duration(hours: 2));
  }

  // Cache monthly rainfall
  static void cacheMonthlyRainfall(
    String postcode,
    int year,
    List<MonthlyRainfall> data,
  ) {
    final key = monthlyRainfallCacheKey(postcode, year);
    set(
      key,
      data,
      timeout: Duration(hours: 6),
    ); // Monthly data can be cached even longer
  }

  // Get monthly rainfall from cache
  static List<MonthlyRainfall>? getCachedMonthlyRainfall(
    String postcode,
    int year,
  ) {
    final key = monthlyRainfallCacheKey(postcode, year);
    return get<List<MonthlyRainfall>>(key, timeout: Duration(hours: 6));
  }
}

class CacheEntry {
  /// [CacheEntry] to structure cache data
  final dynamic data;
  final DateTime timestamp;
  final Duration timeout;

  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.timeout,
  });
}
