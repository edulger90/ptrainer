import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/auth_page.dart';

class SessionTimeoutService with WidgetsBindingObserver {
  SessionTimeoutService._();

  static final SessionTimeoutService instance = SessionTimeoutService._();

  static const Duration timeoutDuration = Duration(minutes: 5);
  static const String _lastInteractionKey = 'session_last_interaction_ms';
  static const String _sessionActiveKey = 'session_active';

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  SharedPreferences? _prefs;
  Timer? _timer;
  bool _observerAttached = false;
  bool _sessionActive = false;
  bool _isLoggingOut = false;
  DateTime? _lastInteraction;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> startSession() async {
    final prefs = await _getPrefs();
    _sessionActive = true;
    await prefs.setBool(_sessionActiveKey, true);

    if (!_observerAttached) {
      WidgetsBinding.instance.addObserver(this);
      _observerAttached = true;
    }

    final now = DateTime.now();
    _lastInteraction = now;
    await prefs.setInt(_lastInteractionKey, now.millisecondsSinceEpoch);
    _scheduleTimeoutCheck(now);
  }

  Future<void> endSession() async {
    _timer?.cancel();
    _timer = null;

    if (_observerAttached) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAttached = false;
    }

    _sessionActive = false;
    _lastInteraction = null;

    final prefs = await _getPrefs();
    await prefs.setBool(_sessionActiveKey, false);
    await prefs.remove(_lastInteractionKey);
  }

  void registerInteraction() {
    if (!_sessionActive) return;

    final now = DateTime.now();
    _lastInteraction = now;
    _scheduleTimeoutCheck(now);
    unawaited(_persistInteraction(now));
  }

  Future<void> ensureSessionIsValid() async {
    if (!_sessionActive) return;

    final last = await _resolveLastInteraction();
    if (last == null) {
      await _triggerTimeoutLogout();
      return;
    }

    final elapsed = DateTime.now().difference(last);
    if (elapsed >= timeoutDuration) {
      await _triggerTimeoutLogout();
      return;
    }

    _lastInteraction = last;
    _scheduleTimeoutCheck(last);
  }

  Future<void> logoutNow() async {
    await _triggerTimeoutLogout();
  }

  Future<void> _persistInteraction(DateTime timestamp) async {
    final prefs = await _getPrefs();
    await prefs.setInt(_lastInteractionKey, timestamp.millisecondsSinceEpoch);
  }

  Future<DateTime?> _resolveLastInteraction() async {
    if (_lastInteraction != null) {
      return _lastInteraction;
    }
    final prefs = await _getPrefs();
    final millis = prefs.getInt(_lastInteractionKey);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  void _scheduleTimeoutCheck(DateTime reference) {
    _timer?.cancel();
    final elapsed = DateTime.now().difference(reference);
    final remaining = timeoutDuration - elapsed;

    if (remaining <= Duration.zero) {
      unawaited(_triggerTimeoutLogout());
      return;
    }

    _timer = Timer(remaining, () {
      unawaited(_triggerTimeoutLogout());
    });
  }

  Future<void> _triggerTimeoutLogout() async {
    if (_isLoggingOut || !_sessionActive) return;
    _isLoggingOut = true;

    await endSession();

    final navigator = navigatorKey.currentState;
    if (navigator != null && navigator.mounted) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (route) => false,
      );
    }

    _isLoggingOut = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_sessionActive) return;

    if (state == AppLifecycleState.resumed) {
      unawaited(ensureSessionIsValid());
    }
  }
}
