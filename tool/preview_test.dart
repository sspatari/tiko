import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiko/core/database/database.dart';
import 'package:tiko/main.dart';

void main() {
  testWidgets('Dashboard preview', (tester) async {
    await tester.runAsync(() async {
    final font = FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(File('/System/Library/Fonts/Supplemental/Arial.ttf').readAsBytesSync())));
    await font.load();
    final icons = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(File('/Users/stanislavspatari/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync())));
    await icons.load();
    });
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(overrides: [
      totalsProvider.overrideWith((ref) => Stream.value(<String, int>{})),
          subscriptionsProvider.overrideWith((ref) => Stream.value(<Subscription>[])),
      eventsProvider.overrideWith((ref) => Stream.value(<UsageEvent>[])),
    ], child: const TikoApp()));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('../build/preview/tiko-dashboard.png'));
  }, skip: !const bool.fromEnvironment('TIKO_PREVIEW'));
}
