import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/program_type.dart';
import '../models/screen_preload.dart';
import '../models/user.dart';
import '../services/screen_preload_service.dart';

class MonthlyAnalysisWidget extends StatefulWidget {
  final User currentUser;

  const MonthlyAnalysisWidget({super.key, required this.currentUser});

  @override
  State<MonthlyAnalysisWidget> createState() => _MonthlyAnalysisWidgetState();
}

class _MonthlyAnalysisWidgetState extends State<MonthlyAnalysisWidget> {
  final _screenPreloadService = ScreenPreloadService();
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  bool _loading = true;
  HomeMonthlyAnalyticsPreload? _analytics;

  @override
  void initState() {
    super.initState();
    _loadAnalytics(referenceDate: _selectedMonth);
  }

  Future<void> _loadAnalytics({DateTime? referenceDate}) async {
    final effectiveMonth = DateTime(
      (referenceDate ?? _selectedMonth).year,
      (referenceDate ?? _selectedMonth).month,
    );
    final userId = widget.currentUser.id;
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _selectedMonth = effectiveMonth;
        _analytics = null;
        _loading = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _selectedMonth = effectiveMonth;
        _loading = true;
      });
    }

    final preload = await _screenPreloadService.loadHomeMonthlyAnalytics(
      userId: userId,
      referenceDate: effectiveMonth,
    );

    if (!mounted) return;
    setState(() {
      _analytics = preload;
      _loading = false;
    });
  }

  String _money(double value) {
    return value.toStringAsFixed(2);
  }

  String _monthLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '$month.${date.year}';
  }

  List<DateTime> _availableMonths() {
    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    return List.generate(
      24,
      (index) => DateTime(currentMonth.year, currentMonth.month - index, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final analytics = _analytics;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF1E88E5).withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E88E5).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                  ),
                ),
                child: const Icon(Icons.analytics_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.monthlyAnalysisTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (analytics != null)
                      Text(
                        _monthLabel(analytics.monthStart),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMonthPicker(context),
          const SizedBox(height: 14),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (analytics == null)
            Text(
              l.monthlyAnalysisNoData,
              style: TextStyle(color: Colors.grey[600]),
            )
          else
            ..._buildAnalyticsContent(context, analytics),
        ],
      ),
    );
  }

  List<Widget> _buildAnalyticsContent(
    BuildContext context,
    HomeMonthlyAnalyticsPreload analytics,
  ) {
    final l = AppLocalizations.of(context);
    final expectedAmount = analytics.totalExpectedAmount;
    final paidAmount = analytics.totalPaidAmount;
    final outstandingAmount = math.max(0.0, expectedAmount - paidAmount);
    final collectionRate = expectedAmount <= 0
        ? 0.0
        : (paidAmount / expectedAmount) * 100;

    return [
      Text(
        l.monthlyOverviewTitle,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      _buildResponsiveGrid(
        minTileWidth: 150,
        childAspectRatio: 1.08,
        children: [
          _buildMetricCard(
            label: l.monthlyPaidTotal,
            value: '${_money(paidAmount)} TL',
            accentColor: const Color(0xFF2E7D32),
            icon: Icons.payments_rounded,
          ),
          _buildMetricCard(
            label: l.monthlyExpectedTotal,
            value: '${_money(expectedAmount)} TL',
            accentColor: const Color(0xFF1565C0),
            icon: Icons.account_balance_wallet_rounded,
          ),
          _buildMetricCard(
            label: l.monthlyCollectionRate,
            value: '%${collectionRate.toStringAsFixed(1)}',
            accentColor: const Color(0xFF6A1B9A),
            icon: Icons.trending_up_rounded,
          ),
          _buildMetricCard(
            label: l.monthlyOutstandingAmount,
            value: '${_money(outstandingAmount)} TL',
            accentColor: const Color(0xFFEF6C00),
            icon: Icons.pending_actions_rounded,
          ),
          _buildMetricCard(
            label: l.monthlyNonHolidayCancelCount,
            value: '${analytics.cancelledNonHolidayCount}',
            accentColor: const Color(0xFFC62828),
            icon: Icons.event_busy_rounded,
          ),
          _buildMetricCard(
            label: l.monthlySelectedMonth,
            value: _monthLabel(analytics.monthStart),
            accentColor: const Color(0xFF00838F),
            icon: Icons.calendar_month_rounded,
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildCollectionProgressCard(
        context: context,
        collectionRate: collectionRate,
        outstandingAmount: outstandingAmount,
      ),
      const SizedBox(height: 16),
      ..._buildInsightSection(
        context,
        analytics,
        collectionRate,
        outstandingAmount,
      ),
      const SizedBox(height: 16),
      ..._buildChartsSection(context, analytics),
      const SizedBox(height: 16),
      Text(
        l.monthlyTopCancellationsTitle,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      if (analytics.topCancelledItems.isEmpty)
        Text(
          l.monthlyTopCancellationsEmpty,
          style: TextStyle(color: Colors.grey[600]),
        )
      else
        ...analytics.topCancelledItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final totalNonHoliday = analytics.cancelledNonHolidayCount;
          final share = totalNonHoliday == 0
              ? 0.0
              : (item.cancelledCount / totalNonHoliday) * 100;
          final rate = item.monthlyLessonCount == 0
              ? 0.0
              : (item.cancelledCount / item.monthlyLessonCount) * 100;

          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 10),
            child: _buildCancellationChartRow(
              context: context,
              rank: index + 1,
              item: item,
              share: share,
              rate: rate,
            ),
          );
        }),
    ];
  }

  List<Widget> _buildChartsSection(
    BuildContext context,
    HomeMonthlyAnalyticsPreload analytics,
  ) {
    final l = AppLocalizations.of(context);

    return [
      Text(
        l.monthlyChartsTitle,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      _buildResponsiveGrid(
        minTileWidth: 300,
        childAspectRatio: 1.12,
        children: [
          _buildRevenueTrendCard(context, analytics),
          _buildProgramTypeChartCard(context, analytics),
        ],
      ),
    ];
  }

  List<Widget> _buildInsightSection(
    BuildContext context,
    HomeMonthlyAnalyticsPreload analytics,
    double collectionRate,
    double outstandingAmount,
  ) {
    final l = AppLocalizations.of(context);
    final mostCancelled = analytics.topCancelledItems.isEmpty
        ? null
        : analytics.topCancelledItems.first;
    MonthlyCancellationItem? highestRateItem;
    double highestRate = 0;

    for (final item in analytics.topCancelledItems) {
      final rate = item.monthlyLessonCount == 0
          ? 0.0
          : (item.cancelledCount / item.monthlyLessonCount) * 100;
      if (highestRateItem == null || rate > highestRate) {
        highestRateItem = item;
        highestRate = rate;
      }
    }

    final collectionStatus = collectionRate >= 100
        ? l.monthlyStatusStrong
        : (collectionRate >= 70
              ? l.monthlyStatusWatch
              : l.monthlyStatusAttention);

    return [
      Text(
        l.monthlyInsightsTitle,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      _buildResponsiveGrid(
        minTileWidth: 220,
        childAspectRatio: 1.45,
        children: [
          _buildInsightCard(
            label: l.monthlyMostCancelledLabel,
            title:
                mostCancelled?.client.fullName ??
                l.monthlyTopCancellationsEmpty,
            subtitle: mostCancelled == null
                ? l.monthlyAnalysisNoData
                : l.monthlyTopCancellationMetrics(
                    mostCancelled.cancelledCount,
                    analytics.cancelledNonHolidayCount == 0
                        ? '0.0'
                        : ((mostCancelled.cancelledCount /
                                      analytics.cancelledNonHolidayCount) *
                                  100)
                              .toStringAsFixed(1),
                    mostCancelled.monthlyLessonCount == 0
                        ? '0.0'
                        : ((mostCancelled.cancelledCount /
                                      mostCancelled.monthlyLessonCount) *
                                  100)
                              .toStringAsFixed(1),
                  ),
            accentColor: const Color(0xFFC62828),
            icon: Icons.warning_amber_rounded,
          ),
          _buildInsightCard(
            label: l.monthlyHighestCancellationRateLabel,
            title:
                highestRateItem?.client.fullName ??
                l.monthlyTopCancellationsEmpty,
            subtitle: highestRateItem == null
                ? l.monthlyAnalysisNoData
                : '%${highestRate.toStringAsFixed(1)}',
            accentColor: const Color(0xFF6A1B9A),
            icon: Icons.show_chart_rounded,
          ),
          _buildInsightCard(
            label: l.monthlyCollectionStatusLabel,
            title: collectionStatus,
            subtitle:
                '${l.monthlyOutstandingAmount}: ${_money(outstandingAmount)} TL',
            accentColor: const Color(0xFF1565C0),
            icon: Icons.assessment_rounded,
          ),
        ],
      ),
    ];
  }

  Widget _buildMonthPicker(BuildContext context) {
    final l = AppLocalizations.of(context);

    return PopupMenuButton<DateTime>(
      tooltip: l.selectMonthYear,
      onSelected: (value) => _loadAnalytics(referenceDate: value),
      itemBuilder: (context) {
        return _availableMonths().map((month) {
          final selected =
              month.year == _selectedMonth.year &&
              month.month == _selectedMonth.month;
          return PopupMenuItem<DateTime>(
            value: month,
            child: Row(
              children: [
                Expanded(child: Text(_monthLabel(month))),
                if (selected)
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: Color(0xFF1565C0),
                  ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF1E88E5).withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: Color(0xFF1565C0),
            ),
            const SizedBox(width: 8),
            Text(
              _monthLabel(_selectedMonth),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            Text(
              l.selectMonthYear,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF1565C0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid({
    required List<Widget> children,
    required double minTileWidth,
    required double childAspectRatio,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = math.max(
          1,
          (constraints.maxWidth / minTileWidth).floor(),
        );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }

  Widget _buildRevenueTrendCard(
    BuildContext context,
    HomeMonthlyAnalyticsPreload analytics,
  ) {
    final l = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.monthlyRevenueTrendTitle,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              painter: _RevenueTrendChartPainter(
                points: analytics.revenueTrend,
                paidColor: const Color(0xFF2E7D32),
                expectedColor: const Color(0xFF1565C0),
                gridColor: const Color(0xFFD8E6F7),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  analytics.revenueTrend.isEmpty
                      ? ''
                      : _monthLabel(analytics.revenueTrend.first.monthStart),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
              Text(
                analytics.revenueTrend.isEmpty
                    ? ''
                    : _monthLabel(analytics.revenueTrend.last.monthStart),
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildLegendItem(
                color: const Color(0xFF2E7D32),
                label: l.monthlyTrendPaidLegend,
              ),
              _buildLegendItem(
                color: const Color(0xFF1565C0),
                label: l.monthlyTrendExpectedLegend,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgramTypeChartCard(
    BuildContext context,
    HomeMonthlyAnalyticsPreload analytics,
  ) {
    final l = AppLocalizations.of(context);
    final segments = analytics.cancellationDistribution;
    final total = segments.fold<int>(0, (sum, item) => sum + item.count);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: 0.14),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final vertical = constraints.maxWidth < 360;
          final chart = SizedBox(
            width: 140,
            height: 140,
            child: total == 0
                ? Center(
                    child: Text(
                      l.monthlyChartsEmpty,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  )
                : CustomPaint(
                    painter: _DonutChartPainter(
                      segments: [
                        for (final segment in segments)
                          _ChartSegment(
                            value: segment.count.toDouble(),
                            color: _programTypeColor(segment.programType),
                          ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$total',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
          );

          final legend = Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.monthlyProgramTypeChartTitle,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (segments.isEmpty)
                  Text(
                    l.monthlyChartsEmpty,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  )
                else
                  ...segments.map(
                    (segment) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildLegendItem(
                        color: _programTypeColor(segment.programType),
                        label:
                            '${_programTypeLabel(context, segment.programType)} • ${segment.count}',
                      ),
                    ),
                  ),
              ],
            ),
          );

          return vertical
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [chart, const SizedBox(height: 12), legend],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [chart, const SizedBox(width: 16), legend],
                );
        },
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Color _programTypeColor(ProgramType programType) {
    switch (programType) {
      case ProgramType.personal:
        return const Color(0xFF6A1B9A);
      case ProgramType.course:
        return const Color(0xFFEF6C00);
      case ProgramType.sport:
        return const Color(0xFF00838F);
    }
  }

  String _programTypeLabel(BuildContext context, ProgramType programType) {
    final l = AppLocalizations.of(context);
    switch (programType) {
      case ProgramType.personal:
        return l.programTypePersonal;
      case ProgramType.course:
        return l.programTypeCourse;
      case ProgramType.sport:
        return l.programTypeSport;
    }
  }

  Widget _buildCollectionProgressCard({
    required BuildContext context,
    required double collectionRate,
    required double outstandingAmount,
  }) {
    final l = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_rounded,
                size: 18,
                color: Color(0xFF1565C0),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.monthlyCollectionRate,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '%${collectionRate.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: (collectionRate / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF1565C0)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${l.monthlyOutstandingAmount}: ${_money(outstandingAmount)} TL',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationChartRow({
    required BuildContext context,
    required int rank,
    required MonthlyCancellationItem item,
    required double share,
    required double rate,
  }) {
    final l = AppLocalizations.of(context);
    final programType = item.client.programType == ProgramType.personal
        ? l.programTypePersonal
        : (item.client.programType == ProgramType.course
              ? l.programTypeCourse
              : l.programTypeSport);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF42A5F5).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF1565C0),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.client.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      programType,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                '%${share.toStringAsFixed(1)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: (share / 100).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFDCEBFF),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF42A5F5)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.monthlyTopCancellationMetrics(
              item.cancelledCount,
              share.toStringAsFixed(1),
              rate.toStringAsFixed(1),
            ),
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accentColor),
          const Spacer(),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: accentColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required String label,
    required String title,
    required String subtitle,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accentColor),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RevenueTrendChartPainter extends CustomPainter {
  final List<MonthlyRevenuePoint> points;
  final Color paidColor;
  final Color expectedColor;
  final Color gridColor;

  const _RevenueTrendChartPainter({
    required this.points,
    required this.paidColor,
    required this.expectedColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const paddingLeft = 10.0;
    const paddingTop = 10.0;
    const paddingBottom = 12.0;
    final width = size.width - paddingLeft;
    final height = size.height - paddingTop - paddingBottom;
    if (width <= 0 || height <= 0 || points.isEmpty) {
      return;
    }

    final rect = Rect.fromLTWH(paddingLeft, paddingTop, width, height);
    final maxValue = points.fold<double>(0, (maxValue, point) {
      return math.max(
        maxValue,
        math.max(point.paidAmount, point.expectedAmount),
      );
    });
    final effectiveMax = maxValue <= 0 ? 1.0 : maxValue;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = rect.top + (rect.height / 3) * i;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }

    void drawSeries(
      Color color,
      double Function(MonthlyRevenuePoint) selector,
    ) {
      final path = Path();
      for (var index = 0; index < points.length; index++) {
        final point = points[index];
        final dx =
            rect.left + (rect.width / math.max(1, points.length - 1)) * index;
        final dy =
            rect.bottom - ((selector(point) / effectiveMax) * rect.height);
        if (index == 0) {
          path.moveTo(dx, dy);
        } else {
          path.lineTo(dx, dy);
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      for (var index = 0; index < points.length; index++) {
        final point = points[index];
        final dx =
            rect.left + (rect.width / math.max(1, points.length - 1)) * index;
        final dy =
            rect.bottom - ((selector(point) / effectiveMax) * rect.height);
        canvas.drawCircle(Offset(dx, dy), 3.5, Paint()..color = color);
      }
    }

    drawSeries(expectedColor, (point) => point.expectedAmount);
    drawSeries(paidColor, (point) => point.paidAmount);
  }

  @override
  bool shouldRepaint(covariant _RevenueTrendChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _ChartSegment {
  final double value;
  final Color color;

  const _ChartSegment({required this.value, required this.color});
}

class _DonutChartPainter extends CustomPainter {
  final List<_ChartSegment> segments;

  const _DonutChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<double>(
      0,
      (sum, segment) => sum + segment.value,
    );
    if (total <= 0) {
      return;
    }

    final strokeWidth = math.min(size.width, size.height) * 0.2;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    var startAngle = -math.pi / 2;

    for (final segment in segments) {
      final sweep = (segment.value / total) * math.pi * 2;
      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        false,
        Paint()
          ..color = segment.color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}
