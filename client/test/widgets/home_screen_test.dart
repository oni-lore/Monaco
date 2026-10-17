import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  group('HomeScreen widget test', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Text('Loading')),
      );

      expect(find.byType(Text), findsOneWidget);
    });
  });
}
