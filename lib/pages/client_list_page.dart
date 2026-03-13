import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/user.dart';
import '../services/database.dart';
import '../services/error_logger.dart';
import 'add_client_page.dart';
import 'client_detail_page.dart';
import '../main.dart';
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
  List<Client> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      final clients = await _db.getClientsByUser(widget.currentUser.id ?? 0);
      if (!mounted) return;
      setState(() {
        _clients = clients;
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
      });
    }
  }

  void _goToAddClient() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddClientPage(currentUser: widget.currentUser),
      ),
    );
    if (result == true) {
      _loadClients();
    }
  }

  Future<void> _deleteClient(Client client) async {
    await _db.deleteClient(client.id ?? 0);
    _loadClients();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                        l.myAthletes,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
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
              const SizedBox(height: 16),
              // ── İçerik ──
              Expanded(
                child: _clients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_add_alt_1,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l.noAthletesYet,
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
                        itemCount: _clients.length,
                        itemBuilder: (context, index) {
                          final client = _clients[index];
                          // Tüm kartlar aynı açık mavi renk
                          const bgColor = Color(0xFFE3F2FD);
                          const accentColor = Color(0xFF1E88E5);

                          return Dismissible(
                            key: Key(client.id.toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red[400],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            onDismissed: (_) {
                              _deleteClient(client);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ClientDetailPage(client: client),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: accentColor.withValues(
                                          alpha: 0.25,
                                        ),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // Avatar
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: accentColor.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Center(
                                              child: Text(
                                                client.fullName.isNotEmpty
                                                    ? client.fullName
                                                          .substring(0, 1)
                                                          .toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: accentColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          // İsim + Paket
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  client.fullName,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.fitness_center,
                                                      size: 14,
                                                      color: Colors.grey[500],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      l.packageLabel(
                                                        client.sessionPackage,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Ok
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: accentColor.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.arrow_forward_ios,
                                              size: 16,
                                              color: accentColor,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToAddClient,
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: Text(l.addAthlete),
      ),
    );
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (route) => false,
    );
  }
}
