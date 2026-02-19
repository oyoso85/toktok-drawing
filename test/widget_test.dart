import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toktok_drawing/app.dart';

void main() {
  testWidgets('App starts with mode selection screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TokTokDrawingApp()));
    expect(find.text('TokTok Drawing'), findsOneWidget);
  });
}
