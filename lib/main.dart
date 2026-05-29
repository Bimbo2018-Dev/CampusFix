import 'dart:async';

import 'package:flutter/material.dart';

import 'data/local_campusfix_repository.dart';
import 'screens/accounts_screen.dart';
import 'screens/add_report_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/registration_screen.dart';
import 'screens/report_details_screen.dart';
import 'screens/reports_list_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/student_dashboard_screen.dart';
import 'screens/teacher_dashboard_screen.dart';
import 'state/app_state.dart';
import 'utils/app_colors.dart';
import 'utils/app_constants.dart';
import 'utils/app_update_checker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await LocalCampusFixRepository.persistent();

  runApp(
    AppStateScope(
      notifier: AppState(repository),
      child: const CampusFixApp(),
    ),
  );
}

class CampusFixApp extends StatefulWidget {
  const CampusFixApp({super.key});

  @override
  State<CampusFixApp> createState() => _CampusFixAppState();
}

class _CampusFixAppState extends State<CampusFixApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  Timer? _updateTimer;
  bool _checkingForUpdate = false;
  bool _showingUpdateDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForAndroidUpdate());
      _updateTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => unawaited(_checkForAndroidUpdate()),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkForAndroidUpdate());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkForAndroidUpdate() async {
    if (_checkingForUpdate || _showingUpdateDialog || !mounted) {
      return;
    }

    _checkingForUpdate = true;
    try {
      final state = AppStateScope.read(context);
      final updateInfo = await CampusFixUpdateChecker.checkForAndroidUpdate(
        apiBaseUrl: state.apiBaseUrl,
      );
      if (updateInfo != null && mounted) {
        await _showAndroidUpdateDialog(updateInfo);
      }
    } finally {
      _checkingForUpdate = false;
    }
  }

  Future<void> _showAndroidUpdateDialog(
    CampusFixUpdateInfo updateInfo,
  ) async {
    final navigatorContext = _navigatorKey.currentContext;
    if (navigatorContext == null || !navigatorContext.mounted) {
      return;
    }

    _showingUpdateDialog = true;
    await showDialog<void>(
      context: navigatorContext,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.system_update_alt_outlined),
          title: const Text('Update available'),
          content: const Text(
            'A newer CampusFix Android app is ready. Download and install it to get the latest fixes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Later'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final opened = await CampusFixUpdateChecker.openAndroidUpdate(
                  updateInfo,
                );
                final context = _navigatorKey.currentContext;
                if (context == null || !context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      opened
                          ? 'Downloading CampusFix update...'
                          : 'Could not open the update download.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download'),
            ),
          ],
        );
      },
    );
    _showingUpdateDialog = false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'CampusFix',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: _initialRoute(),
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case CampusFixRoutes.roles:
            page = const RoleSelectionScreen();
            break;
          case CampusFixRoutes.login:
            final role = settings.arguments as String? ?? UserRoles.student;
            page = LoginScreen(selectedRole: role);
            break;
          case CampusFixRoutes.register:
            final role = settings.arguments as String? ?? UserRoles.student;
            page = RegistrationScreen(selectedRole: role);
            break;
          case CampusFixRoutes.dashboard:
            page = const _DashboardRouter();
            break;
          case CampusFixRoutes.reports:
            page = const ReportsListScreen();
            break;
          case CampusFixRoutes.addReport:
            page = const AddReportScreen();
            break;
          case CampusFixRoutes.accounts:
            page = const AccountsScreen();
            break;
          case CampusFixRoutes.notifications:
            page = const NotificationsScreen();
            break;
          case CampusFixRoutes.profile:
            page = const ProfileScreen();
            break;
          case CampusFixRoutes.reportDetails:
            page = ReportDetailsScreen(
              reportId: settings.arguments as String? ?? '',
            );
            break;
          case CampusFixRoutes.splash:
          default:
            page = const SplashScreen();
        }

        return MaterialPageRoute(builder: (_) => page, settings: settings);
      },
    );
  }

  String _initialRoute() {
    final route = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    if (route.isEmpty || route == '/') {
      return CampusFixRoutes.splash;
    }
    return route;
  }

  ThemeData _buildTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.background,
      error: AppColors.rejected,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.rejected),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFEDEEEF),
        indicatorColor: const Color(0xFFD4E3FF),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.w900,
          color: AppColors.text,
          height: 1,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
          height: 1.2,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: AppColors.text,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: AppColors.mutedText,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppColors.mutedText,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          letterSpacing: 0.4,
          color: AppColors.mutedText,
        ),
      ),
    );
  }
}

class _DashboardRouter extends StatelessWidget {
  const _DashboardRouter();

  @override
  Widget build(BuildContext context) {
    final role = AppStateScope.watch(context).currentUser?.role;
    switch (role) {
      case UserRoles.teacher:
        return const TeacherDashboardScreen();
      case UserRoles.admin:
        return const AdminDashboardScreen();
      case UserRoles.student:
        return const StudentDashboardScreen();
      default:
        return const RoleSelectionScreen();
    }
  }
}
