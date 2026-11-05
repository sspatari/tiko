import '../../../core/database/database.dart';

class AppPreferences {
  const AppPreferences({
    this.theme = 'system',
    this.language = 'system',
    this.haptics = true,
  });
  final String theme;
  final String language;
  final bool haptics;
  AppPreferences copyWith({String? theme, String? language, bool? haptics}) =>
      AppPreferences(
        theme: theme ?? this.theme,
        language: language ?? this.language,
        haptics: haptics ?? this.haptics,
      );
  Map<String, Object> toJson() => {
    'theme': theme,
    'language': language,
    'haptics': haptics,
  };
  factory AppPreferences.fromJson(Map<String, dynamic> data) {
    if (!['system', 'light', 'dark'].contains(data['theme']) ||
        !['system', 'en', 'ro'].contains(data['language']) ||
        data['haptics'] is! bool) {
      throw const FormatException('Invalid preferences');
    }
    return AppPreferences(
      theme: data['theme'] as String,
      language: data['language'] as String,
      haptics: data['haptics'] as bool,
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
