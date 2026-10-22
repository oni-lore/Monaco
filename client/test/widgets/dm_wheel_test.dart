import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monaco/models/message.dart';
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
      expect(find.byType(Container), findsNothing);
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

      await tester.pumpAndSettle();

      expect(find.byType(DMQuickAccessWheel), findsOneWidget);
      expect(find.byType(Container), findsNothing);
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

    testWidgets('left mode renders left-edge handle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DMQuickAccessWheel(
            mode: DMWheelMode.left,
            dms: createTestDMs(),
            onContactSelected: (id) {},
            isOpen: false,
            onOpenChanged: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('right mode renders right-edge handle', (WidgetTester tester) async {
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

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    });

    testWidgets('tapping handle opens the wheel', (WidgetTester tester) async {
      bool opened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: DMQuickAccessWheel(
            mode: DMWheelMode.right,
            dms: createTestDMs(),
            onContactSelected: (id) {},
            isOpen: false,
            onOpenChanged: (isOpen) => opened = isOpen,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_right_rounded).first);
      await tester.pumpAndSettle();

      expect(opened, isTrue);
      expect(find.byIcon(Icons.send_rounded), findsNothing);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('tapping first avatar invokes onContactSelected',
        (WidgetTester tester) async {
      String? selectedId;
      await tester.pumpWidget(
        MaterialApp(
          home: DMQuickAccessWheel(
            mode: DMWheelMode.right,
            dms: createTestDMs(),
            onContactSelected: (id) => selectedId = id,
            isOpen: true,
            onOpenChanged: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ValueKey('dm-1')));
      await tester.pump();

      expect(selectedId, 'dm-1');
    });

    testWidgets('tapping second avatar invokes onContactSelected with its id',
        (WidgetTester tester) async {
      String? selectedId;
      await tester.pumpWidget(
        MaterialApp(
          home: DMQuickAccessWheel(
            mode: DMWheelMode.right,
            dms: createTestDMs(),
            onContactSelected: (id) => selectedId = id,
            isOpen: true,
            onOpenChanged: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(ValueKey('dm-2')));
      await tester.pump();

      expect(selectedId, 'dm-2');
    });
  });
}
