import 'package:flutter_test/flutter_test.dart';

import 'package:mongolite/main.dart';

void main() {
  testWidgets('App loads and shows connection screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MongoLiteApp());
    expect(find.text('MongoLite'), findsOneWidget);
  });
}
