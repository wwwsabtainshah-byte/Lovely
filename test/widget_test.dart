import 'package:flutter_test/flutter_test.dart';
import 'package:lovely_chat/main.dart';
void main() {
  testWidgets('App shows free and paid rooms', (tester) async {
    await tester.pumpWidget(const LovelyChat());
    expect(find.text('10 Seats'), findsOneWidget);
    expect(find.text('15 Seats'), findsOneWidget);
  });
}
