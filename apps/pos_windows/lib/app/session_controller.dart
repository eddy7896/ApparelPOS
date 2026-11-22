// Who is signed in and whether the counter is locked. The rules (idle time,
// PIN and password limits, lockout) live in core_domain and AuthService; this
// only keeps the current state for the screens. ADR-0002.
import 'package:core_domain/core_domain.dart';
import 'package:flutter/foundation.dart';

import '../data/auth_service.dart';

enum SessionStage { loading, needsSetup, locked, signedIn }

enum SetupResult { done, weakPassword, mismatch, blankName, notAllowed }

/// Sign-in details for the practice users made by development builds. They are
/// not secrets: they exist only in debug builds, only when the database is
/// empty, and never in a release build (ADR-0016).
const String practiceOwnerPassword = 'practice-owner-pass';
const String practiceCashierPin = '246810';

class SessionController extends ChangeNotifier {
  SessionController({
    required this.auth,
    DateTime Function()? now,
    IdleLockPolicy? idle,
  }) : _now = now ?? (() => DateTime.now().toUtc()),
       _idle = idle ?? IdleLockPolicy();

  final AuthService auth;
  final DateTime Function() _now;
  final IdleLockPolicy _idle;

  SessionStage _stage = SessionStage.loading;
  SignedIn? _user;
  List<SignInChoice> _choices = const [];
  String? _pausedName;
  DateTime _lastActivity = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  SessionStage get stage => _stage;

  /// The current time on this counter's clock (UTC).
  DateTime get now => _now();

  /// The signed-in user, or null when locked.
  SignedIn? get user => _user;

  /// The name of the cashier who paused for a break, shown on the lock screen
  /// until someone signs in; null when the counter is simply locked.
  String? get pausedName => _pausedName;

  /// Who appears on the lock screen.
  List<SignInChoice> get choices => _choices;

  /// Loads the sign-in list and shows setup (no users yet) or the lock screen.
  Future<void> start() async {
    _choices = await auth.signInChoices();
    _stage = _choices.isEmpty ? SessionStage.needsSetup : SessionStage.locked;
    notifyListeners();
  }

  /// First launch only: creates the owner and signs them in.
  Future<SetupResult> createFirstOwner({
    required String name,
    required String password,
    required String confirm,
  }) async {
    if ((await auth.signInChoices()).isNotEmpty) {
      return SetupResult.notAllowed;
    }
    if (name.trim().isEmpty) {
      return SetupResult.blankName;
    }
    if (checkPassword(password) != null) {
      return SetupResult.weakPassword;
    }
    if (password != confirm) {
      return SetupResult.mismatch;
    }
    final id = await auth.createUser(
      name: name,
      role: Role.owner,
      secret: password,
    );
    final result = await signIn(id, password);
    return result is SignedIn ? SetupResult.done : SetupResult.notAllowed;
  }

  /// Development builds only (never in release): when there are no users, makes
  /// a practice owner and a practice cashier so screens can be tried. Returns
  /// false if it did nothing.
  Future<bool> createPracticeUsers() async {
    if (!kDebugMode || (await auth.signInChoices()).isNotEmpty) {
      return false;
    }
    await auth.createUser(
      name: 'Practice Owner',
      role: Role.owner,
      secret: practiceOwnerPassword,
    );
    await auth.createUser(
      name: 'Practice Cashier',
      role: Role.cashier,
      secret: practiceCashierPin,
    );
    await start();
    return true;
  }

  /// Checks the PIN or password. On success the counter opens for that user.
  Future<SignInResult> signIn(String userId, String secret) async {
    final result = await auth.signIn(userId: userId, secret: secret);
    if (result is SignedIn) {
      _user = result;
      _pausedName = null;
      _stage = SessionStage.signedIn;
      _lastActivity = _now();
      notifyListeners();
    }
    return result;
  }

  /// Signs out and shows the lock screen.
  void lock() {
    if (_stage != SessionStage.signedIn) {
      return;
    }
    _user = null;
    _stage = SessionStage.locked;
    notifyListeners();
  }

  /// The Pause button: locks the counter and remembers whose break it is. The
  /// break itself is recorded by the shift repository before this is called.
  void lockForBreak(String name) {
    if (_stage != SessionStage.signedIn) {
      return;
    }
    lock();
    _pausedName = name;
    notifyListeners();
  }

  /// Call on any key press or pointer event while signed in.
  void noteActivity() {
    if (_stage == SessionStage.signedIn) {
      _lastActivity = _now();
    }
  }

  /// Locks if the counter has been idle too long. Returns true if it locked.
  bool checkIdle() {
    if (_stage != SessionStage.signedIn) {
      return false;
    }
    if (_idle.shouldLock(lastActivity: _lastActivity, now: _now())) {
      lock();
      return true;
    }
    return false;
  }
}
