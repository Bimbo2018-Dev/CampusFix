import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/api_campusfix_repository.dart';
import '../data/local_campusfix_repository.dart';
import '../models/app_user.dart';
import '../models/report_model.dart';
import '../models/report_note_model.dart';
import '../utils/app_constants.dart';
import '../utils/app_helpers.dart';

class AppState extends ChangeNotifier {
  AppState(
    this._repository, {
    ApiCampusFixRepository? apiRepository,
    bool apiEnabled = true,
  })  : _apiRepository = apiRepository ?? ApiCampusFixRepository(),
        _apiEnabled = apiEnabled,
        _reports = _repository.getReports(),
        _users = _repository.getUsers() {
    _restoreSession();
  }

  final LocalCampusFixRepository _repository;
  final ApiCampusFixRepository _apiRepository;
  final bool _apiEnabled;
  List<ReportModel> _reports;
  List<AppUser> _users;
  Timer? _syncTimer;
  bool _usesApi = false;
  bool _isSyncing = false;

  AppUser? currentUser;
  String? selectedRole;
  String searchQuery = '';
  String? statusFilter;
  String? priorityFilter;
  String? categoryFilter;
  String? apiError;
  String? lastInfoMessage;

  List<AppUser> get users => List.unmodifiable(_users);
  List<ReportModel> get reports => List.unmodifiable(_reports);
  bool get isApiConnected => _usesApi;
  String get apiBaseUrl => _apiRepository.baseUrl;

  Future<bool> login({
    required String role,
    required String email,
    required String password,
  }) async {
    selectedRole = role;
    apiError = null;

    if (_apiEnabled) {
      try {
        final session = await _apiRepository.login(
          role: role,
          email: email,
          password: password,
        );
        _activateApiSession(session);
        await refreshFromApi(notify: false);
        notifyListeners();
        return true;
      } on ApiCampusFixException catch (error) {
        if (!error.isConnectionFailure) {
          apiError = error.message;
          notifyListeners();
          return false;
        }
        apiError = error.message;
      }
    }

    final user = _repository.authenticate(
      role: role,
      email: email,
      password: password,
    );

    if (user == null) {
      notifyListeners();
      return false;
    }
    if (!user.isActive) {
      apiError = 'This account is deactivated. Contact the campus admin.';
      notifyListeners();
      return false;
    }

    currentUser = user;
    _usesApi = false;
    _users = _repository.getUsers();
    clearFilters(notify: false);
    _syncTimer?.cancel();
    _saveSession();
    notifyListeners();
    return true;
  }

  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
    required String department,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (_apiEnabled) {
      try {
        final session = await _apiRepository.register(
          name: name,
          email: normalizedEmail,
          password: password,
          role: role,
          department: department,
        );
        _activateApiSession(session);
        await refreshFromApi(notify: false);
        notifyListeners();
        return null;
      } on ApiCampusFixException catch (error) {
        if (!error.isConnectionFailure) {
          apiError = error.message;
          notifyListeners();
          return error.message;
        }
        apiError = error.message;
        notifyListeners();
        return '${error.message} Make sure the phone is using the laptop LAN address, not 127.0.0.1.';
      }
    }

    if (_repository.emailExists(normalizedEmail)) {
      return 'An account with this email already exists.';
    }

    final user = AppUser(
      id: 'user-${role.toLowerCase()}-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      email: normalizedEmail,
      role: role,
      department: department.trim(),
      avatarText: AppHelpers.initials(name),
    );

    _repository.addUser(user, password);
    selectedRole = role;
    currentUser = user;
    _usesApi = false;
    _users = _repository.getUsers();
    clearFilters(notify: false);
    _syncTimer?.cancel();
    _saveSession();
    notifyListeners();
    return null;
  }

  void setSelectedRole(String role) {
    selectedRole = role;
    notifyListeners();
  }

  void logout() {
    if (_usesApi) {
      unawaited(_apiRepository.logout().catchError((_) {}));
    }
    _syncTimer?.cancel();
    _apiRepository.setToken(null);
    _usesApi = false;
    currentUser = null;
    selectedRole = null;
    apiError = null;
    _repository.clearSession();
    clearFilters(notify: false);
    notifyListeners();
  }

  ReportModel? findReport(String reportId) {
    for (final report in _reports) {
      if (report.id == reportId) {
        return report;
      }
    }
    return null;
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void setStatusFilter(String? value) {
    statusFilter = value == 'All' ? null : value;
    notifyListeners();
  }

  void setPriorityFilter(String? value) {
    priorityFilter = value == 'All' ? null : value;
    notifyListeners();
  }

  void setCategoryFilter(String? value) {
    categoryFilter = value == 'All' ? null : value;
    notifyListeners();
  }

  void clearFilters({bool notify = true}) {
    searchQuery = '';
    statusFilter = null;
    priorityFilter = null;
    categoryFilter = null;
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> addReport({
    required String title,
    required String description,
    required String category,
    required String location,
    required String priority,
    String? imagePath,
  }) async {
    final user = currentUser;
    if (user == null) {
      return;
    }
    lastInfoMessage = null;

    if (_usesApi) {
      try {
        final report = await _apiRepository.addReport(
          title: title,
          description: description,
          category: category,
          location: location,
          priority: priority,
          imagePath: imagePath,
        );
        _reports = [report, ..._reports.where((item) => item.id != report.id)];
        apiError = null;
        notifyListeners();
        return;
      } on ApiCampusFixException catch (error) {
        if (error.isConnectionFailure) {
          final report = _buildLocalReport(
            user: user,
            title: title,
            description: description,
            category: category,
            location: location,
            priority: priority,
            imagePath: imagePath,
            isOfflineQueued: true,
          );
          _repository.addReport(report);
          _reports = [report, ..._reports];
          apiError = error.message;
          lastInfoMessage =
              'Saved offline. CampusFix will auto-sync this report when the API is reachable.';
          notifyListeners();
          return;
        }
        apiError = error.message;
        notifyListeners();
        rethrow;
      }
    }

    final report = _buildLocalReport(
      user: user,
      title: title,
      description: description,
      category: category,
      location: location,
      priority: priority,
      imagePath: imagePath,
    );

    _repository.addReport(report);
    _reports = _repository.getReports();
    notifyListeners();
  }

  Future<void> updateReportStatus(String reportId, String status) async {
    final report = findReport(reportId);
    final user = currentUser;
    if (report == null || user == null) {
      return;
    }

    if (_usesApi) {
      try {
        final updated = await _apiRepository.updateReportStatus(
          reportId,
          status,
        );
        _replaceReport(updated);
        apiError = null;
        notifyListeners();
        return;
      } on ApiCampusFixException catch (error) {
        apiError = error.message;
        notifyListeners();
        rethrow;
      }
    }

    _repository.updateReport(report.copyWith(status: status));
    _repository.addNote(
      reportId,
      ReportNoteModel(
        id: 'note-${DateTime.now().microsecondsSinceEpoch}',
        authorName: user.name,
        authorRole: user.role,
        message: 'Status changed to $status.',
        createdAt: DateTime.now(),
      ),
    );
    _reports = _repository.getReports();
    notifyListeners();
  }

  Future<void> updateReportAssignment(
    String reportId,
    String? assignedTo,
  ) async {
    final report = findReport(reportId);
    final user = currentUser;
    if (report == null || user?.role != UserRoles.admin) {
      return;
    }

    if (_usesApi && !report.isOfflineQueued) {
      try {
        final updated = await _apiRepository.updateReportAssignment(
          reportId,
          assignedTo,
        );
        _replaceReport(updated);
        apiError = null;
        notifyListeners();
        return;
      } on ApiCampusFixException catch (error) {
        apiError = error.message;
        notifyListeners();
        rethrow;
      }
    }

    _repository.updateReport(report.copyWith(assignedTo: assignedTo ?? ''));
    if (assignedTo != null && assignedTo.isNotEmpty) {
      _repository.addNote(
        reportId,
        ReportNoteModel(
          id: 'note-${DateTime.now().microsecondsSinceEpoch}',
          authorName: user!.name,
          authorRole: user.role,
          message: 'Assigned to $assignedTo.',
          createdAt: DateTime.now(),
        ),
      );
    }
    _reports = _repository.getReports();
    notifyListeners();
  }

  Future<void> updateResolvedImage(
    String reportId,
    String resolvedImagePath,
  ) async {
    final report = findReport(reportId);
    final user = currentUser;
    if (report == null || user?.role != UserRoles.admin) {
      return;
    }

    if (_usesApi && !report.isOfflineQueued) {
      try {
        final updated = await _apiRepository.updateResolvedImage(
          reportId,
          resolvedImagePath,
        );
        _replaceReport(updated);
        apiError = null;
        notifyListeners();
        return;
      } on ApiCampusFixException catch (error) {
        apiError = error.message;
        notifyListeners();
        rethrow;
      }
    }

    _repository
        .updateReport(report.copyWith(resolvedImagePath: resolvedImagePath));
    _repository.addNote(
      reportId,
      ReportNoteModel(
        id: 'note-${DateTime.now().microsecondsSinceEpoch}',
        authorName: user!.name,
        authorRole: user.role,
        message: 'Resolution photo uploaded.',
        createdAt: DateTime.now(),
      ),
    );
    _reports = _repository.getReports();
    notifyListeners();
  }

  Future<void> updateUserAccount(
    AppUser user, {
    String? role,
    String? department,
    bool? isActive,
  }) async {
    final admin = currentUser;
    if (admin?.role != UserRoles.admin) {
      return;
    }

    if (_usesApi) {
      try {
        final updated = await _apiRepository.updateUser(
          userId: user.id,
          role: role,
          department: department,
          isActive: isActive,
        );
        _replaceUser(updated);
        apiError = null;
        _saveSession();
        notifyListeners();
        return;
      } on ApiCampusFixException catch (error) {
        apiError = error.message;
        notifyListeners();
        rethrow;
      }
    }

    final updated = user.copyWith(
      role: role,
      department: department,
      isActive: isActive,
    );
    _repository.updateUser(updated);
    _replaceUser(updated);
    _saveSession();
    notifyListeners();
  }

  Future<void> deleteReport(String reportId) async {
    final report = findReport(reportId);
    if (_usesApi && report?.isOfflineQueued != true) {
      try {
        await _apiRepository.deleteReport(reportId);
        _reports = _reports
            .where((report) => report.id != reportId)
            .toList(growable: false);
        apiError = null;
        notifyListeners();
        return;
      } on ApiCampusFixException catch (error) {
        apiError = error.message;
        notifyListeners();
        rethrow;
      }
    }

    _repository.deleteReport(reportId);
    _reports = _repository.getReports();
    notifyListeners();
  }

  Future<void> addReportNote(String reportId, String message) async {
    final user = currentUser;
    if (user == null || message.trim().isEmpty) {
      return;
    }
    final report = findReport(reportId);

    if (_usesApi && report?.isOfflineQueued != true) {
      try {
        final updated = await _apiRepository.addNote(reportId, message);
        _replaceReport(updated);
        apiError = null;
        notifyListeners();
        return;
      } on ApiCampusFixException catch (error) {
        apiError = error.message;
        notifyListeners();
        rethrow;
      }
    }

    _repository.addNote(
      reportId,
      ReportNoteModel(
        id: 'note-${DateTime.now().microsecondsSinceEpoch}',
        authorName: user.name,
        authorRole: user.role,
        message: message.trim(),
        createdAt: DateTime.now(),
      ),
    );
    _reports = _repository.getReports();
    notifyListeners();
  }

  Future<void> validateReportByTeacher(String reportId) async {
    final user = currentUser;
    if (user == null || user.role != UserRoles.teacher) {
      return;
    }

    final report = findReport(reportId);

    if (_usesApi && report?.isOfflineQueued != true) {
      try {
        final updated = await _apiRepository.validateReport(reportId);
        _replaceReport(updated);
        apiError = null;
        notifyListeners();
        return;
      } on ApiCampusFixException catch (error) {
        apiError = error.message;
        notifyListeners();
        rethrow;
      }
    }

    _repository.validateReport(reportId);
    _repository.addNote(
      reportId,
      ReportNoteModel(
        id: 'note-${DateTime.now().microsecondsSinceEpoch}',
        authorName: user.name,
        authorRole: user.role,
        message: 'Report validated by teacher.',
        createdAt: DateTime.now(),
      ),
    );
    _reports = _repository.getReports();
    notifyListeners();
  }

  List<ReportModel> getReportsForCurrentUser() {
    final user = currentUser;
    if (user == null) {
      return const [];
    }

    switch (user.role) {
      case UserRoles.student:
        return _reports
            .where((report) => report.reporterId == user.id)
            .toList(growable: false);
      case UserRoles.teacher:
        return _reports
            .where(
              (report) =>
                  report.reporterRole == UserRoles.student ||
                  report.reporterId == user.id,
            )
            .toList(growable: false);
      case UserRoles.admin:
      default:
        return reports;
    }
  }

  List<ReportModel> getFilteredReports({List<ReportModel>? source}) {
    final base = source ?? getReportsForCurrentUser();
    return base.where((report) {
      final query = searchQuery.trim();
      final matchesSearch = query.isEmpty ||
          AppHelpers.containsQuery(report.title, query) ||
          AppHelpers.containsQuery(report.description, query) ||
          AppHelpers.containsQuery(report.location, query) ||
          AppHelpers.containsQuery(report.reporterName, query) ||
          AppHelpers.containsQuery(report.category, query);
      final matchesStatus =
          statusFilter == null || report.status == statusFilter;
      final matchesPriority =
          priorityFilter == null || report.priority == priorityFilter;
      final matchesCategory =
          categoryFilter == null || report.category == categoryFilter;

      return matchesSearch &&
          matchesStatus &&
          matchesPriority &&
          matchesCategory;
    }).toList(growable: false);
  }

  List<AppUser> getFilteredUsers({List<AppUser>? source}) {
    final base = source ?? users;
    final query = searchQuery.trim();
    if (query.isEmpty) {
      return base;
    }

    return base.where((user) {
      return AppHelpers.containsQuery(user.name, query) ||
          AppHelpers.containsQuery(user.email, query) ||
          AppHelpers.containsQuery(user.role, query) ||
          AppHelpers.containsQuery(user.department, query);
    }).toList(growable: false);
  }

  List<ReportModel> findPotentialDuplicates({
    required String title,
    required String category,
    required String location,
  }) {
    final normalizedTitle = title.trim().toLowerCase();
    final normalizedLocation = location.trim().toLowerCase();
    if (normalizedTitle.isEmpty || normalizedLocation.isEmpty) {
      return const [];
    }

    return getReportsForCurrentUser().where((report) {
      if (report.status == ReportStatuses.resolved ||
          report.status == ReportStatuses.rejected) {
        return false;
      }

      final sameCategory = report.category == category;
      final sameLocation = report.location.toLowerCase() == normalizedLocation;
      final titleWords = normalizedTitle
          .split(RegExp(r'\s+'))
          .where((word) => word.length >= 4)
          .toList();
      final matchingWords = titleWords
          .where((word) => report.title.toLowerCase().contains(word))
          .length;

      return sameCategory && (sameLocation || matchingWords >= 2);
    }).toList(growable: false);
  }

  List<ReportModel> overdueReports({List<ReportModel>? source}) {
    final base = source ?? reports;
    return base
        .where(
          (report) => AppHelpers.isReportOverdue(
            createdAt: report.createdAt,
            priority: report.priority,
            status: report.status,
          ),
        )
        .toList(growable: false);
  }

  List<ReportModel> unassignedReports({List<ReportModel>? source}) {
    final base = source ?? reports;
    return base
        .where(
          (report) =>
              report.status != ReportStatuses.resolved &&
              report.status != ReportStatuses.rejected &&
              (report.assignedTo == null || report.assignedTo!.isEmpty),
        )
        .toList(growable: false);
  }

  List<ReportModel> queuedReports() {
    return _repository
        .getReports()
        .where((report) => report.isOfflineQueued)
        .toList(growable: false);
  }

  int countByStatus(String status, {List<ReportModel>? source}) {
    final base = source ?? getReportsForCurrentUser();
    return base.where((report) => report.status == status).length;
  }

  int countByPriority(String priority, {List<ReportModel>? source}) {
    final base = source ?? getReportsForCurrentUser();
    return base.where((report) => report.priority == priority).length;
  }

  int countUsersByRole(String role, {List<AppUser>? source}) {
    final base = source ?? users;
    return base.where((user) => user.role == role).length;
  }

  int countNeedsValidation() {
    return getReportsForCurrentUser()
        .where(
          (report) =>
              report.reporterRole == UserRoles.student &&
              !report.isValidatedByTeacher,
        )
        .length;
  }

  int totalSubmittedByCurrentUser() {
    final user = currentUser;
    if (user == null) {
      return 0;
    }
    return _reports.where((report) => report.reporterId == user.id).length;
  }

  List<Map<String, String>> generatedNotifications() {
    return _reports.take(8).map((report) {
      final title = switch (report.status) {
        ReportStatuses.resolved => 'Report resolved',
        ReportStatuses.inProgress => 'Status changed',
        ReportStatuses.reviewed => 'Report reviewed',
        _ => 'Report submitted',
      };

      return {
        'title': title,
        'message': '${report.title} is ${report.status.toLowerCase()}.',
        'date': AppHelpers.formatDateTime(report.updatedAt),
        'reportId': report.id,
      };
    }).toList(growable: false);
  }

  Future<void> refreshFromApi({bool notify = true}) async {
    final user = currentUser;
    if (!_usesApi || user == null || _isSyncing) {
      return;
    }

    _isSyncing = true;
    try {
      await _syncQueuedReports();
      _reports = await _apiRepository.fetchReports();
      _mergeQueuedReports();
      if (user.role == UserRoles.admin) {
        _users = await _apiRepository.fetchUsers();
      } else {
        _users = [user];
      }
      _saveSession();
      apiError = null;
    } on ApiCampusFixException catch (error) {
      apiError = error.message;
    } finally {
      _isSyncing = false;
    }

    if (notify) {
      notifyListeners();
    }
  }

  void _activateApiSession(ApiCampusFixSession session) {
    currentUser = session.user;
    selectedRole = session.user.role;
    _apiRepository.setToken(session.token);
    _usesApi = true;
    _users = [session.user];
    clearFilters(notify: false);
    _saveSession();
    _startAutoSync();
  }

  void _restoreSession() {
    final session = _repository.getSavedSession();
    if (session == null || !session.user.isActive) {
      return;
    }

    currentUser = session.user;
    selectedRole = session.user.role;
    _usesApi = session.usesApi && session.token != null && _apiEnabled;
    if (_usesApi) {
      _apiRepository.setToken(session.token);
      _users = [session.user];
      _startAutoSync();
      unawaited(refreshFromApi());
    } else {
      _users = _repository.getUsers();
    }
  }

  void _saveSession() {
    final user = currentUser;
    if (user == null) {
      _repository.clearSession();
      return;
    }

    _repository.saveSession(
      user: user,
      usesApi: _usesApi,
      token: _usesApi ? _apiRepository.token : null,
    );
  }

  void _startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => unawaited(refreshFromApi()),
    );
  }

  void _replaceReport(ReportModel updated) {
    final index = _reports.indexWhere((report) => report.id == updated.id);
    if (index == -1) {
      _reports = [updated, ..._reports];
      return;
    }
    final next = List<ReportModel>.from(_reports);
    next[index] = updated;
    _reports = next;
  }

  void _replaceUser(AppUser updated) {
    final index = _users.indexWhere((user) => user.id == updated.id);
    if (index == -1) {
      _users = [updated, ..._users];
      return;
    }
    final next = List<AppUser>.from(_users);
    next[index] = updated;
    _users = next;
    if (currentUser?.id == updated.id) {
      currentUser = updated;
    }
  }

  ReportModel _buildLocalReport({
    required AppUser user,
    required String title,
    required String description,
    required String category,
    required String location,
    required String priority,
    String? imagePath,
    bool isOfflineQueued = false,
  }) {
    final now = DateTime.now();
    final prefix = isOfflineQueued ? 'LOCAL' : 'CF';
    return ReportModel(
      id: '$prefix-${1000 + _reports.length + 1}',
      reporterId: user.id,
      reporterName: user.name,
      reporterRole: user.role,
      title: title.trim(),
      description: description.trim(),
      category: category,
      location: location.trim(),
      priority: priority,
      status: ReportStatuses.pending,
      createdAt: now,
      updatedAt: now,
      imagePath: imagePath,
      isValidatedByTeacher: user.role == UserRoles.teacher,
      isOfflineQueued: isOfflineQueued,
      notes: const [],
    );
  }

  Future<void> _syncQueuedReports() async {
    final user = currentUser;
    if (!_usesApi || user == null) {
      return;
    }

    final queued = _repository
        .getReports()
        .where(
          (report) => report.isOfflineQueued && report.reporterId == user.id,
        )
        .toList(growable: false);

    for (final report in queued) {
      try {
        final synced = await _apiRepository.addReport(
          title: report.title,
          description: report.description,
          category: report.category,
          location: report.location,
          priority: report.priority,
          imagePath: report.imagePath,
        );
        _repository.deleteReport(report.id);
        _replaceReport(synced);
      } on ApiCampusFixException catch (error) {
        if (error.isConnectionFailure) {
          return;
        }
        _repository.deleteReport(report.id);
      }
    }
  }

  void _mergeQueuedReports() {
    final user = currentUser;
    if (user == null) {
      return;
    }

    final queued = _repository
        .getReports()
        .where(
          (report) => report.isOfflineQueued && report.reporterId == user.id,
        )
        .toList(growable: false);
    if (queued.isEmpty) {
      return;
    }

    _reports = [
      ...queued,
      ..._reports.where(
        (report) => !queued.any((queuedReport) => queuedReport.id == report.id),
      ),
    ];
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppState watch(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope?.notifier != null, 'AppStateScope is missing.');
    return scope!.notifier!;
  }

  static AppState read(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<AppStateScope>();
    final scope = element?.widget as AppStateScope?;
    assert(scope?.notifier != null, 'AppStateScope is missing.');
    return scope!.notifier!;
  }
}
