import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gamenet/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await initializeDateFormatting('fa_IR');
    await tester.pumpWidget(const GamenetApp());
    await tester.pump();
    expect(find.text('داشبورد'), findsOneWidget);
  });
}
