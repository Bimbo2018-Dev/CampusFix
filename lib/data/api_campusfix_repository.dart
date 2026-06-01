import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/app_user.dart';
import '../models/report_model.dart';

class ApiCampusFixSession {
  const ApiCampusFixSession({
    required this.token,
    required this.user,
  });

  final String token;
  final AppUser user;
}

class ApiCampusFixException implements Exception {
  const ApiCampusFixException(
    this.message, {
    this.isConnectionFailure = false,
  });

  final String message;
  final bool isConnectionFailure;

  @override
  String toString() => message;
}

class ApiCampusFixRepository {
  ApiCampusFixRepository({
    http.Client? client,
    String? baseUrl,
    Duration timeout = const Duration(seconds: 20),
  })  : _client = client ?? http.Client(),
        _baseUrl = _normalizeBaseUrl(baseUrl ?? _defaultBaseUrl()),
        _timeout = timeout;

  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;
  String? _token;

  String get baseUrl => _baseUrl;
  String? get token => _token;
  bool get isAuthenticated => _token != null;

  void setToken(String? token) {
    _token = token;
  }

  Future<ApiCampusFixSession> login({
    required String role,
    required String email,
    required String password,
  }) async {
    final body = await _send(
      'POST',
      '/auth/login',
      body: {
        'role': role,
        'email': email.trim().toLowerCase(),
        'password': password,
      },
      authenticated: false,
    );

    return _sessionFromJson(body);
  }

  Future<ApiCampusFixSession> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String department,
  }) async {
    final body = await _send(
      'POST',
      '/auth/register',
      body: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'password_confirmation': password,
        'role': role,
        'department': department.trim(),
      },
      authenticated: false,
    );

    return _sessionFromJson(body);
  }

  Future<void> logout() async {
    if (_token == null) {
      return;
    }

    await _send('POST', '/auth/logout');
    _token = null;
  }

  Future<List<AppUser>> fetchUsers() async {
    final body = await _send('GET', '/users');
    final users = body['users'] as List? ?? const [];
    return [
      for (final item in users)
        if (item is Map) AppUser.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  Future<List<ReportModel>> fetchReports() async {
    final body = await _send('GET', '/reports');
    final reports = body['reports'] as List? ?? const [];
    return [
      for (final item in reports)
        if (item is Map) ReportModel.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  Future<AppUser> updateUser({
    required String userId,
    String? role,
    String? department,
    bool? isActive,
  }) async {
    final body = await _send(
      'PATCH',
      '/users/${Uri.encodeComponent(userId)}',
      body: {
        if (role != null) 'role': role,
        if (department != null) 'department': department.trim(),
        if (isActive != null) 'isActive': isActive,
      },
    );

    return AppUser.fromJson(Map<String, dynamic>.from(body['user']));
  }

  Future<ReportModel> addReport({
    required String title,
    required String description,
    required String category,
    required String location,
    required String priority,
    String? imagePath,
  }) async {
    final body = await _send(
      'POST',
      '/reports',
      body: {
        'title': title.trim(),
        'description': description.trim(),
        'category': category,
        'location': location.trim(),
        'priority': priority,
        'imagePath': imagePath,
      },
      timeout: imagePath == null
          ? const Duration(seconds: 35)
          : const Duration(seconds: 90),
    );

    return ReportModel.fromJson(Map<String, dynamic>.from(body['report']));
  }

  Future<ReportModel> updateReportStatus(String reportId, String status) async {
    final body = await _send(
      'PATCH',
      '/reports/${Uri.encodeComponent(reportId)}',
      body: {'status': status},
    );

    return ReportModel.fromJson(Map<String, dynamic>.from(body['report']));
  }

  Future<ReportModel> updateReportAssignment(
    String reportId,
    String? assignedTo,
  ) async {
    final body = await _send(
      'PATCH',
      '/reports/${Uri.encodeComponent(reportId)}',
      body: {'assignedTo': assignedTo},
    );

    return ReportModel.fromJson(Map<String, dynamic>.from(body['report']));
  }

  Future<ReportModel> updateResolvedImage(
    String reportId,
    String? resolvedImagePath,
  ) async {
    final body = await _send(
      'PATCH',
      '/reports/${Uri.encodeComponent(reportId)}',
      body: {'resolvedImagePath': resolvedImagePath},
      timeout: const Duration(seconds: 90),
    );

    return ReportModel.fromJson(Map<String, dynamic>.from(body['report']));
  }

  Future<void> deleteReport(String reportId) async {
    await _send('DELETE', '/reports/${Uri.encodeComponent(reportId)}');
  }

  Future<ReportModel> addNote(String reportId, String message) async {
    final body = await _send(
      'POST',
      '/reports/${Uri.encodeComponent(reportId)}/notes',
      body: {'message': message.trim()},
    );

    return ReportModel.fromJson(Map<String, dynamic>.from(body['report']));
  }

  Future<ReportModel> validateReport(String reportId) async {
    final body = await _send(
      'POST',
      '/reports/${Uri.encodeComponent(reportId)}/validate',
    );

    return ReportModel.fromJson(Map<String, dynamic>.from(body['report']));
  }

  ApiCampusFixSession _sessionFromJson(Map<String, dynamic> body) {
    final token = body['token'] as String?;
    final user = body['user'];
    if (token == null || user is! Map) {
      throw const ApiCampusFixException('Invalid API response.');
    }

    _token = token;
    return ApiCampusFixSession(
      token: token,
      user: AppUser.fromJson(Map<String, dynamic>.from(user)),
    );
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
    Duration? timeout,
  }) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'));
    request.headers['Accept'] = 'application/json';
    request.headers['Content-Type'] = 'application/json';
    const apiCookie = String.fromEnvironment('CAMPUSFIX_API_COOKIE');
    if (!kIsWeb && apiCookie.isNotEmpty) {
      request.headers['Cookie'] = apiCookie;
    }
    if (authenticated) {
      final token = _token;
      if (token == null) {
        throw const ApiCampusFixException('You are not logged in.');
      }
      request.headers['Authorization'] = 'Bearer $token';
    }
    if (body != null) {
      request.body = jsonEncode(body);
    }

    http.StreamedResponse streamed;
    try {
      streamed = await _client.send(request).timeout(timeout ?? _timeout);
    } on TimeoutException {
      throw ApiCampusFixException(
        'Could not reach CampusFix API at $_baseUrl.',
        isConnectionFailure: true,
      );
    } on http.ClientException {
      throw ApiCampusFixException(
        'Could not connect to CampusFix API at $_baseUrl.',
        isConnectionFailure: true,
      );
    }

    final response = await http.Response.fromStream(streamed);
    final decoded = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiCampusFixException(_errorMessage(decoded, response.statusCode));
    }

    return decoded;
  }

  Map<String, dynamic> _decode(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } on FormatException {
      throw const ApiCampusFixException('The API returned invalid JSON.');
    }

    return <String, dynamic>{};
  }

  String _errorMessage(Map<String, dynamic> body, int statusCode) {
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        return first.first.toString();
      }
      return first.toString();
    }

    return body['message'] as String? ?? 'CampusFix API error ($statusCode).';
  }

  static String _defaultBaseUrl() {
    const configured = String.fromEnvironment('CAMPUSFIX_API_BASE');
    if (configured.isNotEmpty) {
      return configured;
    }

    if (kIsWeb && Uri.base.host.isNotEmpty) {
      return '${Uri.base.scheme}://${Uri.base.host}:8001/api';
    }

    return 'http://127.0.0.1:8001/api';
  }

  static String _normalizeBaseUrl(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
