import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fixen/features/authentication/presentation/pages/role_selection_page.dart';

void main() {
  testWidgets('Role Selection Page UI test', (WidgetTester tester) async {
    // Build our widget and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RoleSelectionPage(),
        ),
      ),
    );

    // Verify that the widget compiles and mounts.
    expect(find.byType(RoleSelectionPage), findsOneWidget);
  });
}
