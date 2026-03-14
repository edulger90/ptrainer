import 'package:flutter/material.dart';
import '../models/user.dart';
import '../main.dart'; // AuthPage'e dönebilmek için
import '../services/premium_service.dart';
import 'client_list_page.dart';
import 'weekly_plan_page.dart';
import 'settings_page.dart';
import 'premium_page.dart';
import '../widgets/app_background.dart';
import '../l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  final User currentUser;
  const HomePage({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Üst Bar: Logo + Çıkış ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00897B), Color(0xFF00BCD4)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF00BCD4,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.appTitle,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00897B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.welcome(currentUser.username),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.teal[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.settings, color: Colors.teal[400]),
                        tooltip: l.settings,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SettingsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.logout, color: Colors.red[400]),
                        tooltip: l.logout,
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const AuthPage()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // ── Menü Kartları ──
                _MenuCard(
                  icon: Icons.people_alt_rounded,
                  title: l.myAthletes,
                  subtitle: l.manageAthletesDesc,
                  gradientColors: const [Color(0xFF00897B), Color(0xFF00BCD4)],
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ClientListPage(currentUser: currentUser),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _MenuCard(
                  icon: Icons.calendar_month_rounded,
                  title: l.weeklyPlan,
                  subtitle: l.weeklyPlanDesc,
                  gradientColors: const [Color(0xFF1E88E5), Color(0xFF42A5F5)],
                  isLocked: !PremiumService().canAccessWeeklyPlan,
                  onTap: () {
                    if (!PremiumService().canAccessWeeklyPlan) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PremiumPage()),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            WeeklyPlanPage(currentUser: currentUser),
                      ),
                    );
                  },
                ),
                // Analiz kartı ileride eklenecek
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final bool isLocked;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: gradientColors[1].withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[0].withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: gradientColors[1].withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isLocked ? Icons.lock : Icons.arrow_forward_ios,
                  size: 16,
                  color: isLocked ? Colors.amber[700] : gradientColors[0],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
