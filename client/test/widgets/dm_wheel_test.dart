import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monaco/models/conversation.dart';
import 'package:monaco/widgets/dm_wheel.dart';

void main() {
  group('DMQuickAccessWheel', () {
    List<Conversation> createTestDMs() {
      return [
        Conversation(
          id: 'dm-1',
          name: null,
          createdAt: DateTime(2026, 1, 1),
          participants: [
            {'id': 'user-a', 'username': 'alexmorgan_demo'},
            {'id': 'user-b', 'username': 'maya_chen'},
          ],
          otherParticipant: {
            'id': 'user-b',
            'username': 'maya_chen',
            'email': 'maya.chen@demo.monaco',
          },
        ),
        Conversation(
          id: 'dm-2',
          name: null,
          createdAt: DateTime(2026, 1, 2),
          participants: [
            {'id': 'user-a', 'username': 'alexmorgan_demo'},
            {'id': 'user-c', 'username': 'theo_reyes'},
          ],
          otherParticipant: {
            'id': 'user-c',
            'username': 'theo_reyes',
            'email': 'theo.reyes@demo.monaco',
          },
        ),
      ];
    }

    testWidgets('is hidden when mode is Off', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DMQuickAccessWheel(
            mode: DMWheelMode.off,
            dms: createTestDMs(),
            onContactSelected: (id) {},
            isOpen: false,
            onOpenChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(DMQuickAccessWheel), findsOneWidget);
    });

    testWidgets('is hidden when open=false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DMQuickAccessWheel(
            mode: DMWheelMode.right,
            dms: createTestDMs(),
            onContactSelected: (id) {},
            isOpen: false,
            onOpenChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(DMQuickAccessWheel), findsOneWidget);
    });

    testWidgets('shows wheel when open', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DMQuickAccessWheel(
            mode: DMWheelMode.right,
            dms: createTestDMs(),
            onContactSelected: (id) {},
            isOpen: true,
            onOpenChanged: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DMQuickAccessWheel), findsOneWidget);
    });

    testWidgets('left mode uses left edge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DMQuickAccessWheel(
            mode: DMWheelMode.left,
            dms: createTestDMs(),
            onContactSelected: (id) {},
            isOpen: true,
            onOpenChanged: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DMQuickAccessWheel), findsOneWidget);
    });

    testWidgets('right mode uses right edge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DMQuickAccessWheel(
            mode: DMWheelMode.right,
            dms: createTestDMs(),
            onContactSelected: (id) {},
            isOpen: true,
            onOpenChanged: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(DMQuickAccessWheel), findsOneWidget);
    });
  });
}
