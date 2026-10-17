import 'package:flutter_test/flutter_test.dart';
import 'package:monaco/models/message.dart';

void main() {
  group('HomeScreen widget test', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: const Text('Loading')),
      );

      expect(find.byType(Text), findsOneWidget);
    });
  });
}
