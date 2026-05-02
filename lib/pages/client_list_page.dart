import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/package_type.dart';
import '../models/period.dart';
import '../models/session_schedule.dart';
import '../models/trainer_weekday.dart';
import '../models/user.dart';
import '../services/database.dart';
import '../services/error_logger.dart';
import '../services/premium_service.dart';
import '../services/screen_preload_service.dart';
import '../services/session_timeout_service.dart';
import '../pages/premium_page.dart';
import 'add_client_page.dart';
import 'client_detail_page.dart';
import '../widgets/app_background.dart';
import '../l10n/app_localizations.dart';

class ClientListPage extends StatefulWidget {
  final User currentUser;
  const ClientListPage({super.key, required this.currentUser});

  @override
  State<ClientListPage> createState() => _ClientListPageState();
}

class _ClientListPageState extends State<ClientListPage> {
  final _db = AppDatabase();
  final _screenPreloadService = ScreenPreloadService();
  List<Client> _clients = [];
  bool _showActive = true;
  // clientId -> (latestPeriod, completedCount)
  Map<int, (Period?, int)> _clientPeriodInfo = {};
  Map<int, Set<int>> _scheduledWeekdaysByClientId = {};

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final preloads = await _screenPreloadService.loadClientListPreloads(
        userId: widget.currentUser.id ?? 0,
      );
      final clients = preloads.map((preload) => preload.client).toList();
      final clientIds = clients.map((c) => c.id).whereType<int>().toList();
      final schedules = clientIds.isEmpty
          ? const <SessionSchedule>[]
          : await _db.getSessionSchedulesByClientIds(clientIds);

      final scheduleWeekdays = <int, Set<int>>{};
      for (final schedule in schedules) {
        final clientId = schedule.clientId;
        final weekday = TrainerWeekday.fromStorageKey(
          schedule.dayOfWeek,
        )?.weekdayNumber;
        if (clientId == null || weekday == null) continue;
        scheduleWeekdays.putIfAbsent(clientId, () => <int>{}).add(weekday);
      }

      final periodInfo = <int, (Period?, int)>{};
      for (final preload in preloads) {
        final cid = preload.client.id ?? 0;
        if (cid == 0) continue;
        periodInfo[cid] = (preload.latestPeriod, preload.completedLessons);
      }
      if (!mounted) return;
      setState(() {
        _clients = clients;
        _clientPeriodInfo = periodInfo;
        _scheduledWeekdaysByClientId = scheduleWeekdays;
      });
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: '_ClientListPageState._loadClients',
      );
      if (!mounted) return;
      setState(() {
        _clients = [];
        _scheduledWeekdaysByClientId = {};
      });
    }
  }

  int _countLessonsInRange({
    required DateTime startDate,
    required DateTime endDate,
    required Set<int> weekdays,
  }) {
    if (weekdays.isEmpty) return 0;
    if (endDate.isBefore(startDate)) return 0;

    int count = 0;
    DateTime current = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);
    while (!current.isAfter(normalizedEnd)) {
      if (weekdays.contains(current.weekday)) count++;
      current = current.add(const Duration(days: 1));
    }
    return count;
  }

  int _resolveTotalCount(Client client, Period latestPeriod) {
    if (client.packageType == PackageType.daily) {
      return client.sessionPackage ?? 0;
    }

    final clientId = client.id;
    if (clientId == null) return 0;
    final weekdays = _scheduledWeekdaysByClientId[clientId] ?? const <int>{};
    final start = DateTime.tryParse(latestPeriod.startDate);
    final end = DateTime.tryParse(latestPeriod.endDate);
    if (start == null || end == null) return 0;

    return _countLessonsInRange(
      startDate: start,
      endDate: end,
      weekdays: weekdays,
    );
  }

  List<Client> get _filteredClients =>
      _clients.where((c) => c.isActive == _showActive).toList();

  Future<void> _toggleClientActive(Client client) async {
    final newActive = !client.isActive;
    await _db.toggleClientActive(client.id ?? 0, newActive);
    await _loadClients();
    if (!mounted) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newActive ? l.athleteSetActive : l.athleteSetPassive),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _deleteClient(Client client) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[400], size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(l.confirmDeleteTitle)),
          ],
        ),
        content: Text(l.confirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteClient(client.id ?? 0);
      _loadClients();
    }
  }

  void _goToAddClient() async {
    // Premium kontrolü: ücretsiz planda max 3 sporcu
    final clientCount = _clients.length;
    if (!PremiumService().canAddClient(clientCount)) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.maxClientsReached(PremiumService.freeMaxClients)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'Premium',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PremiumPage()));
            },
          ),
        ),
      );
      return;
    }
    final createdClient = await Navigator.of(context).push<Client>(
      MaterialPageRoute(
        builder: (_) => AddClientPage(currentUser: widget.currentUser),
      ),
    );

    if (!mounted) return;
    if (createdClient != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ClientDetailPage(client: createdClient),
        ),
      );
    }

    if (!mounted) return;
    _loadClients();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final filtered = _filteredClients;
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
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l.myAthletes,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.logout,
                          color: Colors.red[400],
                          size: 22,
                        ),
                        tooltip: l.logout,
                        onPressed: _logout,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // ── Aktif / Pasif Switch ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _showActive
                        ? const Color(0xFF00BCD4).withValues(alpha: 0.08)
                        : Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _showActive
                          ? const Color(0xFF00BCD4).withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _showActive ? Icons.person : Icons.person_off,
                        color: _showActive
                            ? const Color(0xFF00897B)
                            : Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _showActive ? l.activeAthletes : l.passiveAthletes,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _showActive
                                ? const Color(0xFF00897B)
                                : Colors.orange[700],
                          ),
                        ),
                      ),
                      Switch(
                        value: _showActive,
                        onChanged: (val) {
                          setState(() {
                            _showActive = val;
                          });
                        },
                        activeThumbColor: const Color(0xFF00897B),
                        inactiveThumbColor: Colors.orange[700],
                        inactiveTrackColor: Colors.orange.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // ── İçerik ──
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showActive
                                  ? Icons.person_add_alt_1
                                  : Icons.person_off,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _showActive
                                  ? l.noAthletesYet
                                  : l.noPassiveAthletes,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final client = filtered[index];
                          final bgColor = _showActive
                              ? const Color(0xFFE3F2FD)
                              : const Color(0xFFFFF3E0);
                          final accentColor = _showActive
                              ? const Color(0xFF1E88E5)
                              : Colors.orange[700]!;

                          // Period info
                          final cid = client.id ?? 0;
                          final periodData = _clientPeriodInfo[cid];
                          final latestPeriod = periodData?.$1;
                          final completedCount = periodData?.$2 ?? 0;
                          final totalCount = latestPeriod == null
                              ? 0
                              : _resolveTotalCount(client, latestPeriod);
                          final isCompleted =
                              totalCount > 0 && completedCount >= totalCount;
                          final hasUnpaidLatestPeriod =
                              latestPeriod != null && !latestPeriod.isPaid;
                          final hasOneLessonLeft =
                              latestPeriod != null &&
                              totalCount > 0 &&
                              (totalCount - completedCount) == 1;

                          return Dismissible(
                            key: Key(client.id.toString()),
                            direction: DismissDirection.horizontal,
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.endToStart) {
                                await _toggleClientActive(client);
                                return false;
                              } else {
                                await _deleteClient(client);
                                return false;
                              }
                            },
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            secondaryBackground: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: _showActive
                                    ? Colors.orange[400]
                                    : const Color(0xFF00897B),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: Icon(
                                _showActive ? Icons.person_off : Icons.person,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ClientDetailPage(client: client),
                                      ),
                                    );
                                    _loadClients();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: accentColor.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      child: Row(
                                        children: [
                                          // Avatar (küçük)
                                          Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: accentColor.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Center(
                                              child: Text(
                                                client.fullName.isNotEmpty
                                                    ? client.fullName
                                                          .substring(0, 1)
                                                          .toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                  color: accentColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // İsim + Periyot bilgisi
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _nameWithProgramMarkers(
                                                    client.fullName,
                                                    showUnpaidMarker:
                                                        hasUnpaidLatestPeriod,
                                                    showOneLessonLeftMarker:
                                                        hasOneLessonLeft,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (latestPeriod != null) ...[
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .calendar_today_rounded,
                                                        size: 11,
                                                        color: Colors.grey[500],
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Expanded(
                                                        child: Text(
                                                          _formatPeriodDates(
                                                            latestPeriod,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          // Ders sayısı badge
                                          if (latestPeriod != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isCompleted
                                                    ? const Color(
                                                        0xFFC9A227,
                                                      ).withValues(alpha: 0.15)
                                                    : const Color(
                                                        0xFF4CAF50,
                                                      ).withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isCompleted
                                                      ? const Color(
                                                          0xFFC9A227,
                                                        ).withValues(alpha: 0.4)
                                                      : const Color(
                                                          0xFF4CAF50,
                                                        ).withValues(
                                                          alpha: 0.4,
                                                        ),
                                                ),
                                              ),
                                              child: Text(
                                                '$completedCount/$totalCount',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isCompleted
                                                      ? const Color(0xFFC9A227)
                                                      : const Color(0xFF388E3C),
                                                ),
                                              ),
                                            )
                                          else
                                            Icon(
                                              Icons.arrow_forward_ios,
                                              size: 14,
                                              color: accentColor.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _showActive
          ? FloatingActionButton.extended(
              onPressed: _goToAddClient,
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add),
              label: Text(l.addAthlete),
            )
          : null,
    );
  }

  String _formatPeriodDates(Period period) {
    try {
      final start = DateTime.parse(period.startDate);
      final end = DateTime.parse(period.postponedEndDate ?? period.endDate);
      String fmt(DateTime d) =>
          '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
      return '${fmt(start)} - ${fmt(end)}';
    } catch (_) {
      return '';
    }
  }

  String _nameWithProgramMarkers(
    String name, {
    required bool showUnpaidMarker,
    required bool showOneLessonLeftMarker,
  }) {
    final markers = <String>[];
    if (showUnpaidMarker) markers.add('!');
    if (showOneLessonLeftMarker) markers.add('*');
    if (markers.isEmpty) return name;
    return '$name ${markers.join(' ')}';
  }

  Future<void> _logout() async {
    await SessionTimeoutService.instance.logoutNow();
  }
}
