import 'package:flutter_test/flutter_test.dart';
import 'package:visionfurnish/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const VisionFurnishApp());
    expect(find.byType(VisionFurnishApp), findsOneWidget);
  });
}
