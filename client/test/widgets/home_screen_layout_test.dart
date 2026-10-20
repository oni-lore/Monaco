import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monaco/providers/demo_mode_provider.dart';
import 'package:monaco/screens/home_screen.dart';
import 'package:monaco/models/conversation.dart';
import 'package:monaco/models/user.dart';

void main() {
  group('HomeScreen layout', () {
    testWidgets('renders Chats screen with header and search', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => DemoModeProvider()..activateDemoMode()),
            ],
            child: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Monaco wordmark
      expect(find.text('Monaco'), findsOneWidget);

      // Verify search bar
      expect(find.text('Search'), findsOneWidget);

      // Verify Notes section
      expect(find.text('Notes'), findsOneWidget);

      // Verify Councils section
      expect(find.text('Councils'), findsOneWidget);
    });

    testWidgets('shows Councils before DMs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => DemoModeProvider()..activateDemoMode()),
            ],
            child: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Councils header should appear before Recent DM header
      expect(find.text('Councils'), findsOneWidget);
      expect(find.text('Recent DM'), findsOneWidget);

      final councilsIndex = tester.getTopLeft(find.text('Councils').first).dy;
      final dmIndex = tester.getTopLeft(find.text('Recent DM').first).dy;

      expect(councilsIndex, lessThan(dmIndex));
    });

    testWidgets('Council cards show names and previews', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => DemoModeProvider()..activateDemoMode()),
            ],
            child: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify council names appear
      expect(find.text('The Design Council'), findsOneWidget);
      expect(find.text('Weekend people'), findsOneWidget);
      expect(find.text('Study Circle'), findsOneWidget);
    });

    testWidgets('bottom navigation has three destinations', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => DemoModeProvider()..activateDemoMode()),
            ],
            child: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Chats'), findsOneWidget);
      expect(find.text('Loading Chambers'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('DM previews section shows individual DMs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => DemoModeProvider()..activateDemoMode()),
            ],
            child: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // DM usernames should appear
      expect(find.text('maya_chen'), findsWidgets);
      expect(find.text('theo_reyes'), findsWidgets);
      expect(find.text('leo_tan'), findsWidgets);
    });

    testWidgets('no duplicate Profile button in header', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => DemoModeProvider()..activateDemoMode()),
            ],
            child: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Only one Logout button in header (no Profile icon button)
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsNothing);
    });
  });
}
