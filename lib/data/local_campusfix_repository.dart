import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/report_model.dart';
import '../models/report_note_model.dart';
import 'seed_data.dart';

class CampusFixSavedSession {
  const CampusFixSavedSession({
    required this.user,
    required this.usesApi,
    this.token,
  });

  final AppUser user;
  final bool usesApi;
  final String? token;
}

class LocalCampusFixRepository {
  LocalCampusFixRepository({SharedPreferencesWithCache? preferences})
      : _preferences = preferences,
        _users = List<AppUser>.from(SeedData.users),
        _reports = SeedData.reports() {
    _addDemoPasswords();
    _restore();
    _ensureSeedUsers();
    _addDemoPasswords();
    _persist();
  }

  static const _usersStorageKey = 'campusfix.users.v1';
  static const _reportsStorageKey = 'campusfix.reports.v1';
  static const _passwordsStorageKey = 'campusfix.passwords.v1';
  static const _sessionStorageKey = 'campusfix.session.v1';

  static Future<LocalCampusFixRepository> persistent() async {
    final preferences = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {
          _usersStorageKey,
          _reportsStorageKey,
          _passwordsStorageKey,
          _sessionStorageKey,
        },
      ),
    );

    return LocalCampusFixRepository(preferences: preferences);
  }

  final SharedPreferencesWithCache? _preferences;
  final List<AppUser> _users;
  final List<ReportModel> _reports;
  final Map<String, String> _passwords = {};

  List<AppUser> getUsers() {
    return List<AppUser>.unmodifiable(_users);
  }

  List<ReportModel> getReports() {
    return List<ReportModel>.unmodifiable(_reports);
  }

  CampusFixSavedSession? getSavedSession() {
    final savedSession =
        _decodeMap(_preferences?.getString(_sessionStorageKey));
    if (savedSession == null) {
      return null;
    }

    final userJson = savedSession['user'];
    if (userJson is! Map) {
      return null;
    }

    final user = AppUser.fromJson(Map<String, dynamic>.from(userJson));
    if (user.id.isEmpty || user.email.isEmpty) {
      return null;
    }

    return CampusFixSavedSession(
      user: user,
      usesApi: savedSession['usesApi'] == true,
      token: savedSession['token'] as String?,
    );
  }

  void saveSession({
    required AppUser user,
    required bool usesApi,
    String? token,
  }) {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    unawaited(
      preferences.setString(
        _sessionStorageKey,
        jsonEncode({
          'user': user.toJson(),
          'usesApi': usesApi,
          'token': token,
        }),
      ),
    );
  }

  void clearSession() {
    unawaited(_preferences?.remove(_sessionStorageKey));
  }

  AppUser? authenticate({
    required String role,
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    final savedPassword = _passwords[normalizedEmail];
    if (savedPassword == null || savedPassword != password) {
      return null;
    }

    for (final user in _users) {
      if (user.email.toLowerCase() == normalizedEmail && user.role == role) {
        return user;
      }
    }
    return null;
  }

  bool emailExists(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    return _users.any((user) => user.email.toLowerCase() == normalizedEmail);
  }

  void addUser(AppUser user, String password) {
    _users.add(user);
    _passwords[user.email.toLowerCase()] = password;
    _persist();
  }

  void updateUser(AppUser user) {
    final index = _users.indexWhere((item) => item.id == user.id);
    if (index == -1) {
      return;
    }
    _users[index] = user;
    _persist();
  }

  void addReport(ReportModel report) {
    _reports.insert(0, report);
    _persist();
  }

  void updateReport(ReportModel report) {
    final index = _reports.indexWhere((item) => item.id == report.id);
    if (index == -1) {
      return;
    }
    _reports[index] = report.copyWith(updatedAt: DateTime.now());
    _persist();
  }

  void deleteReport(String reportId) {
    _reports.removeWhere((report) => report.id == reportId);
    _persist();
  }

  void addNote(String reportId, ReportNoteModel note) {
    final index = _reports.indexWhere((report) => report.id == reportId);
    if (index == -1) {
      return;
    }

    final report = _reports[index];
    _reports[index] = report.copyWith(
      notes: [...report.notes, note],
      updatedAt: DateTime.now(),
    );
    _persist();
  }

  void validateReport(String reportId) {
    final index = _reports.indexWhere((report) => report.id == reportId);
    if (index == -1) {
      return;
    }

    final report = _reports[index];
    _reports[index] = report.copyWith(
      isValidatedByTeacher: true,
      updatedAt: DateTime.now(),
    );
    _persist();
  }

  void _addDemoPasswords() {
    _passwords.addAll({
      'student@campusfix.app': 'student123',
      'teacher@campusfix.app': 'teacher123',
      'admin@campusfix.app': 'admin123',
    });
  }

  void _ensureSeedUsers() {
    for (final seedUser in SeedData.users) {
      final exists = _users.any(
        (user) => user.email.toLowerCase() == seedUser.email.toLowerCase(),
      );
      if (!exists) {
        _users.add(seedUser);
      }
    }
  }

  void _restore() {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    final savedUsers = _decodeList(preferences.getString(_usersStorageKey));
    if (savedUsers != null) {
      _users
        ..clear()
        ..addAll(
          savedUsers
              .whereType<Map>()
              .map((item) => AppUser.fromJson(Map<String, dynamic>.from(item)))
              .where((user) => user.email.isNotEmpty),
        );
    }

    final savedReports = _decodeList(preferences.getString(_reportsStorageKey));
    if (savedReports != null) {
      _reports
        ..clear()
        ..addAll(
          savedReports.whereType<Map>().map(
                (item) => ReportModel.fromJson(Map<String, dynamic>.from(item)),
              ),
        );
    }

    final savedPasswords =
        _decodeMap(preferences.getString(_passwordsStorageKey));
    if (savedPasswords != null) {
      _passwords
        ..clear()
        ..addEntries(
          savedPasswords.entries.map(
            (entry) => MapEntry(entry.key, entry.value.toString()),
          ),
        );
    }
  }

  void _persist() {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    unawaited(
      preferences.setString(
        _usersStorageKey,
        jsonEncode(_users.map((user) => user.toJson()).toList()),
      ),
    );
    unawaited(
      preferences.setString(
        _reportsStorageKey,
        jsonEncode(_reports.map((report) => report.toJson()).toList()),
      ),
    );
    unawaited(
      preferences.setString(_passwordsStorageKey, jsonEncode(_passwords)),
    );
  }

  List<dynamic>? _decodeList(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);
      return decoded is List ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Map<String, dynamic>? _decodeMap(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on FormatException {
      return null;
    }
  }
}
