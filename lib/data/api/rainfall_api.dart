import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/rainfall_record_model.dart';

class RainfallApiService {
  /// [RainfallApiService] to fetch rainfall data from the API

  // API base URL
  static const String _baseUrl = 'https://rainfall-api-3mlh.onrender.com';
  // API timeout setting
  static const Duration _timeout = Duration(seconds: 30);

  // Get rainfall data for a specific postcode
  static Future<List<RainfallRecord>> getRainfallData({
    required String postcode,
    int? year,
    int? month,
  }) async {
    try {
      if (kIsWeb) {
        // Fetch rainfall data on web (with CORS proxy)
        return await _getRainfallDataWeb(
          postcode: postcode,
          year: year,
          month: month,
        );
      } else {
        // Fetch rainfall data on mobile
        return await _getRainfallDataNative(
          postcode: postcode,
          year: year,
          month: month,
        );
      }
    } catch (e) {
      throw RainfallApiException('Failed to fetch rainfall data $e');
    }
  }

  // Mobile app version (no CORS issues)
  static Future<List<RainfallRecord>> _getRainfallDataNative({
    required String postcode,
    int? year,
    int? month,
  }) async {
    final client = http.Client();
    try {
      // Build query parameters
      final queryParams = <String, String>{'postcode': postcode};
      if (year != null) queryParams['year'] = year.toString();
      if (month != null) queryParams['month'] = month.toString();

      // Add query parameters to URI
      final uri = Uri.parse(
        '$_baseUrl/get_rainfall',
      ).replace(queryParameters: queryParams);

      // Fetch data
      final response = await client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        // Decode JSON data
        final List<dynamic> jsonData = json.decode(response.body);
        // Convert JSON data to RainfallRecord objects
        return jsonData
            .map((item) => RainfallRecord.fromJson(item, postcode))
            .toList();
      } else {
        throw RainfallApiException(
          'API returned status ${response.statusCode}: ${response.body}',
        );
      }
    } finally {
      client.close();
    }
  }

  // Web version with CORS workaround
  static Future<List<RainfallRecord>> _getRainfallDataWeb({
    required String postcode,
    int? year,
    int? month,
  }) async {
    final client = http.Client();

    try {
      // Build query parameters
      final queryParams = <String, String>{'postcode': postcode};
      if (year != null) queryParams['year'] = year.toString();
      if (month != null) queryParams['month'] = month.toString();

      // Add query parameters to URI
      final targetUrl =
          Uri.parse(
            '$_baseUrl/get_rainfall',
          ).replace(queryParameters: queryParams).toString();

      // Try multiple CORS proxy services in event of failure
      final proxies = [
        'https://api.allorigins.win/get?url=',
        'https://corsproxy.io/?',
        'https://cors-anywhere.herokuapp.com/',
      ];

      for (int i = 0; i < proxies.length; i++) {
        try {
          // Add proxy to URI
          final proxyUrl = '${proxies[i]}${Uri.encodeComponent(targetUrl)}';
          final uri = Uri.parse(proxyUrl);

          // Fetch data
          final response = await client.get(uri).timeout(_timeout);

          if (response.statusCode == 200) {
            dynamic responseData;

            // Handle different proxy response formats
            if (proxies[i].contains('allorigins')) {
              final proxyResponse = json.decode(response.body);
              responseData = json.decode(proxyResponse['contents']);
            } else {
              responseData = json.decode(response.body);
            }

            if (responseData is List) {
              // Convert JSON data to list of RainfallRecord objects
              return responseData
                  .map((item) => RainfallRecord.fromJson(item, postcode))
                  .toList();
            } else {
              throw RainfallApiException('Unexpected response format');
            }
          }
        } catch (e) {
          if (i == proxies.length - 1) rethrow; // Last proxy failed
          continue; // Try next proxy
        }
      }

      throw RainfallApiException('All proxy services failed');
    } finally {
      client.close();
    }
  }
}

// Custom exception for API errors
class RainfallApiException implements Exception {
  final String message;
  RainfallApiException(this.message);

  @override
  String toString() => 'RainfallApiException: $message';
}
