import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services.dart';
import 'session_controller.dart';
import 'ui/home_shell.dart';
import 'ui/lock_screen.dart';
import 'ui/setup_screen.dart';

/// The whole app: sign-in, first-time setup and (for now) an empty shell.
/// Watches for idle time and Ctrl+L (ADR-0002).
class PosApp extends StatefulWidget {
  const PosApp({
    super.key,
    required this.session,
    required this.services,
    this.idleCheckEvery = const Duration(seconds: 5),
  });

  final SessionController session;
  final AppServices services;
  final Duration idleCheckEvery;

  @override
  State<PosApp> createState() => _PosAppState();
}

class _PosAppState extends State<PosApp> {
  final _navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSession);
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSession);
    super.dispose();
  }

  /// When the counter locks, close any screen opened on top (a half-filled
  /// form must not stay visible behind the lock screen).
  void _onSession() {
    if (widget.session.stage != SessionStage.signedIn) {
      _navigator.currentState?.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return MaterialApp(
      navigatorKey: _navigator,
      title: 'Apparel PoS',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3949AB),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: _IdleGuard(
        session: session,
        checkEvery: widget.idleCheckEvery,
        child: ListenableBuilder(
          listenable: session,
          builder: (context, _) {
            switch (session.stage) {
              case SessionStage.loading:
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              case SessionStage.needsSetup:
                return SetupScreen(session: session, services: widget.services);
              case SessionStage.locked:
                return LockScreen(session: session);
              case SessionStage.signedIn:
                return HomeShell(session: session, services: widget.services);
            }
          },
        ),
      ),
    );
  }
}

/// Locks on Ctrl+L, notes activity on any key or pointer event, and checks the
/// idle time every few seconds.
class _IdleGuard extends StatefulWidget {
  const _IdleGuard({
    required this.session,
    required this.checkEvery,
    required this.child,
  });

  final SessionController session;
  final Duration checkEvery;
  final Widget child;

  @override
  State<_IdleGuard> createState() => _IdleGuardState();
}

class _IdleGuardState extends State<_IdleGuard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _timer = Timer.periodic(
      widget.checkEvery,
      (_) => widget.session.checkIdle(),
    );
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyL &&
          HardwareKeyboard.instance.isControlPressed) {
        widget.session.lock();
      } else {
        widget.session.noteActivity();
      }
    }
    return false; // never swallow the key
  }

  @override
  void dispose() {
    _timer?.cancel();
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => widget.session.noteActivity(),
      onPointerMove: (_) => widget.session.noteActivity(),
      onPointerSignal: (_) => widget.session.noteActivity(),
      child: widget.child,
    );
  }
}
