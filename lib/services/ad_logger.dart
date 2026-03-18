import 'package:flutter/foundation.dart';

/// Simple console logger for ad events (no UI, no files)
class AdLogger {
  static void log(String message) {
    debugPrint('[AdLogger] $message');
  }

  static void adLoaded(String adType) {
    log('✅ $adType ad loaded successfully');
  }

  static void adFailed(String adType, String reason) {
    log('❌ $adType ad failed: $reason');
  }

  static void adShown(String adType) {
    log('📺 $adType ad shown');
  }

  static void adDismissed(String adType) {
    log('❌ $adType ad dismissed by user');
  }

  static void adDisabled(String adType) {
    log('⚠️  $adType ad disabled in API config');
  }

  static void cooldownActive(String adType, int remainingSeconds) {
    log('⏱️  $adType cooldown active (${remainingSeconds}s remaining)');
  }

  static void apiConfigFetched(int configCount) {
    log('📋 Fetched $configCount ad configurations from API');
  }

  static void apiError(String error) {
    log('🔴 API Error: $error');
  }
}
