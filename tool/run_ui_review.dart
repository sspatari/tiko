import 'dart:convert';
import 'dart:io';
import 'ui_test_safety.dart';

const target = 'integration_test/phone_polish_test.dart';

Future<String> readCommand(String executable, List<String> arguments) async {
  final result = await Process.run(
    executable,
    arguments,
    runInShell: Platform.isWindows,
  );
  if (result.exitCode != 0) {
    throw ProcessException(
      executable,
      arguments,
      '${result.stderr}',
      result.exitCode,
    );
  }
  return result.stdout.toString().trim();
}

Future<void> flutter(List<String> arguments) async {
  final process = await Process.start(
    'flutter',
    arguments,
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  final result = await process.exitCode;
  if (result != 0) {
    throw ProcessException(
      'flutter',
      arguments,
      'Flutter command failed.',
      result,
    );
  }
}

Future<String> aaptPath() async {
  final properties = File('android/local.properties');
  String? sdk =
      Platform.environment['ANDROID_SDK_ROOT'] ??
      Platform.environment['ANDROID_HOME'];
  if (properties.existsSync()) {
    for (final line in await properties.readAsLines()) {
      if (line.startsWith('sdk.dir=')) {
        sdk = line
            .substring('sdk.dir='.length)
            .replaceAll(r'\:', ':')
            .replaceAll(r'\\', r'\');
      }
    }
  }
  if (sdk == null) {
    throw StateError('Android SDK path unavailable; cannot verify the APK.');
  }
  final versions = await Directory(
    '$sdk/build-tools',
  ).list().where((entry) => entry is Directory).toList();
  versions.sort((a, b) => b.path.compareTo(a.path));
  for (final version in versions) {
    final path = '${version.path}/aapt${Platform.isWindows ? '.exe' : ''}';
    if (File(path).existsSync()) return path;
  }
  throw StateError('aapt unavailable; cannot verify the APK.');
}

Future<void> main(List<String> arguments) async {
  Directory? staging;
  try {
    if (arguments.length != 2 || !['ios', 'android'].contains(arguments[0])) {
      throw ArgumentError(
        'Usage: dart run tool/run_ui_review.dart <ios|android> <simulator-or-emulator-id>',
      );
    }
    final platform = arguments[0];
    final id = arguments[1];
    final devices =
        jsonDecode(await readCommand('flutter', ['devices', '--machine']))
            as List<dynamic>;
    final selected = devices
        .whereType<Map<String, dynamic>>()
        .where((device) => device['id'] == id)
        .toList();
    if (selected.length != 1) {
      throw StateError(
        'Choose an available simulator/emulator from flutter devices.',
      );
    }
    // This runs before any build, install, launch or cleanup command.
    requireVirtualTestDevice(selected.single, platform);
    late String artifact;
    if (platform == 'ios') {
      await flutter([
        'build',
        'ios',
        '--simulator',
        '--debug',
        '--flavor',
        'uitest',
        '--target',
        target,
      ]);
      artifact = 'build/ios/iphonesimulator/Runner.app';
      requireTestApplicationId(
        await readCommand('/usr/bin/plutil', [
          '-extract',
          'CFBundleIdentifier',
          'raw',
          '-o',
          '-',
          '$artifact/Info.plist',
        ]),
      );
    } else {
      await flutter(['build', 'apk', '--debug', '--target', target]);
      artifact = 'build/app/outputs/flutter-apk/app-debug.apk';
      requireTestApplicationId(
        androidApplicationId(
          await readCommand(await aaptPath(), ['dump', 'badging', artifact]),
        ),
      );
    }
    // Freeze the verified artifact so a concurrent normal build cannot replace it.
    staging = await Directory.systemTemp.createTemp('tiko-uitest-artifact-');
    if (platform == 'ios') {
      final copy = '${staging.path}/Runner.app';
      await readCommand('/usr/bin/ditto', [artifact, copy]);
      artifact = copy;
      requireTestApplicationId(
        await readCommand('/usr/bin/plutil', [
          '-extract',
          'CFBundleIdentifier',
          'raw',
          '-o',
          '-',
          '$artifact/Info.plist',
        ]),
      );
    } else {
      artifact = (await File(artifact).copy('${staging.path}/uitest.apk')).path;
      requireTestApplicationId(
        androidApplicationId(
          await readCommand(await aaptPath(), ['dump', 'badging', artifact]),
        ),
      );
    }
    stdout.writeln(
      'Verified isolated app $uiTestApplicationId on virtual device $id.',
    );
    await flutter([
      'drive',
      '--debug',
      if (platform == 'ios') ...['--flavor', 'uitest'],
      '--use-application-binary=$artifact',
      '--driver=test_driver/integration_test.dart',
      '--target=$target',
      '-d',
      id,
      '--no-pub',
    ]);
  } catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  } finally {
    if (staging != null) await staging.delete(recursive: true);
  }
}
