import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Directory(
    Platform.environment['TIKO_SCREENSHOT_DIR'] ??
        '${Directory.systemTemp.path}/tiko-phone-review',
  );
  await output.create(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final filename = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      await File('${output.path}/$filename.png').writeAsBytes(bytes);
      return true;
    },
    responseDataCallback: (data) async {
      await File('${output.path}/results.json').writeAsString(jsonEncode(data));
    },
  );
}
