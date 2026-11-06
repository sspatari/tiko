import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/core/localization/app_localizations.dart';
import 'package:tiko/main.dart';

void main() {
  for (final reducedMotion in [false, true]) {
    testWidgets(
      'Usage feedback updates totals with reduced motion=$reducedMotion',
      (tester) async {
        final total = ValueNotifier(1);
        addTearDown(total.dispose);
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reducedMotion),
                child: Scaffold(
                  body: ValueListenableBuilder<int>(
                    valueListenable: total,
                    builder: (context, uses, _) => Column(
                      children: [
                        AnimatedUsageTotal(uses: uses),
                        UsageProgress(value: uses / 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('1 use'), findsOneWidget);
        total.value = 2;
        await tester.pump();
        expect(find.text('2 uses'), findsOneWidget);
        if (reducedMotion) expect(find.text('1 use'), findsNothing);
        await tester.pumpAndSettle();
        expect(find.text('1 use'), findsNothing);
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator),
              )
              .value,
          .2,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
