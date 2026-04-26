import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_environment.dart';
import '../l10n/app_localizations.dart';
import '../services/app_language_service.dart';
import '../services/database.dart';
import '../services/error_logger.dart';
import '../services/notification_service.dart';
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
  final _notificationService = NotificationService.instance;
  bool _isPremium = PremiumService().isPremium;
  bool _isDeletingAccount = false;
  NotificationPreferences _notificationPreferences =
      const NotificationPreferences.defaults();
  bool _isLoadingNotificationPreferences = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    await _notificationService.initialize();
    final preferences = await _notificationService.loadPreferences();
    if (!mounted) return;
    setState(() {
      _notificationPreferences = preferences;
      _isLoadingNotificationPreferences = false;
    });
  }

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

  String _notificationSettingsSubtitle(AppLocalizations l) {
    if (_isLoadingNotificationPreferences) {
      return l.notificationSettingsLoading;
    }

    final beforeProgram = _notificationPreferences.sessionReminderEnabled;
    final morningPlan = _notificationPreferences.morningPlanEnabled;

    if (!beforeProgram && !morningPlan) {
      return l.notificationSettingsDisabled;
    }

    final beforeProgramLabel = beforeProgram
        ? l.notificationBeforeProgramSummary(
            _notificationPreferences.reminderMinutesBefore,
          )
        : l.notificationBeforeProgramOff;
    final morningLabel = morningPlan
        ? l.notificationMorningPlanSummary(
            _notificationPreferences.morningHour,
            _notificationPreferences.morningMinute,
          )
        : l.notificationMorningPlanOff;

    return '$beforeProgramLabel • $morningLabel';
  }

  Future<void> _showNotificationSettings() async {
    final l = AppLocalizations.of(context);
    final localizations = MaterialLocalizations.of(context);

    var sessionReminderEnabled =
        _notificationPreferences.sessionReminderEnabled;
    var reminderMinutes = _notificationPreferences.reminderMinutesBefore;
    var morningPlanEnabled = _notificationPreferences.morningPlanEnabled;
    var morningHour = _notificationPreferences.morningHour;
    var morningMinute = _notificationPreferences.morningMinute;

    final updatedSettings = await showModalBottomSheet<NotificationPreferences>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final morningTimeText = localizations.formatTimeOfDay(
              TimeOfDay(hour: morningHour, minute: morningMinute),
              alwaysUse24HourFormat: true,
            );

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.notificationSettings,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.notificationSettingsDesc,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: sessionReminderEnabled,
                      onChanged: (value) {
                        setSheetState(() {
                          sessionReminderEnabled = value;
                        });
                      },
                      title: Text(l.notificationBeforeProgram),
                      subtitle: Text(l.notificationBeforeProgramDesc),
                    ),
                    const SizedBox(height: 8),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: l.notificationBeforeProgramMinutes,
                        border: const OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: reminderMinutes,
                          isExpanded: true,
                          items: const [5, 10, 15, 30, 45, 60, 90, 120]
                              .map(
                                (minutes) => DropdownMenuItem<int>(
                                  value: minutes,
                                  child: Text(
                                    l.notificationMinuteValue(minutes),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: sessionReminderEnabled
                              ? (value) {
                                  if (value == null) return;
                                  setSheetState(() {
                                    reminderMinutes = value;
                                  });
                                }
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: morningPlanEnabled,
                      onChanged: (value) {
                        setSheetState(() {
                          morningPlanEnabled = value;
                        });
                      },
                      title: Text(l.notificationMorningPlan),
                      subtitle: Text(l.notificationMorningPlanDesc),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        '${l.notificationMorningTime}: $morningTimeText',
                      ),
                      onPressed: morningPlanEnabled
                          ? () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: morningHour,
                                  minute: morningMinute,
                                ),
                              );
                              if (picked == null) return;
                              setSheetState(() {
                                morningHour = picked.hour;
                                morningMinute = picked.minute;
                              });
                            }
                          : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: Text(l.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(sheetContext).pop(
                                NotificationPreferences(
                                  sessionReminderEnabled:
                                      sessionReminderEnabled,
                                  reminderMinutesBefore: reminderMinutes,
                                  morningPlanEnabled: morningPlanEnabled,
                                  morningHour: morningHour,
                                  morningMinute: morningMinute,
                                ),
                              );
                            },
                            child: Text(l.save),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (updatedSettings == null) return;

    await _notificationService.updatePreferences(updatedSettings);
    if (!mounted) return;
    setState(() {
      _notificationPreferences = updatedSettings;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.notificationSettingsSaved)));
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
      await _notificationService.clearAllSettingsAndNotifications();
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
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.translate,
                    color: Color(0xFF00897B),
                  ),
                  title: Text(l.appLanguage),
                  subtitle: Text(_selectedLanguageLabel(l)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showLanguagePicker,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(
            l.notificationSettings,
            Icons.notifications_active_outlined,
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.notifications_active_outlined,
                color: Color(0xFF00897B),
              ),
              title: Text(l.notificationSettings),
              subtitle: Text(_notificationSettingsSubtitle(l)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showNotificationSettings,
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
              leading: Icon(
                PremiumService().isPremium
                    ? Icons.workspace_premium
                    : Icons.lock_outline,
                color: PremiumService().isPremium
                    ? Colors.amber[700]
                    : Colors.grey[600],
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
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumPage()),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Legal', Icons.gavel_outlined),
          const SizedBox(height: 8),
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
          Card(
            color: const Color(0xFFFFF7F6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFF2B8B5)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFC62828),
                  ),
                  title: Text(
                    l.deleteAccount,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB71C1C),
                    ),
                  ),
                  subtitle: Text(
                    l.deleteAccountDesc,
                    style: const TextStyle(
                      color: Color(0xFF7F1D1D),
                      fontSize: 13,
                    ),
                  ),
                  trailing: _isDeletingAccount
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.chevron_right,
                          color: Color(0xFFC62828),
                        ),
                  onTap: _isDeletingAccount ? null : _deleteAccount,
                ),
              ],
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
                  leading: Icon(Icons.bug_report, color: Colors.red[400]),
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
                    leading: Icon(
                      Icons.query_stats,
                      color: Colors.blueGrey[700],
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
                      leading: Icon(
                        Icons.analytics_outlined,
                        color: Colors.orange[400],
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
