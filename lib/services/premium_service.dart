import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_environment.dart';

/// Premium / Free tier yönetim servisi.
/// In-App Purchase ile gerçek ödeme entegrasyonu.
/// Auto-renewable subscription (abonelik) modeli.
class PremiumService {
  // ── Singleton ──
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  static const String _keyIsPremium = 'is_premium';
  static const String _keyPurchaseDate = 'premium_purchase_date';
  static const String _keyPremiumProductId = 'premium_product_id';

  // ── Ürün ID'leri ──
  // App Store Connect ve Google Play Console'da tanımlanacak abonelik ID'leri.
  static const String monthlySubscriptionProductId = 'ptrainer_premium_monthly';
  static const String yearlySubscriptionProductId = 'ptrainer_premium_yearly';
  static final Set<String> _productIds = {
    monthlySubscriptionProductId,
    yearlySubscriptionProductId,
  };

  // ── Free Tier Limitleri ──
  static const int freeMaxClients = 3;
  static const int freeMaxPeriodsPerClient = 1;

  // ── Premium Durumu ──
  bool _isPremium = false;
  bool get isPremium => _isPremium;
  PremiumPlan? _activePlan;
  PremiumPlan? get activePlan => _activePlan;

  // ── IAP State ──
  final InAppPurchase _iap = InAppPurchase.instance;
  bool _iapAvailable = false;
  bool get iapAvailable => _iapAvailable;

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  // Satın alma durumunu UI'a bildirmek için
  final StreamController<PurchaseState> _stateController =
      StreamController<PurchaseState>.broadcast();
  Stream<PurchaseState> get stateStream => _stateController.stream;

  /// Servisi başlat – uygulama açılışında çağrılmalı
  Future<void> init() async {
    // Önce SharedPreferences'tan oku
    final prefs = await SharedPreferences.getInstance();
    final storedPlan = _planFromProductId(
      prefs.getString(_keyPremiumProductId),
    );
    final storedPurchaseDate = DateTime.tryParse(
      prefs.getString(_keyPurchaseDate) ?? '',
    );
    _activePlan = storedPlan;
    _isPremium = _isStoredEntitlementActive(
      isPremiumFlag: prefs.getBool(_keyIsPremium) ?? false,
      plan: storedPlan,
      purchaseDate: storedPurchaseDate,
    );

    // Süresi dolmuş yerel premium durumunu temizle.
    if (!_isPremium) {
      await prefs.setBool(_keyIsPremium, false);
      await prefs.remove(_keyPremiumProductId);
      await prefs.remove(_keyPurchaseDate);
      _activePlan = null;
    }

    // IAP başlat
    _iapAvailable = await _iap.isAvailable();
    if (!_iapAvailable) {
      debugPrint('IAP: Store not available');
      return;
    }

    // Purchase stream'i dinle
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        debugPrint('IAP stream error: $error');
        _stateController.add(PurchaseState.error);
      },
    );

    // Ürünleri yükle
    await _loadProducts();

    // Aktif abonelikleri mağazadan senkronize et.
    // Auto-renewable subscription için entitlement güncel tutulmalıdır.
    unawaited(restorePurchases());
  }

  /// Ürünleri mağazadan yükle
  Future<void> _loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(_productIds);
      if (response.error != null) {
        debugPrint('IAP product query error: ${response.error}');
        return;
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('IAP products not found: ${response.notFoundIDs}');
      }
      _products = response.productDetails;
      debugPrint('IAP: ${_products.length} product(s) loaded');
    } catch (e) {
      debugPrint('IAP _loadProducts error: $e');
    }
  }

  /// Satın alma güncellemelerini işle
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _stateController.add(PurchaseState.pending);
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // Satın alma doğrulandı – premium aç
          await _verifyAndActivate(purchase);
          break;

        case PurchaseStatus.error:
          debugPrint('IAP error: ${purchase.error?.message}');
          _stateController.add(PurchaseState.error);
          break;

        case PurchaseStatus.canceled:
          _stateController.add(PurchaseState.cancelled);
          break;
      }

      // pendingCompletePurchase varsa tamamla
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// Satın almayı doğrula ve premium'u aktifleştir
  Future<void> _verifyAndActivate(PurchaseDetails purchase) async {
    if (!_productIds.contains(purchase.productID)) {
      debugPrint('IAP: Ignoring unknown product id: ${purchase.productID}');
      _stateController.add(PurchaseState.error);
      return;
    }

    // Not: Gerçek bir üretim uygulamasında burada sunucu taraflı
    // receipt validation yapılmalıdır. Basit uygulamalar için
    // client-side yeterlidir.
    final purchaseDate = _parseStorePurchaseDate(purchase.transactionDate);
    await activatePremium(
      productId: purchase.productID,
      purchaseDate: purchaseDate,
    );
    _stateController.add(
      purchase.status == PurchaseStatus.restored
          ? PurchaseState.restored
          : PurchaseState.purchased,
    );
  }

  /// Premium satın alma başlat
  Future<bool> buyPremium(PremiumPlan plan) async {
    // Debug modda gerçek IAP yerine doğrudan aktifleştir
    if (kDebugMode && AppEnvironmentConfig().isDev) {
      debugPrint('IAP: Debug mode – activating premium directly');
      await activatePremium(
        productId: productIdForPlan(plan),
        purchaseDate: DateTime.now(),
      );
      _stateController.add(PurchaseState.purchased);
      return true;
    }

    if (!_iapAvailable) {
      _stateController.add(PurchaseState.storeUnavailable);
      return false;
    }

    final product = productForPlan(plan);

    if (product == null) {
      debugPrint('IAP: Product ${productIdForPlan(plan)} not found');
      _stateController.add(PurchaseState.productNotFound);
      return false;
    }

    final purchaseParam = PurchaseParam(productDetails: product);
    try {
      // in_app_purchase API'de subscription satın alımı da buyNonConsumable ile başlatılır.
      final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!started) {
        _stateController.add(PurchaseState.error);
      }
      return started;
    } catch (e) {
      debugPrint('IAP buyPremium error: $e');
      _stateController.add(PurchaseState.error);
      return false;
    }
  }

  /// Önceki satın almayı geri yükle
  Future<void> restorePurchases() async {
    // Debug modda gerçek IAP yerine doğrudan aktifleştir
    if (kDebugMode && AppEnvironmentConfig().isDev) {
      debugPrint('IAP: Debug mode – restoring premium directly');
      await activatePremium(
        productId: yearlySubscriptionProductId,
        purchaseDate: DateTime.now(),
      );
      _stateController.add(PurchaseState.restored);
      return;
    }

    if (!_iapAvailable) {
      _stateController.add(PurchaseState.storeUnavailable);
      return;
    }
    _stateController.add(PurchaseState.restoring);
    try {
      await _iap.restorePurchases();
    } catch (e) {
      debugPrint('IAP restore error: $e');
      _stateController.add(PurchaseState.error);
    }
  }

  ProductDetails? productForPlan(PremiumPlan plan) {
    return _products.cast<ProductDetails?>().firstWhere(
      (p) => p?.id == productIdForPlan(plan),
      orElse: () => null,
    );
  }

  String? priceForPlan(PremiumPlan plan) {
    return productForPlan(plan)?.price;
  }

  String productIdForPlan(PremiumPlan plan) {
    return switch (plan) {
      PremiumPlan.monthly => monthlySubscriptionProductId,
      PremiumPlan.yearly => yearlySubscriptionProductId,
    };
  }

  /// Premium'u aktifleştir
  Future<void> activatePremium({
    String? productId,
    DateTime? purchaseDate,
  }) async {
    if (productId != null && !_productIds.contains(productId)) {
      debugPrint(
        'IAP: activatePremium blocked for unknown product id: $productId',
      );
      return;
    }

    _isPremium = true;
    _activePlan = _planFromProductId(productId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, true);
    await prefs.setString(
      _keyPurchaseDate,
      (purchaseDate ?? DateTime.now()).toIso8601String(),
    );
    if (productId != null) {
      await prefs.setString(_keyPremiumProductId, productId);
    }
  }

  DateTime? _parseStorePurchaseDate(String? rawMillis) {
    if (rawMillis == null || rawMillis.isEmpty) return null;
    final millis = int.tryParse(rawMillis);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  bool _isStoredEntitlementActive({
    required bool isPremiumFlag,
    required PremiumPlan? plan,
    required DateTime? purchaseDate,
  }) {
    if (!isPremiumFlag) return false;
    if (plan == null || purchaseDate == null) return false;

    final expiry = _estimatedExpiryDate(plan, purchaseDate);
    return DateTime.now().isBefore(expiry);
  }

  DateTime _estimatedExpiryDate(PremiumPlan plan, DateTime purchaseDate) {
    return switch (plan) {
      PremiumPlan.monthly => DateTime(
        purchaseDate.year,
        purchaseDate.month + 1,
        purchaseDate.day,
        purchaseDate.hour,
        purchaseDate.minute,
        purchaseDate.second,
        purchaseDate.millisecond,
        purchaseDate.microsecond,
      ),
      PremiumPlan.yearly => DateTime(
        purchaseDate.year + 1,
        purchaseDate.month,
        purchaseDate.day,
        purchaseDate.hour,
        purchaseDate.minute,
        purchaseDate.second,
        purchaseDate.millisecond,
        purchaseDate.microsecond,
      ),
    };
  }

  /// Premium'u deaktifleştir (test için)
  Future<void> deactivatePremium() async {
    _isPremium = false;
    _activePlan = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, false);
    await prefs.remove(_keyPurchaseDate);
    await prefs.remove(_keyPremiumProductId);
  }

  Future<void> clearLocalState() async {
    _isPremium = false;
    _activePlan = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  PremiumPlan? _planFromProductId(String? productId) {
    return switch (productId) {
      monthlySubscriptionProductId => PremiumPlan.monthly,
      yearlySubscriptionProductId => PremiumPlan.yearly,
      _ => null,
    };
  }

  /// Satın alma tarihi
  Future<String?> getPurchaseDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPurchaseDate);
  }

  // ── Limit Kontrolleri ──

  bool canAddClient(int currentCount) {
    if (_isPremium) return true;
    return currentCount < freeMaxClients;
  }

  bool canAddPeriod(int currentPeriodCount) {
    if (_isPremium) return true;
    return currentPeriodCount < freeMaxPeriodsPerClient;
  }

  bool get canAccessBodyMeasurements => _isPremium;
  bool get canAccessWeeklyPlan => _isPremium;
  bool get canAccessPaymentTracking => _isPremium;
  bool get canAccessAnalysis => _isPremium;

  /// Offer kodunu kullan
  /// iOS: Apple'ın native redemption sheet'ini açar (kod orada girilir)
  /// Android: Google Play redemption URL'ini açar (kod URL'e eklenir)
  Future<void> redeemOfferCode(String offerCode) async {
    // Debug modda doğrudan aktifleştir
    if (kDebugMode && AppEnvironmentConfig().isDev) {
      debugPrint('IAP: Debug mode – activating premium via offer code');
      await activatePremium(
        productId: yearlySubscriptionProductId,
        purchaseDate: DateTime.now(),
      );
      _stateController.add(PurchaseState.purchased);
      return;
    }

    if (!_iapAvailable) {
      _stateController.add(PurchaseState.storeUnavailable);
      return;
    }

    _stateController.add(PurchaseState.pending);

    if (Platform.isIOS) {
      // iOS: StoreKit native sheet – kullanıcı kodu orada girer
      // Uygulamamızda girilen kodu görmezden gelebiliriz; Apple kendi UI'ını sunar.
      try {
        final iosPlatformAddition = _iap
            .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        await iosPlatformAddition.presentCodeRedemptionSheet();
      } catch (e) {
        debugPrint('IAP iOS offer sheet error: $e');
        _stateController.add(PurchaseState.error);
        return;
      }
    } else {
      // Android: Google Play promo code deep link
      final code = Uri.encodeComponent(offerCode.trim());
      final uri = Uri.parse('https://play.google.com/redeem?code=$code');
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        debugPrint('IAP Android: Could not open Play Store redemption URL');
        _stateController.add(PurchaseState.error);
        return;
      }
    }

    // Store'dan döndükten sonra entitlemente algılamak için restore çalıştır.
    // Bu, IAP stream'i üzerinden _handlePurchaseUpdates'i tetikler.
    unawaited(restorePurchases());
  }

  /// Kaynakları temizle
  void dispose() {
    _subscription?.cancel();
    _stateController.close();
  }
}

/// Satın alma durumu – UI bildirimler için
enum PurchaseState {
  pending,
  purchased,
  restored,
  restoring,
  error,
  cancelled,
  storeUnavailable,
  productNotFound,
}

enum PremiumPlan { monthly, yearly }
