import 'dart:ui';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/user.dart';
import '../services/premium_service.dart';
import 'premium_page.dart';
import '../widgets/app_background.dart';
import '../widgets/monthly_analysis_widget.dart';

class AnalysisPage extends StatelessWidget {
  final User currentUser;

  const AnalysisPage({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final canAccessAnalysis = PremiumService().canAccessAnalysis;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 600
                  ? 16.0
                  : 24.0;

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      24,
                      horizontalPadding,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                ),
                                color: const Color(0xFF1E88E5),
                                tooltip: MaterialLocalizations.of(
                                  context,
                                ).backButtonTooltip,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.analysis,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1565C0),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l.analysisDesc,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (canAccessAnalysis)
                                  MonthlyAnalysisWidget(
                                    currentUser: currentUser,
                                  )
                                else
                                  _PremiumLockedCard(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PremiumLockedCard extends StatelessWidget {
  const _PremiumLockedCard();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB300).withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFA000),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.premiumRequired,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(l.analysisDesc, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: const _AnalysisPreviewTeaser(),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.white.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          l.analysisPreviewTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.analysisPreviewTeaser,
                          style: TextStyle(color: Colors.grey[800]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PremiumPage()));
            },
            icon: const Icon(Icons.lock_open_rounded),
            label: Text(l.upgradeToPremium),
          ),
        ],
      ),
    );
  }
}

class _AnalysisPreviewTeaser extends StatelessWidget {
  const _AnalysisPreviewTeaser();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompactLayout = constraints.maxWidth < 360;
        return Container(
          height: useCompactLayout ? 320 : 220,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF7FBFF), Color(0xFFE9F4FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _teaserCard(const Color(0xFF2E7D32)),
                  const SizedBox(width: 10),
                  _teaserCard(const Color(0xFF1565C0)),
                  const SizedBox(width: 10),
                  _teaserCard(const Color(0xFFEF6C00)),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: useCompactLayout
                    ? Column(
                        children: [
                          Expanded(child: _lineChartCard()),
                          const SizedBox(height: 12),
                          SizedBox(height: 110, child: _donutChartCard()),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _lineChartCard()),
                          const SizedBox(width: 12),
                          SizedBox(width: 110, child: _donutChartCard()),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _teaserCard(Color color) {
    return Expanded(
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _lineChartCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: CustomPaint(
        painter: _PreviewLinePainter(),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _donutChartCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: CustomPaint(
        painter: const _PreviewDonutPainter(
          segments: [
            _PreviewSegment(value: 40, color: Color(0xFF6A1B9A)),
            _PreviewSegment(value: 35, color: Color(0xFFEF6C00)),
            _PreviewSegment(value: 25, color: Color(0xFF00838F)),
          ],
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PreviewLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFD8E6F7)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height / 3 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final expectedPath = Path()
      ..moveTo(0, size.height * 0.7)
      ..lineTo(size.width * 0.2, size.height * 0.55)
      ..lineTo(size.width * 0.4, size.height * 0.6)
      ..lineTo(size.width * 0.6, size.height * 0.35)
      ..lineTo(size.width * 0.8, size.height * 0.4)
      ..lineTo(size.width, size.height * 0.2);

    final paidPath = Path()
      ..moveTo(0, size.height * 0.8)
      ..lineTo(size.width * 0.2, size.height * 0.68)
      ..lineTo(size.width * 0.4, size.height * 0.63)
      ..lineTo(size.width * 0.6, size.height * 0.52)
      ..lineTo(size.width * 0.8, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.34);

    canvas.drawPath(
      expectedPath,
      Paint()
        ..color = const Color(0xFF1565C0)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      paidPath,
      Paint()
        ..color = const Color(0xFF2E7D32)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PreviewSegment {
  final double value;
  final Color color;

  const _PreviewSegment({required this.value, required this.color});
}

class _PreviewDonutPainter extends CustomPainter {
  final List<_PreviewSegment> segments;

  const _PreviewDonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(
      0,
      (sum, segment) => sum + segment.value,
    );
    if (total <= 0) {
      return;
    }

    final strokeWidth = size.width * 0.18;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    var startAngle = -3.141592653589793 / 2;

    for (final segment in segments) {
      final sweep = (segment.value / total) * 3.141592653589793 * 2;
      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        false,
        Paint()
          ..color = segment.color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewDonutPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}
