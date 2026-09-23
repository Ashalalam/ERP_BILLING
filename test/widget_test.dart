import 'package:flutter_test/flutter_test.dart';
import 'package:erp_billing/main.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Just verify the app widget tree builds
    await tester.pumpWidget(const BillSproutApp());
  });
}
