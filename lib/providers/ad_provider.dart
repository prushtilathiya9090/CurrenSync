import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../services/ad_logger.dart';

class AdProvider extends ChangeNotifier {
  BannerAd? _bannerAd;
  BannerAd? _topBannerAd;
  AppOpenAd? _appOpenAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerAdLoaded = false;
  bool _isTopBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isAppOpenAdLoaded = false;

  // Frequency capping for interstitials (milliseconds)
  static const int _interstitialCooldownMs = 30000; // 30 seconds between interstitials
  DateTime? _lastInterstitialShownTime;
  int _interstitialShowCount = 0;
  bool _isLoadingInterstitial = false;

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
        AdLogger.log('❌ No Top Banner Unit ID available (disabled in API)');
        _isTopBannerAdLoaded = false;
        notifyListeners();
        return;
      }
      
      AdLogger.log('📱 Loading Top Banner with Unit ID: $adUnitId');

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
        AdLogger.log('❌ No Bottom Banner Unit ID available (disabled in API)');
        _isBannerAdLoaded = false;
        notifyListeners();
        return;
      }
      
      AdLogger.log('📱 Loading Bottom Banner with Unit ID: $adUnitId');

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

  /// Pre-load interstitial ad (public method - call this on app start)
  Future<void> preloadInterstitialAd() async {
    await _preloadInterstitialAd();
  }

  /// Internal method to pre-load interstitial ad
  Future<void> _preloadInterstitialAd() async {
    if (_isLoadingInterstitial) return;
    
    try {
      _isLoadingInterstitial = true;
      
      final adUnitId = await AdService.getAdUnitId(
        adType: 'Interstitial',
        platform: Platform.isAndroid ? 'Android' : 'iOS',
      );

      if (adUnitId == null) {
        AdLogger.log('❌ No Interstitial Unit ID available (disabled in API)');
        _isInterstitialAdLoaded = false;
        _isLoadingInterstitial = false;
        notifyListeners();
        return;
      }
      
      AdLogger.log('📺 Preloading Interstitial with Unit ID: $adUnitId');

      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
            _isLoadingInterstitial = false;
            AdLogger.adLoaded('Interstitial (cached)');
            notifyListeners();
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isInterstitialAdLoaded = false;
            _isLoadingInterstitial = false;
            AdLogger.adFailed('Interstitial', error.message);
            notifyListeners();
          },
        ),
      );
    } catch (e) {
      _isInterstitialAdLoaded = false;
      _isLoadingInterstitial = false;
      notifyListeners();
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
        AdLogger.log('❌ No App Open Unit ID available (disabled in API)');
        _isAppOpenAdLoaded = false;
        notifyListeners();
        return null;
      }
      
      AdLogger.log('🎬 Loading App Open with Unit ID: $adUnitId');

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

  /// Show interstitial ad with frequency capping (uses cached ad if available)
  Future<void> showInterstitialAd() async {
    try {
      // Check frequency capping
      if (!_canShowInterstitial()) {
        return;
      }

      // Check if we have a cached ad ready
      if (_interstitialAd != null && _isInterstitialAdLoaded) {
        final adToShow = _interstitialAd!;
        _interstitialAd = null; // Clear the cache
        _isInterstitialAdLoaded = false;
        
        _lastInterstitialShownTime = DateTime.now();
        _interstitialShowCount++;
        AdLogger.adShown('Interstitial');
        
        adToShow.fullScreenContentCallback = FullScreenContentCallback(
          onAdShowedFullScreenContent: (ad) {},
          onAdFailedToShowFullScreenContent: (ad, err) {
            ad.dispose();
          },
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            // Preload next interstitial after this one is dismissed
            _preloadInterstitialAd();
          },
        );
        
        try {
          await adToShow.show();
        } catch (e) {
          AdLogger.log('❌ Error showing interstitial: $e');
        }
      } else {
        // No cached ad, trigger a preload for next time
        AdLogger.log('⏳ No cached interstitial ready, preloading for next time');
        _preloadInterstitialAd();
      }
    } catch (e) {
      AdLogger.log('❌ Error in showInterstitialAd: $e');
    }
  }

  /// Dispose all ads
  void disposeAds() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _topBannerAd?.dispose();
    _topBannerAd = null;
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isBannerAdLoaded = false;
    _isTopBannerAdLoaded = false;
    _isInterstitialAdLoaded = false;
    _isAppOpenAdLoaded = false;
    notifyListeners();
  }

  /// Reload all ads (alternative method - useful for debugging)
  Future<void> reloadAllAds() async {
    AdLogger.log('🔄 Manual reload triggered - refreshing all ads');
    disposeAds();
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdLoaded = false;
    await Future.delayed(const Duration(milliseconds: 500));
    await initializeBannerAd();
    await preloadInterstitialAd();
    notifyListeners();
  }

  /// Force show interstitial immediately (bypasses cooldown, uses cached if available)
  Future<void> forceShowInterstitialAd() async {
    try {
      // If we have a cached interstitial ad, show it
      if (_interstitialAd != null && _isInterstitialAdLoaded) {
        final adToShow = _interstitialAd!;
        _interstitialAd = null; // Clear the cache
        _isInterstitialAdLoaded = false;
        
        _lastInterstitialShownTime = DateTime.now();
        _interstitialShowCount++;
        AdLogger.adShown('Interstitial (forced)');
        
        adToShow.fullScreenContentCallback = FullScreenContentCallback(
          onAdShowedFullScreenContent: (ad) {},
          onAdFailedToShowFullScreenContent: (ad, err) {
            ad.dispose();
          },
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            // Preload next interstitial after this one is dismissed
            _preloadInterstitialAd();
          },
        );
        
        try {
          await adToShow.show();
        } catch (e) {
          AdLogger.log('❌ Error showing forced interstitial: $e');
        }
      } else {
        AdLogger.log('⚡ No cached interstitial, preloading and will show next time');
        _preloadInterstitialAd();
      }
    } catch (e) {
      AdLogger.log('❌ Error in forceShowInterstitialAd: $e');
    }
  }

  @override
  void dispose() {
    disposeAds();
    super.dispose();
  }
}
