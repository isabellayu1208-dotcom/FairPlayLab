import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/main.dart';

void main() {
  testWidgets('FairPlay Lab loads overview', (tester) async {
    await tester.pumpWidget(const FairPlayLabApp(useFirebase: false));
    await tester.pumpAndSettle();

    expect(find.text('Enter your data'), findsOneWidget);
  });
}
