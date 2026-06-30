import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/premium_service.dart';

/// Premium olmayan kullanıcılara banner reklam gösterir.
/// Premium kullanıcılarda sıfır yükseklikte boş widget döner.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  static String get _unitId {
    if (kDebugMode) {
      return Platform.isIOS
          ? 'ca-app-pub-3940256099942544/2934735716' // Google iOS test banner
          : 'ca-app-pub-3940256099942544/6300978111'; // Google Android test banner
    }
    return Platform.isIOS
        ? 'ca-app-pub-8094152890068517/5962529840'
        : 'ca-app-pub-8094152890068517/2458399108';
  }

  static const List<String> _keywords = [
    'fitness',
    'spor',
    'antrenman',
    'sağlık',
    'egzersiz',
    'personal trainer',
    'gym',
  ];

  @override
  void initState() {
    super.initState();
    if (!PremiumService().isPremium) {
      _loadBanner();
    }
  }

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: _unitId,
      size: AdSize.banner,
      request: const AdRequest(keywords: _keywords),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          debugPrint('[BannerAd] Loaded.');
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[BannerAd] Failed: ${error.code} – ${error.message}');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (PremiumService().isPremium || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    return SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
