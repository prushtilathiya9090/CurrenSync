import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../services/ad_logger.dart';

class AdProvider extends ChangeNotifier {
  BannerAd? _bannerAd;
  BannerAd? _topBannerAd;
  AppOpenAd? _appOpenAd;
  bool _isBannerAdLoaded = false;
  bool _isTopBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isAppOpenAdLoaded = false;

  // Frequency capping for interstitials (milliseconds)
  static const int _interstitialCooldownMs = 30000; // 30 seconds between interstitials
  DateTime? _lastInterstitialShownTime;
  int _interstitialShowCount = 0;

  BannerAd? get bannerAd => _bannerAd;
  BannerAd? get topBannerAd => _topBannerAd;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isTopBannerAdLoaded => _isTopBannerAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isAppOpenAdLoaded => _isAppOpenAdLoaded;
  int get interstitialShowCount => _interstitialShowCount;

  /// Initialize top banner ad (premium placement)
  Future<void> initializeTopBannerAd() async {
    try {
      final adUnitId = await AdService.getAdUnitId(
        adType: 'Banner',
        platform: Platform.isAndroid ? 'Android' : 'iOS',
      );

      if (adUnitId == null) {
        _isTopBannerAdLoaded = false;
        notifyListeners();
        return;
      }

      _topBannerAd = BannerAd(
        adUnitId: adUnitId,
        request: const AdRequest(),
        size: AdSize.mediumRectangle,
        listener: BannerAdListener(
          onAdLoaded: (_) {
            _isTopBannerAdLoaded = true;
            AdLogger.adLoaded('Top Banner');
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _isTopBannerAdLoaded = false;
            AdLogger.adFailed('Top Banner', error.message);
            notifyListeners();
          },
        ),
      );

      await _topBannerAd?.load();
    } catch (e) {
      _isTopBannerAdLoaded = false;
      notifyListeners();
    }
  }

  /// Initialize banner ad
  Future<void> initializeBannerAd() async {
    try {
      final adUnitId = await AdService.getAdUnitId(
        adType: 'Banner',
        platform: Platform.isAndroid ? 'Android' : 'iOS',
      );

      if (adUnitId == null) {
        _isBannerAdLoaded = false;
        notifyListeners();
        return;
      }

      _bannerAd = BannerAd(
        adUnitId: adUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (_) {
            _isBannerAdLoaded = true;
            AdLogger.adLoaded('Bottom Banner');
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _isBannerAdLoaded = false;
            AdLogger.adFailed('Bottom Banner', error.message);
            notifyListeners();
          },
        ),
      );

      await _bannerAd?.load();
    } catch (e) {
      _isBannerAdLoaded = false;
      notifyListeners();
    }
  }

  /// Load interstitial ad
  Future<InterstitialAd?> loadInterstitialAd() async {
    try {
      final adUnitId = await AdService.getAdUnitId(
        adType: 'Interstitial',
        platform: Platform.isAndroid ? 'Android' : 'iOS',
      );

      if (adUnitId == null) {
        _isInterstitialAdLoaded = false;
        notifyListeners();
        return null;
      }

      InterstitialAd? interstitialAd;

      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialAd = ad;
            _isInterstitialAdLoaded = true;
            AdLogger.adLoaded('Interstitial');
            notifyListeners();
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isInterstitialAdLoaded = false;
            AdLogger.adFailed('Interstitial', error.message);
            notifyListeners();
          },
        ),
      );

      return interstitialAd;
    } catch (e) {
      _isInterstitialAdLoaded = false;
      notifyListeners();
      return null;
    }
  }

  /// Load app open ad (shown on app launch/resume)
  Future<AppOpenAd?> loadAppOpenAd() async {
    try {
      final adUnitId = await AdService.getAdUnitId(
        adType: 'App open',
        platform: Platform.isAndroid ? 'Android' : 'iOS',
      );

      if (adUnitId == null) {
        _isAppOpenAdLoaded = false;
        notifyListeners();
        return null;
      }

      AppOpenAd? appOpenAd;

      await AppOpenAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            appOpenAd = ad;
            _appOpenAd = ad;
            _isAppOpenAdLoaded = true;
            AdLogger.adLoaded('App Open');
            notifyListeners();
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isAppOpenAdLoaded = false;
            AdLogger.adFailed('App Open', error.message);
            notifyListeners();
          },
        ),
      );

      return appOpenAd;
    } catch (e) {
      _isAppOpenAdLoaded = false;
      notifyListeners();
      return null;
    }
  }

  /// Show app open ad if available (high-priority placement)
  Future<void> showAppOpenAd() async {
    try {
      // If we have a cached app open ad, show it
      if (_appOpenAd != null) {
        AdLogger.adShown('App Open (cached)');
        _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdShowedFullScreenContent: (ad) {},
          onAdFailedToShowFullScreenContent: (ad, err) {
            ad.dispose();
            _appOpenAd = null;
          },
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _appOpenAd = null;
            // Preload next app open ad for next app open
            loadAppOpenAd();
          },
        );
        await _appOpenAd?.show();
        return;
      }

      // Otherwise load and show
      final appOpenAd = await loadAppOpenAd();
      if (appOpenAd != null) {
        appOpenAd.fullScreenContentCallback = FullScreenContentCallback(
          onAdShowedFullScreenContent: (ad) {},
          onAdFailedToShowFullScreenContent: (ad, err) {
            ad.dispose();
            _appOpenAd = null;
          },
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _appOpenAd = null;
          },
        );
        await appOpenAd.show();
      }
    } catch (e) {}
  }

  /// Check if enough time has passed since last interstitial
  bool _canShowInterstitial() {
    if (_lastInterstitialShownTime == null) {
      return true;
    }
    final elapsed = DateTime.now().difference(_lastInterstitialShownTime!).inMilliseconds;
    return elapsed >= _interstitialCooldownMs;
  }

  /// Show interstitial ad with frequency capping
  Future<void> showInterstitialAd({bool forceSilent = false}) async {
    try {
      // Check frequency capping
      if (!_canShowInterstitial()) {
        return;
      }

      final interstitialAd = await loadInterstitialAd();
      if (interstitialAd != null) {
        _lastInterstitialShownTime = DateTime.now();
        _interstitialShowCount++;
        AdLogger.adShown('Interstitial');
        
        interstitialAd.fullScreenContentCallback = FullScreenContentCallback(
          onAdShowedFullScreenContent: (ad) {},
          onAdFailedToShowFullScreenContent: (ad, err) {
            ad.dispose();
          },
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
          },
        );
        await interstitialAd.show();
      }
    } catch (e) {}
  }

  /// Dispose all ads
  void disposeAds() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isBannerAdLoaded = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeAds();
    super.dispose();
  }
}
