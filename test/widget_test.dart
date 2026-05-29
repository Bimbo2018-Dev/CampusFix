import 'package:campusfix/data/local_campusfix_repository.dart';
import 'package:campusfix/main.dart';
import 'package:campusfix/state/app_state.dart';
import 'package:campusfix/utils/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('registered local users can log in again', () async {
    final state = AppState(LocalCampusFixRepository(), apiEnabled: false);

    final error = await state.registerUser(
      name: 'Ana Reyes',
      email: 'ana.reyes@campusfix.app',
      password: 'secret123',
      role: UserRoles.student,
      department: 'Computer Studies',
    );

    expect(error, isNull);
    expect(state.currentUser?.email, 'ana.reyes@campusfix.app');

    state.logout();
    final success = await state.login(
      role: UserRoles.student,
      email: 'ana.reyes@campusfix.app',
      password: 'secret123',
    );

    expect(success, isTrue);
    expect(state.currentUser?.name, 'Ana Reyes');
  });

  testWidgets('CampusFix opens with the splash brand', (tester) async {
    await tester.pumpWidget(
      AppStateScope(
        notifier: AppState(LocalCampusFixRepository(), apiEnabled: false),
        child: const CampusFixApp(),
      ),
    );

    expect(find.text('CampusFix'), findsOneWidget);
    expect(find.text('Report. Track. Resolve.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  testWidgets('CampusFix navigates to role selection after splash',
      (tester) async {
    await tester.pumpWidget(
      AppStateScope(
        notifier: AppState(LocalCampusFixRepository(), apiEnabled: false),
        child: const CampusFixApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to\nCampusFix'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });

  testWidgets('login screen opens registration flow', (tester) async {
    await tester.pumpWidget(
      AppStateScope(
        notifier: AppState(LocalCampusFixRepository(), apiEnabled: false),
        child: const CampusFixApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Student').first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Create a new account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create a new account'));
    await tester.pumpAndSettle();

    expect(find.text('Create CampusFix Account'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
  });

  testWidgets('password fields can be shown and hidden', (tester) async {
    await tester.pumpWidget(
      AppStateScope(
        notifier: AppState(LocalCampusFixRepository(), apiEnabled: false),
        child: const CampusFixApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Student').first);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Show password'), findsOneWidget);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Hide password'), findsOneWidget);

    await tester.ensureVisible(find.text('Create a new account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a new account'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Show password'), findsNWidgets(2));
  });
}
