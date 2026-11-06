const uiTestApplicationId = 'com.sspatari.tiko.uitest';

void requireVirtualTestDevice(Map<String, dynamic> device, String platform) {
  final target = device['targetPlatform'];
  final matches = platform == 'ios'
      ? target == 'ios'
      : target is String && target.startsWith('android');
  if (device['emulator'] != true || !matches) {
    throw StateError(
      'UI review only supports iOS simulators and Android emulators. Physical devices are refused.',
    );
  }
}

void requireTestApplicationId(String identifier) {
  if (identifier.trim() != uiTestApplicationId) {
    throw StateError(
      'Refusing deployment: expected $uiTestApplicationId, got $identifier.',
    );
  }
}

String androidApplicationId(String badging) {
  final match = RegExp(
    r"^package: name='([^']+)'",
    multiLine: true,
  ).firstMatch(badging);
  if (match == null) {
    throw const FormatException('Cannot verify APK application ID.');
  }
  return match.group(1)!;
}
