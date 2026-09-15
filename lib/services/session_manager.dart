import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the app currently stands, resolved once at startup by
/// [SessionManager.restore] and used by the splash/auth redirect to
/// decide where to send the user.
enum AuthState {
  /// Not yet checked - splash should keep waiting.
  unknown,

  /// No stored session - go to the Auth / sign-in screen.
  loggedOut,

  /// Logged in, but the phone number still needs OTP verification - go
  /// to [OtpVerificationScreen].
  pendingVerification,

  /// Logged in and verified - go straight into the app.
  authenticated,
}

/// Persists auth/session data across app restarts and exposes it as a
/// [ChangeNotifier] so the splash screen (or a top-level listener) can
/// auto-navigate based on [state].
///
/// - Non-sensitive flags (logged-in flag, verified flag, user id) live in
///   [SharedPreferences] - fast, unencrypted, fine for booleans/ids.
/// - The actual auth token lives in [FlutterSecureStorage] - encrypted
///   keystore/keychain storage, never plain prefs.
///
/// Usage:
/// ```dart
/// final session = SessionManager();
/// await session.restore(); // call once at app startup
///
/// // after a successful login:
/// await session.saveSession(userId: user.id, token: idToken, isPhoneVerified: false);
///
/// // after OTP succeeds:
/// await session.markPhoneVerified();
///
/// // on logout:
/// await session.clear();
///
/// // anywhere:
/// if (session.state == AuthState.authenticated) { ... }
/// ```
class SessionManager extends ChangeNotifier {
  SessionManager({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _kIsLoggedIn = 'session_is_logged_in';
  static const _kIsPhoneVerified = 'session_is_phone_verified';
  static const _kUserId = 'session_user_id';
  static const _kAuthTokenSecureKey = 'session_auth_token';

  final FlutterSecureStorage _secureStorage;
  SharedPreferences? _prefs;

  AuthState _state = AuthState.unknown;
  AuthState get state => _state;

  String? _userId;
  String? get userId => _userId;

  String? _token;
  String? get token => _token;

  bool get isLoggedIn => _state != AuthState.unknown && _state != AuthState.loggedOut;
  bool get isPhoneVerified => _state == AuthState.authenticated;

  Future<SharedPreferences> get _prefsInstance async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Reads whatever was persisted last session and resolves [state].
  /// Call this once, early, e.g. from the splash screen before deciding
  /// where to navigate.
  Future<AuthState> restore() async {
    final prefs = await _prefsInstance;

    final loggedIn = prefs.getBool(_kIsLoggedIn) ?? false;
    final verified = prefs.getBool(_kIsPhoneVerified) ?? false;
    _userId = prefs.getString(_kUserId);
    _token = await _secureStorage.read(key: _kAuthTokenSecureKey);

    if (!loggedIn || _userId == null) {
      _state = AuthState.loggedOut;
    } else if (!verified) {
      _state = AuthState.pendingVerification;
    } else {
      _state = AuthState.authenticated;
    }

    notifyListeners();
    return _state;
  }

  /// Persists a new session right after sign-in/sign-up. Pass
  /// [isPhoneVerified] `true` when the account doesn't need a separate
  /// OTP step (e.g. email/social sign-in).
  Future<void> saveSession({
    required String userId,
    String? token,
    bool isPhoneVerified = false,
  }) async {
    final prefs = await _prefsInstance;
    await prefs.setBool(_kIsLoggedIn, true);
    await prefs.setBool(_kIsPhoneVerified, isPhoneVerified);
    await prefs.setString(_kUserId, userId);

    if (token != null) {
      await _secureStorage.write(key: _kAuthTokenSecureKey, value: token);
    }

    _userId = userId;
    _token = token ?? _token;
    _state = isPhoneVerified ? AuthState.authenticated : AuthState.pendingVerification;
    notifyListeners();
  }

  /// Call after the OTP screen successfully verifies the phone number.
  Future<void> markPhoneVerified() async {
    final prefs = await _prefsInstance;
    await prefs.setBool(_kIsPhoneVerified, true);
    _state = AuthState.authenticated;
    notifyListeners();
  }

  /// Updates the stored token (e.g. after a silent refresh) without
  /// touching the rest of the session.
  Future<void> updateToken(String token) async {
    await _secureStorage.write(key: _kAuthTokenSecureKey, value: token);
    _token = token;
  }

  /// Clears everything - call on sign-out.
  Future<void> clear() async {
    final prefs = await _prefsInstance;
    await prefs.remove(_kIsLoggedIn);
    await prefs.remove(_kIsPhoneVerified);
    await prefs.remove(_kUserId);
    await _secureStorage.delete(key: _kAuthTokenSecureKey);

    _userId = null;
    _token = null;
    _state = AuthState.loggedOut;
    notifyListeners();
  }
}
