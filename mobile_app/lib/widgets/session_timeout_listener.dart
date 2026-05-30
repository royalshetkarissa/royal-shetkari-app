import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../localization/app_localizations.dart';
import '../main.dart';

class SessionTimeoutListener extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const SessionTimeoutListener({
    super.key,
    required this.child,
    this.duration = const Duration(minutes: 15), // Default to 15 minutes
  });

  @override
  State<SessionTimeoutListener> createState() => _SessionTimeoutListenerState();
}

class _SessionTimeoutListenerState extends State<SessionTimeoutListener> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  void _startTimer() {
    _cancelTimer();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated) {
      _timer = Timer(widget.duration, _onTimeout);
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _handleUserInteraction() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated) {
      _startTimer();
    } else {
      _cancelTimer();
    }
  }

  Future<void> _onTimeout() async {
    _cancelTimer();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated) {
      // Perform logout operation
      await auth.logout();

      final navContext = RoyalShetkariApp.navigatorKey.currentContext;
      if (navContext != null) {
        // Resolve translated message
        final String message = AppLocalizations.of(navContext)
                ?.translate('err_stream_session_expired') ??
            "Your session has expired. Please login again.";

        // Display localized SnackBar to the user
        ScaffoldMessenger.of(navContext).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Route the user back to the login screen and clear current history
      RoyalShetkariApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Synchronize timer state with authentication state updates
    if (auth.isAuthenticated) {
      if (_timer == null) {
        _startTimer();
      }
    } else {
      _cancelTimer();
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _handleUserInteraction(),
      onPointerSignal: (_) => _handleUserInteraction(),
      child: widget.child,
    );
  }
}
