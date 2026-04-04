import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_environment.dart';

/// Premium / Free tier yönetim servisi.
/// In-App Purchase ile gerçek ödeme entegrasyonu.
/// Non-consumable (bir kere satın al, hep kullan) model.
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
    _isPremium = prefs.getBool(_keyIsPremium) ?? false;
    _activePlan = _planFromProductId(prefs.getString(_keyPremiumProductId));

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
    // Not: Gerçek bir üretim uygulamasında burada sunucu taraflı
    // receipt validation yapılmalıdır. Basit uygulamalar için
    // client-side yeterlidir.
    await activatePremium(productId: purchase.productID);
    _stateController.add(
      purchase.status == PurchaseStatus.restored
          ? PurchaseState.restored
          : PurchaseState.purchased,
    );
  }

  /// Premium satın alma başlat
  Future<bool> buyPremium(PremiumPlan plan) async {
    // Debug modda gerçek IAP yerine doğrudan aktifleştir
    if (AppEnvironmentConfig().isDev) {
      debugPrint('IAP: Debug mode – activating premium directly');
      await activatePremium(productId: productIdForPlan(plan));
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
      // Subscriptions are also initiated through buyNonConsumable in this API.
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
    if (AppEnvironmentConfig().isDev) {
      debugPrint('IAP: Debug mode – restoring premium directly');
      await activatePremium(productId: yearlySubscriptionProductId);
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
  Future<void> activatePremium({String? productId}) async {
    _isPremium = true;
    _activePlan = _planFromProductId(productId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, true);
    await prefs.setString(_keyPurchaseDate, DateTime.now().toIso8601String());
    if (productId != null) {
      await prefs.setString(_keyPremiumProductId, productId);
    }
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
