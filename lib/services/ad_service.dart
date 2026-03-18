import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ad_logger.dart';

class AdData {
  final String appName;
  final String adType; // App open, Interstitial, Banner
  final String adUnitId;
  final String platform; // Android, iOS
  final bool isEnabled;

  AdData({
    required this.appName,
    required this.adType,
    required this.adUnitId,
    required this.platform,
    required this.isEnabled,
  });

  factory AdData.fromJson(Map<String, dynamic> json) {
    return AdData(
      appName: json['App Name'] ?? '',
      adType: json['Ad Type'] ?? '',
      adUnitId: json['Ad Unit ID'] ?? '',
      platform: json['Platform'] ?? '',
      isEnabled: json['Status'] == 'Enable',
    );
  }
}

class AdService {
  static const String _apiUrl =
      'https://script.googleusercontent.com/macros/echo?user_content_key=AY5xjrR1aXv-YSQUN5lniSxKUbdu-S3Ux3xtBJ24AmYMGYh7QmilD6kMOjUhaQm3u-rq6QWcmTl8iv8jbp9SDdV9NKcGbkB1nDT1fdbdHN6aUPqDiDG0z9lQBsOjp0FlTRWHwSyoUrDC82wnADFYyJGkDDWzY9YGbOCDG_G61wwR4rqM9ue7yimCiZiMSnFnCH5cx3qVSUS_4WygI2NwmrOrjbADCHvM9cuRKKUSgK9QMDwUlKk57YsWyjM0fhJOrw_QLRc4IubnrkNOzW4DSz0w8hMGFGBlPVdLkXnO91W1BlS6Ov7KJgu8SnaoCQEN1Q&lib=MH__BrZO-6yBZFmsCpXNALTBB5iDfypnN';

  /// Fetch ad configurations from Google Apps Script API
  static Future<List<AdData>> fetchAdConfigs() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final configs = data
            .map((item) => AdData.fromJson(item as Map<String, dynamic>))
            .toList();
        
        AdLogger.apiConfigFetched(configs.length);
        return configs;
      } else {
        AdLogger.apiError('Status code: ${response.statusCode}');
        throw Exception(
            'Failed to load ad configs. Status code: ${response.statusCode}');
      }
    } catch (e) {
      AdLogger.apiError(e.toString());
      throw Exception('Error fetching ad configs: $e');
    }
  }

  /// Get specific ad unit ID based on type and platform
  static Future<String?> getAdUnitId({
    required String adType,
    required String platform,
  }) async {
    try {
      final configs = await fetchAdConfigs();
      final adConfig = configs.firstWhere(
        (ad) =>
            ad.adType.toLowerCase() == adType.toLowerCase() &&
            ad.platform.toLowerCase() == platform.toLowerCase() &&
            ad.isEnabled,
        orElse: () => AdData(
          appName: '',
          adType: '',
          adUnitId: '',
          platform: '',
          isEnabled: false,
        ),
      );

      return adConfig.isEnabled ? adConfig.adUnitId : null;
    } catch (e) {
      return null;
    }
  }

  /// Check if ads are enabled for a specific type
  static Future<bool> isAdEnabled({
    required String adType,
    required String platform,
  }) async {
    try {
      final configs = await fetchAdConfigs();
      final isEnabled = configs.any(
        (ad) =>
            ad.adType.toLowerCase() == adType.toLowerCase() &&
            ad.platform.toLowerCase() == platform.toLowerCase() &&
            ad.isEnabled,
      );

      return isEnabled;
    } catch (e) {
      return false;
    }
  }
}
