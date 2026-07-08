import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sollu/app.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    // Build our app and trigger a frame, wrapping in ProviderScope.
    await tester.pumpWidget(const ProviderScope(child: SolluApp()));

    // Verify that the app bar title is 'Sollu'
    expect(find.text('Sollu'), findsOneWidget);
  });
}