import '../../../core/database/database.dart';

class AppPreferences {
  const AppPreferences({
    this.theme = 'system',
    this.language = 'system',
    this.haptics = true,
    this.expiryReminders = false,
  });
  final String theme;
  final String language;
  final bool haptics;
  final bool expiryReminders;
  AppPreferences copyWith({
    String? theme,
    String? language,
    bool? haptics,
    bool? expiryReminders,
  }) => AppPreferences(
    theme: theme ?? this.theme,
    language: language ?? this.language,
    haptics: haptics ?? this.haptics,
    expiryReminders: expiryReminders ?? this.expiryReminders,
  );
  Map<String, Object> toJson() => {
    'theme': theme,
    'language': language,
    'haptics': haptics,
    'expiryReminders': expiryReminders,
  };
  factory AppPreferences.fromJson(Map<String, dynamic> data) {
    if (!['system', 'light', 'dark'].contains(data['theme']) ||
        !['system', 'en', 'ro'].contains(data['language']) ||
        data['haptics'] is! bool ||
        (data.containsKey('expiryReminders') &&
            data['expiryReminders'] is! bool)) {
      throw const FormatException('Invalid preferences');
    }
    return AppPreferences(
      theme: data['theme'] as String,
      language: data['language'] as String,
      haptics: data['haptics'] as bool,
      expiryReminders: data['expiryReminders'] as bool? ?? false,
    );
  }
}

class PreferencesRepository {
  PreferencesRepository(this.database);
  final TikoDatabase database;
  Future<AppPreferences> load() async {
    final rows = await database.select(database.appSettings).get();
    final values = {for (final row in rows) row.key: row.value};
    return AppPreferences.fromJson({
      'theme': values['theme'] ?? 'system',
      'language': values['language'] ?? 'system',
      'haptics': values['haptics'] != 'false',
      'expiryReminders': values['expiryReminders'] == 'true',
    });
  }

  Future<void> save(AppPreferences preferences) =>
      database.transaction(() async {
        for (final entry in preferences.toJson().entries) {
          await database
              .into(database.appSettings)
              .insertOnConflictUpdate(
                AppSettingsCompanion.insert(
                  key: entry.key,
                  value: entry.value.toString(),
                ),
              );
        }
      });
}
