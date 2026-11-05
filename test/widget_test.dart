import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/core/database/database.dart';
import 'package:tiko/main.dart';

void main() {
  testWidgets('Empty dashboard invites creation without seeded data', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          subscriptionsProvider.overrideWith(
            (ref) => Stream.value(<Subscription>[]),
          ),
          eventsProvider.overrideWith((ref) => Stream.value(<UsageEvent>[])),
        ],
        child: const TikoApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tiko'), findsOneWidget);
    expect(find.text('Make every use count'), findsOneWidget);
    expect(find.text('Create counter'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
