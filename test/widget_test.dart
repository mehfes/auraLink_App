import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_flutter_app/main.dart';
import 'package:my_flutter_app/providers/app_state.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState(testMode: true)),
        ],
        child: const AuraLinkApp(),
      ),
    );

    // Verify that the app builds.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
