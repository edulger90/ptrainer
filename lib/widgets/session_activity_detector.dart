import 'package:flutter/material.dart';

import '../services/session_timeout_service.dart';

class SessionActivityDetector extends StatelessWidget {
  const SessionActivityDetector({super.key, required this.child});

  final Widget child;

  void _registerActivity(PointerEvent _) {
    SessionTimeoutService.instance.registerInteraction();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _registerActivity,
      onPointerUp: _registerActivity,
      onPointerHover: _registerActivity,
      onPointerSignal: _registerActivity,
      onPointerPanZoomStart: _registerActivity,
      child: child,
    );
  }
}
