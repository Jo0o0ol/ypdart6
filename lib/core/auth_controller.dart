import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'api_exceptions.dart';
import 'config.dart';
import 'roles.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._prefs);

  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUser = 'auth_cached_user';
  static const _kUiRole = 'auth_ui_role';
  static const _kSessionStarted = 'auth_session_started_ms';
  static const _kLastActivity = 'auth_last_activity_ms';

  final SharedPreferences _prefs;
  Dio? _dio;

  AppUser? _user;
  String? _accessToken;
  String? _refreshToken;
  AppRole? _uiRole;
  DateTime? _sessionStartedAt;
  String? _lastLogoutMessage;
  int? _inactivitySecondsLeft;

  Timer? _warningTimer;
  Timer? _logoutTimer;
  Timer? _warningCountdown;
  Timer? _maxSessionTimer;
  Future<void>? _refreshFuture;
  DateTime? _lastActivityRecordedAt;

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _user != null && _accessToken != null;
  String? get lastLogoutMessage => _lastLogoutMessage;
  int? get inactivitySecondsLeft => _inactivitySecondsLeft;

  AppRole? get serverRole => AppRoleInfo.fromApi(_user?.role);
  AppRole? get uiRole => _uiRole ?? serverRole;

  bool serverHasAtLeast(AppRole role) {
    final actual = serverRole;
    return actual != null && RolePermissions.hasAtLeast(actual, role);
  }

  bool serverIs(AppRole role) => serverRole == role;

  bool uiHasAtLeast(AppRole role) {
    final actual = uiRole;
    return actual != null && RolePermissions.hasAtLeast(actual, role);
  }

  bool uiIs(AppRole role) => uiRole == role;

  void attachDio(Dio dio) {
    _dio = dio;
  }

  Future<void> restore() async {
    _accessToken = _prefs.getString(_kAccess);
    _refreshToken = _prefs.getString(_kRefresh);

    final cachedUser = _prefs.getString(_kUser);
    if (cachedUser != null) {
      try {
        final decoded = jsonDecode(cachedUser);
        if (decoded is Map) {
          _user = AppUser.fromJson(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        _user = null;
      }
    }

    _uiRole = AppRoleInfo.fromApi(_prefs.getString(_kUiRole));

    final startedMs = _prefs.getInt(_kSessionStarted);
    if (startedMs != null) {
      _sessionStartedAt = DateTime.fromMillisecondsSinceEpoch(startedMs);
    }

    final lastActivityMs = _prefs.getInt(_kLastActivity);
    if (_accessToken != null && lastActivityMs != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastActivityMs);
      final elapsed = DateTime.now().difference(last).inSeconds;
      if (elapsed >= inactivityTimeoutSeconds) {
        await _clearLocal(
          'Сессия завершена: более трёх минут не было активности.',
        );
        return;
      }
    }

    if (_accessToken == null || _user == null) {
      await _clearLocal(null);
      return;
    }

    try {
      final response = await guardRead(
        () => _requireDio().get('/auth/me'),
        maxAttempts: 1,
      );
      _user = AppUser.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
      await _saveCachedUser();
      _uiRole ??= AppRoleInfo.fromApi(_user?.role);
      if (_uiRole != null) {
        await _prefs.setString(_kUiRole, _uiRole!.apiName);
      }
    } on UnauthorizedException {
      try {
        await refreshTokens();
      } catch (_) {
        await _clearLocal('Срок действия сессии истёк. Войдите снова.');
        return;
      }
    } on ApiException {
      // При временной недоступности сервера оставляем локально сохранённую
      // сессию. Первый сетевой запрос позже покажет понятную ошибку.
    }

    _sessionStartedAt ??= DateTime.now();
    await _prefs.setInt(
      _kSessionStarted,
      _sessionStartedAt!.millisecondsSinceEpoch,
    );
    await _prefs.setInt(
      _kLastActivity,
      DateTime.now().millisecondsSinceEpoch,
    );
    _restartSessionTimers();
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final response = await guardWrite(
      () => _requireDio().post(
        '/auth/login',
        data: {
          'username': username.trim(),
          'password': password,
        },
      ),
    );

    await _acceptAuthResponse(
      Map<String, dynamic>.from(response.data as Map),
      resetSessionStart: true,
    );
    _lastLogoutMessage = null;
    notifyListeners();
  }

  Future<AppUser> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) async {
    final response = await guardWrite(
      () => _requireDio().post(
        '/auth/register',
        data: {
          'username': username.trim(),
          'password': password,
          'email': email.trim(),
          'fullName': fullName.trim(),
        },
      ),
    );

    return AppUser.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> refreshTokens() async {
    final existing = _refreshFuture;
    if (existing != null) {
      return existing;
    }

    final future = _performRefresh();
    _refreshFuture = future;
    try {
      await future;
    } finally {
      if (identical(_refreshFuture, future)) {
        _refreshFuture = null;
      }
    }
  }

  Future<void> _performRefresh() async {
    final token = _refreshToken;
    if (token == null || token.isEmpty) {
      throw const UnauthorizedException('Нет токена обновления.');
    }

    final response = await guardWrite(
      () => _requireDio().post(
        '/auth/refresh',
        data: {'refreshToken': token},
      ),
    );

    await _acceptAuthResponse(
      Map<String, dynamic>.from(response.data as Map),
      resetSessionStart: false,
    );
  }

  Future<void> logout({String? message}) async {
    final refresh = _refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await guardWrite(
          () => _requireDio().post(
            '/auth/logout',
            data: {'refreshToken': refresh},
          ),
        );
      } catch (_) {
        // Локальный выход не должен зависеть от доступности сервера.
      }
    }

    await _clearLocal(message);
  }

  Future<void> forceLogout(String message) async {
    await _clearLocal(message);
  }

  void clearLogoutMessage() {
    _lastLogoutMessage = null;
  }

  void noteActivity() {
    if (!isAuthenticated) return;

    final now = DateTime.now();
    if (_lastActivityRecordedAt == null ||
        now.difference(_lastActivityRecordedAt!).inSeconds >= 5) {
      _lastActivityRecordedAt = now;
      _prefs.setInt(
        _kLastActivity,
        now.millisecondsSinceEpoch,
      );
    }
    _restartInactivityTimers();
  }

  Future<void> reloadUiRoleFromStorage() async {
    await _prefs.reload();
    _uiRole = AppRoleInfo.fromApi(_prefs.getString(_kUiRole));
    notifyListeners();
  }

  Future<void> resetUiRoleFromServer() async {
    _uiRole = serverRole;
    if (_uiRole != null) {
      await _prefs.setString(_kUiRole, _uiRole!.apiName);
    } else {
      await _prefs.remove(_kUiRole);
    }
    notifyListeners();
  }

  Future<void> _acceptAuthResponse(
    Map<String, dynamic> data, {
    required bool resetSessionStart,
  }) async {
    final rawUser = data['user'];
    if (rawUser is! Map) {
      throw const ServerException('Сервер не вернул данные пользователя.');
    }

    _accessToken = '${data['accessToken'] ?? ''}';
    _refreshToken = '${data['refreshToken'] ?? ''}';
    _user = AppUser.fromJson(Map<String, dynamic>.from(rawUser));

    await _prefs.setString(_kAccess, _accessToken!);
    await _prefs.setString(_kRefresh, _refreshToken!);
    await _saveCachedUser();

    if (resetSessionStart || _sessionStartedAt == null) {
      _sessionStartedAt = DateTime.now();
      await _prefs.setInt(
        _kSessionStarted,
        _sessionStartedAt!.millisecondsSinceEpoch,
      );
    }

    await _prefs.setInt(
      _kLastActivity,
      DateTime.now().millisecondsSinceEpoch,
    );

    // Роль в localStorage используется только для отрисовки интерфейса.
    // Серверные права определяются по подписанному access token.
    if (resetSessionStart || _uiRole == null) {
      _uiRole = AppRoleInfo.fromApi(_user!.role);
      if (_uiRole != null) {
        await _prefs.setString(_kUiRole, _uiRole!.apiName);
      }
    }

    _restartSessionTimers();
    notifyListeners();
  }

  Future<void> _saveCachedUser() async {
    if (_user == null) {
      await _prefs.remove(_kUser);
      return;
    }
    await _prefs.setString(_kUser, jsonEncode(_user!.toJson()));
  }

  Future<void> _clearLocal(String? message) async {
    _cancelTimers();
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _uiRole = null;
    _sessionStartedAt = null;
    _inactivitySecondsLeft = null;
    _lastLogoutMessage = message;

    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kUser);
    await _prefs.remove(_kUiRole);
    await _prefs.remove(_kSessionStarted);
    await _prefs.remove(_kLastActivity);
    notifyListeners();
  }

  void _restartSessionTimers() {
    _restartInactivityTimers();
    _maxSessionTimer?.cancel();

    if (!isAuthenticated || _sessionStartedAt == null) return;

    final maxDuration = Duration(minutes: maxSessionMinutes);
    final elapsed = DateTime.now().difference(_sessionStartedAt!);
    final remaining = maxDuration - elapsed;

    if (remaining <= Duration.zero) {
      Future<void>.microtask(
        () => forceLogout(
          'Сессия завершена: достигнута максимальная длительность.',
        ),
      );
      return;
    }

    _maxSessionTimer = Timer(
      remaining,
      () => forceLogout(
        'Сессия завершена: достигнута максимальная длительность.',
      ),
    );
  }

  void _restartInactivityTimers() {
    final hadWarning = _inactivitySecondsLeft != null;
    _warningTimer?.cancel();
    _logoutTimer?.cancel();
    _warningCountdown?.cancel();
    _inactivitySecondsLeft = null;
    if (hadWarning) notifyListeners();

    if (!isAuthenticated) return;

    final warningStart = inactivityTimeoutSeconds - inactivityWarningSeconds;
    _warningTimer = Timer(
      Duration(seconds: warningStart > 0 ? warningStart : 1),
      () {
        _inactivitySecondsLeft = inactivityWarningSeconds;
        notifyListeners();

        _warningCountdown = Timer.periodic(
          const Duration(seconds: 1),
          (timer) {
            final value = _inactivitySecondsLeft;
            if (value == null || value <= 1) {
              timer.cancel();
              return;
            }
            _inactivitySecondsLeft = value - 1;
            notifyListeners();
          },
        );
      },
    );

    _logoutTimer = Timer(
      const Duration(seconds: inactivityTimeoutSeconds),
      () => forceLogout(
        'Сессия завершена из-за неактивности.',
      ),
    );
  }

  void _cancelTimers() {
    _warningTimer?.cancel();
    _logoutTimer?.cancel();
    _warningCountdown?.cancel();
    _maxSessionTimer?.cancel();
  }

  Dio _requireDio() {
    final dio = _dio;
    if (dio == null) {
      throw StateError('Dio ещё не подключён к AuthController.');
    }
    return dio;
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }
}
