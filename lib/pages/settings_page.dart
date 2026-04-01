import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_environment.dart';
import '../l10n/app_localizations.dart';
import '../services/error_logger.dart';
import '../services/premium_service.dart';
import 'error_log_page.dart';
import 'premium_page.dart';
import 'query_plan_debug_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isPremium = PremiumService().isPremium;

  Future<void> _setPremium(bool value) async {
    if (value) {
      await PremiumService().activatePremium();
    } else {
      await PremiumService().deactivatePremium();
    }
    setState(() {
      _isPremium = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDevEnvironment = AppEnvironmentConfig().isDev;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.settings),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Uygulama bilgileri kartı
          _buildSectionHeader(l.appInfo, Icons.info_outline),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 48,
                    color: Color(0xFF00BCD4),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'P-Trainer',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l.versionLabel}: ${AppVersionInfo.fullVersion}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _infoRow(l.buildNumber, AppVersionInfo.buildNumber),
                  _infoRow(l.appVersionLabel, AppVersionInfo.version),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          // --- Premium Test Butonu (Sadece debug modda) ---
          if (isDevEnvironment) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: Icon(Icons.workspace_premium, color: Colors.blue),
                title: const Text('Premium Dev Toggle'),
                subtitle: Text(_isPremium ? 'Premium aktif' : 'Premium pasif'),
                trailing: Switch(
                  value: _isPremium,
                  onChanged: (val) => _setPremium(val),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Premium plan kartı
          _buildSectionHeader(l.premiumPlan, Icons.workspace_premium),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PremiumService().isPremium
                      ? Colors.amber[50]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  PremiumService().isPremium
                      ? Icons.workspace_premium
                      : Icons.lock_outline,
                  color: PremiumService().isPremium
                      ? Colors.amber[700]
                      : Colors.grey[600],
                ),
              ),
              title: Text(
                PremiumService().isPremium ? l.premiumLabel : l.premiumFree,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: PremiumService().isPremium
                      ? Colors.amber[800]
                      : Colors.grey[700],
                ),
              ),
              subtitle: Text(
                PremiumService().isPremium
                    ? l.premiumActiveDesc
                    : l.premiumDesc,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: PremiumService().isPremium
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l.premiumActive,
                        style: TextStyle(
                          color: Colors.amber[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumPage()),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Geliştirici araçları
          _buildSectionHeader(l.developerTools, Icons.build_outlined),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.bug_report, color: Colors.red[400]),
                  ),
                  title: Text(l.errorLogs),
                  subtitle: Text(l.errorLogsDesc),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ErrorLogPage()),
                    );
                  },
                ),
                if (kDebugMode) ...[
                  const Divider(height: 1, indent: 72),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.query_stats,
                        color: Colors.blueGrey[700],
                      ),
                    ),
                    title: const Text('Query Plan Debug'),
                    subtitle: const Text(
                      'Check EXPLAIN QUERY PLAN output for indexed queries',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QueryPlanDebugPage(),
                        ),
                      );
                    },
                  ),
                ],
                const Divider(height: 1, indent: 72),
                FutureBuilder<int>(
                  future: ErrorLogger().getLogCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.analytics_outlined,
                          color: Colors.orange[400],
                        ),
                      ),
                      title: Text(l.errorStats),
                      subtitle: Text('$count ${l.totalEntries}'),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Versiyon geçmişi
          _buildSectionHeader(l.versionHistory, Icons.history),
          const SizedBox(height: 8),
          ...AppVersionInfo.changelog.map((entry) {
            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF00BCD4,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'v${entry['version']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00897B),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          entry['date'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry['changes'] ?? '',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  static Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF00897B)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00897B),
          ),
        ),
      ],
    );
  }

  static Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
