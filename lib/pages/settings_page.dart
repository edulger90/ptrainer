import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_environment.dart';
import '../l10n/app_localizations.dart';
import '../services/app_language_service.dart';
import '../services/database.dart';
import '../services/error_logger.dart';
import '../services/premium_service.dart';
import '../services/session_timeout_service.dart';
import 'auth_page.dart';
import 'error_log_page.dart';
import 'premium_page.dart';
import 'query_plan_debug_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _db = AppDatabase();
  final _premiumService = PremiumService();
  final _appLanguageService = AppLanguageService();
  bool _isPremium = PremiumService().isPremium;
  bool _isDeletingAccount = false;

  String _languageNativeLabel(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return 'Turkce';
      case 'en':
        return 'English';
      case 'es':
        return 'Espanol';
      case 'nl':
        return 'Nederlands';
      default:
        return languageCode;
    }
  }

  String _selectedLanguageLabel(AppLocalizations l) {
    final selectedLocale = _appLanguageService.selectedLocale;
    if (selectedLocale == null) {
      return l.systemDefaultLanguage;
    }

    return _languageNativeLabel(selectedLocale.languageCode);
  }

  Future<void> _showLanguagePicker() async {
    final selectedLocale = await showModalBottomSheet<Locale?>(
      context: context,
      builder: (sheetContext) {
        final l = AppLocalizations.of(sheetContext);
        final currentSelected = _appLanguageService.selectedLocale;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  l.selectAppLanguage,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(l.systemDefaultLanguage),
                trailing: currentSelected == null
                    ? const Icon(Icons.check, color: Color(0xFF00897B))
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(null),
              ),
              const Divider(height: 1),
              ...AppLocalizations.supportedLocales.map((locale) {
                final isSelected = currentSelected == locale;
                return ListTile(
                  title: Text(_languageNativeLabel(locale.languageCode)),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF00897B))
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(locale),
                );
              }),
            ],
          ),
        );
      },
    );

    final shouldUpdate = selectedLocale != _appLanguageService.selectedLocale;

    if (!shouldUpdate) return;

    await _appLanguageService.setSelectedLocale(selectedLocale);
    if (mounted) {
      setState(() {});
    }
  }

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

  Future<void> _deleteAccount() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.deleteAccountConfirmTitle),
        content: Text(l.deleteAccountConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.deleteAccount),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeletingAccount = true;
    });

    try {
      await _premiumService.clearLocalState();
      await _db.deleteAllData();
      await SessionTimeoutService.instance.endSession();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.deleteAccountError)));
      setState(() {
        _isDeletingAccount = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDevEnvironment = AppEnvironmentConfig().isDev;
    final isIosDevice = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

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
                  _infoRow(l.copyrightLabel, AppVersionInfo.copyrightNotice),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(l.languageSettings, Icons.language),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: const Icon(Icons.translate, color: Color(0xFF00897B)),
              title: Text(l.appLanguage),
              subtitle: Text(_selectedLanguageLabel(l)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showLanguagePicker,
            ),
          ),
          const SizedBox(height: 24),

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

          // --- Legal Links ---
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip,
                    color: Color(0xFF00897B),
                  ),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final url = Uri.parse(
                      'https://edulger90.github.io/ptrainer/privacy-policy.html',
                    );
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                ),
                if (isIosDevice) ...[
                  const Divider(height: 1, indent: 72),
                  ListTile(
                    leading: const Icon(
                      Icons.description,
                      color: Color(0xFF00897B),
                    ),
                    title: const Text('Terms of Use'),
                    subtitle: const Text('Apple Standard EULA'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final url = Uri.parse(
                        'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
                      );
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                ],
              ],
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

          _buildSectionHeader(l.dangerZone, Icons.warning_amber_rounded),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF2B8B5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE3E0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.warning_rounded,
                          color: Color(0xFFC62828),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l.dangerZone,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB71C1C),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l.dangerZoneDesc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF7F1D1D),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _isDeletingAccount ? null : _deleteAccount,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFF2B8B5)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.delete_forever,
                                color: Color(0xFFC62828),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.deleteAccount,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB71C1C),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l.deleteAccountDesc,
                                    style: const TextStyle(
                                      color: Color(0xFF7F1D1D),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _isDeletingAccount
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFFC62828),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
