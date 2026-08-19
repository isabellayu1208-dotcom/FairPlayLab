import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/main.dart';

void main() {
  testWidgets('FairPlay Lab loads overview', (tester) async {
    // No AuthService, so the app runs on local storage without a sign-in gate.
    await tester.pumpWidget(const FairPlayLabApp());
    await tester.pumpAndSettle();

    expect(find.text('Enter your data'), findsOneWidget);
  });
}
