import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // Debug modda Google'ın evrensel test ID'leri kullanılır.
  // Release modda gerçek AdMob unit ID'leri devreye girer.
  static String get _clientAddUnitId {
    if (kDebugMode) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/1712485313' // Google iOS test rewarded
          : 'ca-app-pub-3940256099942544/5224354917'; // Google Android test rewarded
    }
    return Platform.isIOS
        ? 'ca-app-pub-8094152890068517/7002893167'
        : 'ca-app-pub-8094152890068517/6937077468';
  }

  static String get _periodAddUnitId {
    if (kDebugMode) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-3940256099942544/5224354917';
    }
    return Platform.isIOS
        ? 'ca-app-pub-8094152890068517/4376729820'
        : 'ca-app-pub-8094152890068517/5063546996';
  }

  static String get _weeklyPlanUnitId {
    if (kDebugMode) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-3940256099942544/5224354917';
    }
    return Platform.isIOS
        ? 'ca-app-pub-8094152890068517/2350166436'
        : 'ca-app-pub-8094152890068517/8177629641';
  }

  RewardedAd? _clientAd;
  RewardedAd? _periodAd;
  RewardedAd? _weeklyPlanAd;

  Future<void> init() => MobileAds.instance.initialize();

  static const List<String> _adKeywords = [
    'fitness',
    'spor',
    'health',
    'antrenman',
    'sağlık',
    'egzersiz',
    'personal trainer',
    'gym',
    'lesson',
    'workout',
    'teacher',
    'öğretmen',
    'language',
    'dil',
    'athlete',
    'sporcu',
    'spor salonu',
    'spor eğitmeni',
    'sporcu antrenmanı',
    'sporcu sağlığı',
    'sporcu beslenmesi',
    'sporcu performansı',
    'sporcu motivasyonu',
    'sporcu gelişimi',
    'sporcu antrenman programı',
    'sporcu antrenman planı',
  ];

  Future<void> loadClientAd() async {
    await RewardedAd.load(
      adUnitId: _clientAddUnitId,
      request: const AdRequest(keywords: _adKeywords),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdService] Client ad loaded.');
          _clientAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint(
            '[AdService] Client ad failed: ${error.code} – ${error.message}',
          );
          _clientAd = null;
        },
      ),
    );
  }

  Future<void> loadPeriodAd() async {
    await RewardedAd.load(
      adUnitId: _periodAddUnitId,
      request: const AdRequest(keywords: _adKeywords),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdService] Period ad loaded.');
          _periodAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint(
            '[AdService] Period ad failed: ${error.code} – ${error.message}',
          );
          _periodAd = null;
        },
      ),
    );
  }

  /// [onRewarded] → reklam izlendi, devam et
  /// [onFailed]   → reklam yok/hata, ne yapılacağı caller'a bırakılıyor
  Future<void> showClientAd({
    required void Function() onRewarded,
    required void Function() onFailed,
  }) async {
    if (_clientAd == null) {
      onFailed();
      return;
    }
    bool earned = false;
    _clientAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _clientAd = null;
        loadClientAd();
        if (earned) onRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _clientAd = null;
        loadClientAd();
        onFailed();
      },
    );
    await _clientAd!.show(onUserEarnedReward: (_, __) => earned = true);
  }

  Future<void> showPeriodAd({
    required void Function() onRewarded,
    required void Function() onFailed,
  }) async {
    if (_periodAd == null) {
      onFailed();
      return;
    }
    bool earned = false;
    _periodAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _periodAd = null;
        loadPeriodAd();
        if (earned) onRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _periodAd = null;
        loadPeriodAd();
        onFailed();
      },
    );
    await _periodAd!.show(onUserEarnedReward: (_, __) => earned = true);
  }

  Future<void> loadWeeklyPlanAd() async {
    await RewardedAd.load(
      adUnitId: _weeklyPlanUnitId,
      request: const AdRequest(keywords: _adKeywords),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdService] Weekly plan ad loaded.');
          _weeklyPlanAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint(
            '[AdService] Weekly plan ad failed: ${error.code} – ${error.message}',
          );
          _weeklyPlanAd = null;
        },
      ),
    );
  }

  Future<void> showWeeklyPlanAd({
    required void Function() onRewarded,
    required void Function() onFailed,
  }) async {
    if (_weeklyPlanAd == null) {
      onFailed();
      return;
    }
    bool earned = false;
    _weeklyPlanAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _weeklyPlanAd = null;
        loadWeeklyPlanAd();
        if (earned) onRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _weeklyPlanAd = null;
        loadWeeklyPlanAd();
        onFailed();
      },
    );
    await _weeklyPlanAd!.show(onUserEarnedReward: (_, __) => earned = true);
  }
}
