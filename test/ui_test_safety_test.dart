import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../tool/ui_test_safety.dart';

void main() {
  test(
    'Runner rejects a physical device before issuing any build command',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'tiko-runner-guard-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final fakeFlutter = File('${directory.path}/flutter');
      await fakeFlutter.writeAsString('''#!/bin/sh
if [ "\$1" = devices ]; then
  echo '[{"id":"phone","targetPlatform":"ios","emulator":false}]'
else
  echo 'unexpected build or deployment' >&2
  exit 99
fi
''');
      await Process.run('chmod', ['+x', fakeFlutter.path]);
      final result = await Process.run(
        'dart',
        ['run', 'tool/run_ui_review.dart', 'ios', 'phone'],
        environment: {
          'PATH': '${directory.path}:${Platform.environment['PATH']}',
        },
      );
      expect(result.exitCode, 1);
      expect(result.stderr, contains('Physical devices are refused'));
      expect(result.stderr, isNot(contains('unexpected build or deployment')));
    },
    skip: Platform.isWindows,
  );

  test('Physical and unknown devices are refused regardless of name or ID', () {
    for (final device in [
      {
        'id': 'simulator-looking-id',
        'name': 'iPhone Simulator',
        'targetPlatform': 'ios',
        'emulator': false,
      },
      {'targetPlatform': 'ios'},
      {'targetPlatform': 'android-arm64', 'emulator': false},
      {'targetPlatform': 'darwin', 'emulator': true},
    ]) {
      expect(() => requireVirtualTestDevice(device, 'ios'), throwsStateError);
    }
    requireVirtualTestDevice({
      'targetPlatform': 'ios',
      'emulator': true,
    }, 'ios');
    requireVirtualTestDevice({
      'targetPlatform': 'android-x64',
      'emulator': true,
    }, 'android');
    expect(
      () => requireVirtualTestDevice({
        'targetPlatform': 'ios',
        'emulator': true,
      }, 'android'),
      throwsStateError,
    );
  });

  test('Deployment accepts only the exact verified test application ID', () {
    requireTestApplicationId('$uiTestApplicationId\n');
    for (final identifier in [
      'com.sspatari.tiko',
      'com.sspatari.tiko.uitest.other',
      '',
      'unknown',
    ]) {
      expect(() => requireTestApplicationId(identifier), throwsStateError);
    }
    expect(
      androidApplicationId(
        "package: name='com.sspatari.tiko.uitest' versionCode='1'",
      ),
      uiTestApplicationId,
    );
    expect(
      () => androidApplicationId('unreadable manifest'),
      throwsFormatException,
    );
  });

  test(
    'iOS build guard rejects alternate entrypoints with production identity',
    () async {
      for (final target in [
        'integration_test/phone_polish_test.dart',
        '/tmp/generated/test.dart',
        'tool/preview_test.dart',
      ]) {
        final rejected = await Process.run('/bin/sh', [
          'tool/check_ios_test_identity.sh',
          target,
          'com.sspatari.tiko',
          'tiko',
        ]);
        expect(rejected.exitCode, isNot(0));
        final allowed = await Process.run('/bin/sh', [
          'tool/check_ios_test_identity.sh',
          target,
          uiTestApplicationId,
          'tiko-uitest',
        ]);
        expect(allowed.exitCode, 0);
      }
      final wrongScheme = await Process.run('/bin/sh', [
        'tool/check_ios_test_identity.sh',
        'integration_test/test.dart',
        uiTestApplicationId,
        'tiko',
      ]);
      expect(wrongScheme.exitCode, isNot(0));
      for (final main in [
        'lib/main.dart',
        '${Directory.current.path}/lib/main.dart',
      ]) {
        final production = await Process.run('/bin/sh', [
          'tool/check_ios_test_identity.sh',
          main,
          'com.sspatari.tiko',
          'tiko',
        ]);
        expect(production.exitCode, 0);
      }
    },
    skip: Platform.isWindows,
  );
}
