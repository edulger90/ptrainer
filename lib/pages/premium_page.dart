import 'dart:async';
import 'package:flutter/material.dart';

import '../config/app_environment.dart';
import '../services/premium_service.dart';
import '../widgets/app_background.dart';
import '../l10n/app_localizations.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  final _premium = PremiumService();
  StreamSubscription<PurchaseState>? _purchaseSub;
  PremiumPlan _selectedPlan = PremiumPlan.yearly;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _purchaseSub = _premium.stateStream.listen(_onPurchaseState);
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  void _onPurchaseState(PurchaseState state) {
    if (!mounted) return;
    final l = AppLocalizations.of(context);

    setState(() => _isLoading = false);

    switch (state) {
      case PurchaseState.pending:
        setState(() => _isLoading = true);
        break;
      case PurchaseState.purchased:
        setState(() {});
        _showSnack(l.premiumPurchaseSuccess, isSuccess: true);
        break;
      case PurchaseState.restored:
      case PurchaseState.restoring:
        if (_premium.isPremium) {
          setState(() {});
          _showSnack(l.premiumRestoreSuccess, isSuccess: true);
        }
        break;
      case PurchaseState.error:
        _showSnack(l.premiumPurchaseError);
        break;
      case PurchaseState.cancelled:
        // Kullanıcı iptal etti, sessizce geç
        break;
      case PurchaseState.storeUnavailable:
        _showSnack(l.premiumStoreUnavailable);
        break;
      case PurchaseState.productNotFound:
        _showSnack(l.premiumProductNotFound);
        break;
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? const Color(0xFF00897B) : null,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _planTitle(AppLocalizations l, PremiumPlan plan) {
    return switch (plan) {
      PremiumPlan.monthly => l.premiumMonthly,
      PremiumPlan.yearly => l.premiumYearly,
    };
  }

  String _planSubtitle(AppLocalizations l, PremiumPlan plan) {
    return switch (plan) {
      PremiumPlan.monthly => l.premiumMonthlyDesc,
      PremiumPlan.yearly => l.premiumYearlyDesc,
    };
  }

  String _planPrice(PremiumPlan plan, bool isDevEnvironment) {
    final fallback = switch (plan) {
      PremiumPlan.monthly => isDevEnvironment ? r'$4.99 (Test)' : '',
      PremiumPlan.yearly => isDevEnvironment ? r'$39.99 (Test)' : '',
    };
    return _premium.priceForPlan(plan) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final isDevEnvironment = AppEnvironmentConfig().isDev;
    final l = AppLocalizations.of(context);
    final isPremium = _premium.isPremium;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Üst Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF00897B),
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l.premiumTitle,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isPremium)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFB300), Color(0xFFFFC107)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.workspace_premium,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l.premiumActive,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // ── Premium Crown ──
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFB300), Color(0xFFFFC107)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFFB300,
                              ).withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isPremium ? l.premiumThanks : l.premiumUnlock,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPremium ? l.premiumActiveDesc : l.premiumDesc,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      if (isPremium && _premium.activePlan != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          switch (_premium.activePlan!) {
                            PremiumPlan.monthly => l.premiumMonthlyActive,
                            PremiumPlan.yearly => l.premiumYearlyActive,
                          },
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00897B),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // ── Özellik Karşılaştırma ──
                      _FeatureRow(
                        icon: Icons.people,
                        title: l.premiumFeatureClients,
                        freeValue: '${PremiumService.freeMaxClients}',
                        premiumValue: l.premiumUnlimited,
                      ),
                      _FeatureRow(
                        icon: Icons.timeline,
                        title: l.premiumFeaturePeriods,
                        freeValue: '${PremiumService.freeMaxPeriodsPerClient}',
                        premiumValue: l.premiumUnlimited,
                      ),
                      _FeatureRow(
                        icon: Icons.straighten,
                        title: l.premiumFeatureMeasurements,
                        freeValue: '—',
                        premiumValue: '✓',
                        freeBlocked: true,
                      ),
                      _FeatureRow(
                        icon: Icons.calendar_month,
                        title: l.premiumFeatureWeeklyPlan,
                        freeValue: '—',
                        premiumValue: '✓',
                        freeBlocked: true,
                      ),
                      _FeatureRow(
                        icon: Icons.payments,
                        title: l.premiumFeaturePayments,
                        freeValue: '—',
                        premiumValue: '✓',
                        freeBlocked: true,
                      ),

                      const SizedBox(height: 24),

                      // ── Satın Al veya Geri Yükle ──
                      if (!isPremium) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l.premiumChoosePlan,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PlanCard(
                          title: _planTitle(l, PremiumPlan.monthly),
                          subtitle: _planSubtitle(l, PremiumPlan.monthly),
                          price: _planPrice(
                            PremiumPlan.monthly,
                            isDevEnvironment,
                          ),
                          selected: _selectedPlan == PremiumPlan.monthly,
                          onTap: () {
                            setState(() => _selectedPlan = PremiumPlan.monthly);
                          },
                        ),
                        const SizedBox(height: 12),
                        _PlanCard(
                          title: _planTitle(l, PremiumPlan.yearly),
                          subtitle: _planSubtitle(l, PremiumPlan.yearly),
                          price: _planPrice(
                            PremiumPlan.yearly,
                            isDevEnvironment,
                          ),
                          selected: _selectedPlan == PremiumPlan.yearly,
                          badgeText: l.premiumBestValue,
                          onTap: () {
                            setState(() => _selectedPlan = PremiumPlan.yearly);
                          },
                        ),
                        const SizedBox(height: 16),
                        // Satın Al butonu
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFB300),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                            ),
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    setState(() => _isLoading = true);
                                    await _premium.buyPremium(_selectedPlan);
                                    // Sonuç _onPurchaseState'ten gelecek
                                  },
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.workspace_premium,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${l.premiumBuy} • ${_planPrice(_selectedPlan, isDevEnvironment)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Geri Yükle
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  _premium.restorePurchases();
                                },
                          child: Text(
                            l.premiumRestore,
                            style: const TextStyle(
                              color: Color(0xFF00897B),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],

                      // ── DEV: Test butonları (sadece debug modda) ──
                      if (isDevEnvironment) ...[
                        const SizedBox(height: 30),
                        const Divider(),
                        Text(
                          '🛠 Developer Test',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () async {
                            if (isPremium) {
                              await _premium.deactivatePremium();
                            } else {
                              await _premium.activatePremium(
                                productId: _premium.productIdForPlan(
                                  _selectedPlan,
                                ),
                              );
                            }
                            setState(() {});
                          },
                          child: Text(
                            isPremium
                                ? 'Deactivate Premium (Test)'
                                : 'Activate Premium (Test)',
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final bool selected;
  final VoidCallback onTap;
  final String? badgeText;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.selected,
    required this.onTap,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF00897B)
                  : Colors.grey.withValues(alpha: 0.18),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00897B).withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3CD),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badgeText!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8D6E00),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFB300),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected
                        ? const Color(0xFF00897B)
                        : Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature Comparison Row ──
class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String freeValue;
  final String premiumValue;
  final bool freeBlocked;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.freeValue,
    required this.premiumValue,
    this.freeBlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF00897B)),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Free
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    l.premiumFree,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    freeValue,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: freeBlocked ? Colors.red[300] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            // Premium
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    l.premiumLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFFFB300),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    premiumValue,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00897B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
