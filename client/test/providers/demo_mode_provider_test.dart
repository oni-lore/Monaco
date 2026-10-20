import 'package:flutter_test/flutter_test.dart';
import 'package:monaco/providers/demo_mode_provider.dart';

void main() {
  group('DemoModeProvider', () {
    test('starts with demo mode off and no user', () {
      final provider = DemoModeProvider();
      expect(provider.isDemoMode, isFalse);
      expect(provider.demoUser, isNull);
      expect(provider.demoUsers, isEmpty);
      expect(provider.demoCouncils, isEmpty);
      expect(provider.demoDMs, isEmpty);
    });

    test('activates demo mode with seeded data', () async {
      final provider = DemoModeProvider();
      await provider.activateDemoMode();

      expect(provider.isDemoMode, isTrue);
      expect(provider.demoUser, isNotNull);
      expect(provider.demoUser?.username, 'alexmorgan_demo');
      expect(provider.demoUser?.id, 'demo-alex-morgan-001');
      expect(provider.demoUsers.length, 5);

      // Councils: 3+ participants
      expect(provider.demoCouncils.length, 3);
      for (final c in provider.demoCouncils) {
        expect(c.isGroup, isTrue);
        expect(c.participants.length, greaterThan(2));
      }

      // DMs: exactly 2 participants
      expect(provider.demoDMs.length, 3);
      for (final d in provider.demoDMs) {
        expect(d.isGroup, isFalse);
        expect(d.participants.length, 2);
      }
    });

    test('demo user identity is correct', () async {
      final provider = DemoModeProvider();
      await provider.activateDemoMode();

      expect(provider.demoUser?.email, 'alex.morgan@demo.monaco');
      expect(provider.demoUser?.emailVerified, isTrue);
    });

    test('resetting demo data restores initial state', () async {
      final provider = DemoModeProvider();
      await provider.activateDemoMode();

      provider.clearError();

      await provider.resetDemoData();

      expect(provider.isDemoMode, isTrue);
      expect(provider.demoUser?.username, 'alexmorgan_demo');
      expect(provider.demoCouncils.length, 3);
      expect(provider.demoDMs.length, 3);
    });

    test('deactivating demo mode clears all data', () async {
      final provider = DemoModeProvider();
      await provider.activateDemoMode();
      await provider.deactivateDemoMode();

      expect(provider.isDemoMode, isFalse);
      expect(provider.demoUser, isNull);
      expect(provider.demoUsers, isEmpty);
      expect(provider.demoCouncils, isEmpty);
      expect(provider.demoDMs, isEmpty);
    });

    test('isDemoUserId identifies demo user correctly', () async {
      final provider = DemoModeProvider();
      await provider.activateDemoMode();

      expect(provider.isDemoUserId('demo-alex-morgan-001'), isTrue);
      expect(provider.isDemoUserId('demo-user-maya-001'), isFalse);
    });

    test('getDemoConversationById returns correct conversation', () async {
      final provider = DemoModeProvider();
      await provider.activateDemoMode();

      final council = provider.getDemoConversationById('demo-council-design-001');
      expect(council, isNotNull);
      expect(council?.displayName, 'The Design Council');
      expect(council?.isGroup, isTrue);

      final dm = provider.getDemoConversationById('demo-dm-maya-001');
      expect(dm, isNotNull);
      expect(dm?.isGroup, isFalse);
    });

    test('getDemoUserById returns correct user', () async {
      final provider = DemoModeProvider();
      await provider.activateDemoMode();

      final user = provider.getDemoUserById('demo-user-maya-001');
      expect(user, isNotNull);
      expect(user?.username, 'maya_chen');
    });

    test('councils are above DMs in conversation list', () async {
      final provider = DemoModeProvider();
      await provider.activateDemoMode();

      final all = provider.demoConversations;
      final councils = all.where((c) => c.isGroup).toList();
      final dms = all.where((c) => !c.isGroup).toList();

      expect(councils.length, 3);
      expect(dms.length, 3);

      final councilIds = councils.map((c) => c.id).toSet();
      final dmIds = dms.map((d) => d.id).toSet();
      expect(councilIds.intersection(dmIds), isEmpty);
    });
  });
}
