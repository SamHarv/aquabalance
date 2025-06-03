import '../../logic/services/cache_service.dart';
import '../api/rainfall_api.dart';
import '../models/monthly_rainfall_model.dart';
import '../models/rainfall_record_model.dart';
import '../models/weather_data_model.dart';

class DatabaseService {
  /// [DatabaseService] to manage connection to Rainfall API

  // Singleton
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Fetch rainfall data
  Future<Map<String, dynamic>> getRainfallData({
    required String postcode,
    required int year,
    bool includeMonthly = true,
    bool includeAnnual = true,
    bool useCache = true,
  }) async {
    // Enforce year limits
    if (year < 1975 || year > 2025) {
      return buildRainfallResponse(
        _generateEmptyMonthlyData(),
        includeMonthly,
        includeAnnual,
      );
    }

    // Check cache first
    if (useCache) {
      final cached = CacheService.getCachedMonthlyRainfall(postcode, year);
      if (cached != null) {
        return buildRainfallResponse(cached, includeMonthly, includeAnnual);
      }
    }

    try {
      // Fetch from API
      final rainfallRecords = await RainfallApiService.getRainfallData(
        postcode: postcode,
        year: year,
      );

      // Process the data
      final monthlyData = _processMonthlyRainfallData(rainfallRecords, year);

      // Cache the result
      if (useCache) {
        CacheService.cacheMonthlyRainfall(postcode, year, monthlyData);
      }

      return buildRainfallResponse(monthlyData, includeMonthly, includeAnnual);
    } catch (e) {
      throw Exception('Failed to fetch rainfall data: $e');
    }
  }

  // Get weather data using Rainfall API
  Future<List<WeatherData>> getWeatherByPostcode({
    required String postcode,
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
    bool useCache = true,
  }) async {
    // Check cache first
    if (useCache) {
      final cached = CacheService.getCachedWeatherData(
        postcode,
        startDate.year,
        endDate.year,
      );
      if (cached != null) {
        // Return filtered by date range
        return filterWeatherDataByDateRange(cached, startDate, endDate, limit);
      }
    }

    try {
      // Fetch data
      final allWeatherData = await _fetchWeatherDataFromApi(
        postcode,
        startDate.year,
        endDate.year,
      );

      // Cache the result
      if (useCache && allWeatherData.isNotEmpty) {
        CacheService.cacheWeatherData(
          postcode,
          startDate.year,
          endDate.year,
          allWeatherData,
        );
      }

      // Return filtered by date range
      return filterWeatherDataByDateRange(
        allWeatherData,
        startDate,
        endDate,
        limit,
      );
    } catch (e) {
      throw Exception('Failed to fetch weather data: $e');
    }
  }

  // Get monthly rainfall
  Future<List<MonthlyRainfall>> getMonthlyRainfall({
    required String postcode,
    required int year,
    bool useCache = true,
  }) async {
    final result = await getRainfallData(
      postcode: postcode,
      year: year,
      includeMonthly: true,
      includeAnnual: false,
      useCache: useCache,
    );
    return result['monthlyData'] as List<MonthlyRainfall>;
  }

  // Get annual rainfall
  Future<double> getAnnualRainfall({
    required String postcode,
    required int year,
    bool useCache = true,
  }) async {
    final result = await getRainfallData(
      postcode: postcode,
      year: year,
      includeMonthly: false,
      includeAnnual: true,
      useCache: useCache,
    );
    return result['annualTotal'] as double;
  }

  // Build response map
  Map<String, dynamic> buildRainfallResponse(
    List<MonthlyRainfall> monthlyData,
    bool includeMonthly,
    bool includeAnnual,
  ) {
    final response = <String, dynamic>{};

    if (includeMonthly) {
      response['monthlyData'] = monthlyData;
    }

    if (includeAnnual) {
      response['annualTotal'] = monthlyData
          .map((d) => d.totalRainfall)
          .reduce((a, b) => a + b);
    }

    return response;
  }

  // Fetch weather data from API
  Future<List<WeatherData>> _fetchWeatherDataFromApi(
    String postcode,
    int startYear,
    int endYear,
  ) async {
    final List<WeatherData> allWeatherData = [];

    for (int year = startYear; year <= endYear; year++) {
      try {
        // Fetch data
        final rainfallRecords = await RainfallApiService.getRainfallData(
          postcode: postcode,
          year: year,
        );

        // Add to list
        for (final record in rainfallRecords) {
          allWeatherData.addAll(record.toDailyWeatherData());
        }

        // Rate limiting
        await Future.delayed(Duration(milliseconds: 100));
      } catch (e) {
        throw Exception('Failed to fetch data for year $year: $e');
      }
    }

    return allWeatherData;
  }

  // Filter weather data by date range
  List<WeatherData> filterWeatherDataByDateRange(
    List<WeatherData> data,
    DateTime startDate,
    DateTime endDate,
    int? limit,
  ) {
    // Filter by date range
    final filteredData =
        data
            .where(
              (weatherData) =>
                  weatherData.date.isAfter(
                    startDate.subtract(Duration(days: 1)),
                  ) &&
                  weatherData.date.isBefore(endDate.add(Duration(days: 1))),
            )
            .toList();

    // Sort by date
    filteredData.sort((a, b) => a.date.compareTo(b.date));

    // Apply limit if specified
    return limit != null && filteredData.length > limit
        ? filteredData.take(limit).toList()
        : filteredData;
  }

  // Process monthly rainfall from rainfall records
  List<MonthlyRainfall> _processMonthlyRainfallData(
    List<RainfallRecord> records,
    int year,
  ) {
    final Map<int, double> monthlyTotals = {};

    // Group records by month
    for (final record in records) {
      if (record.year == year) {
        monthlyTotals[record.month] =
            (monthlyTotals[record.month] ?? 0) + record.rainfall;
      }
    }

    // Generate monthly data
    return List.generate(12, (index) {
      final month = index + 1;
      return MonthlyRainfall(
        month: month,
        totalRainfall: monthlyTotals[month] ?? 0,
      );
    });
  }

  // Generate empty monthly data for errors
  List<MonthlyRainfall> _generateEmptyMonthlyData() {
    return List.generate(
      12,
      (index) => MonthlyRainfall(month: index + 1, totalRainfall: 0),
    );
  }
}
