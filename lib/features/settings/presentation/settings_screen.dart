part of '../../../main.dart';

final preferencesProvider =
    NotifierProvider<PreferencesController, AppPreferences>(
      PreferencesController.new,
    );

class PreferencesController extends Notifier<AppPreferences> {
  @override
  AppPreferences build() => AppPreferences();
  Future<void> load() async {
    final value = await PreferencesRepository(
      ref.read(databaseProvider),
    ).load();
    state = value;
  }

  Future<void> save(AppPreferences preferences) async {
    await PreferencesRepository(ref.read(databaseProvider)).save(preferences);
    state = preferences;
  }
}

class Bootstrap extends ConsumerStatefulWidget {
  const Bootstrap({super.key});
  @override
  ConsumerState<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends ConsumerState<Bootstrap> {
  late Future<void> load;
  @override
  void initState() {
    super.initState();
    load = ref.read(preferencesProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: load,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return TikoApp();
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: [Locale('en'), Locale('ro')],
        theme: tikoTheme(Brightness.light),
        darkTheme: tikoTheme(Brightness.dark),
        home: Builder(
          builder: (context) => Scaffold(
            body: snapshot.hasError
                ? Center(
                    child: TextButton(
                      onPressed: () => setState(
                        () => load = ref
                            .read(preferencesProvider.notifier)
                            .load(),
                      ),
                      child: Text(context.l10n.openError),
                    ),
                  )
                : BrandLoading(),
          ),
        ),
      );
    },
  );
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool busy = false;
  Future<void> save(AppPreferences preferences) async {
    setState(() => busy = true);
    try {
      await ref.read(preferencesProvider.notifier).save(preferences);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.couldNotSaveSettingsPleaseRetry)),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferences = ref.watch(preferencesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings)),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Row(
            children: [
              BrandMark(),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiko',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(context.l10n.everyUseCounts),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 32),
          DropdownButtonFormField<String>(
            key: ValueKey('theme:${preferences.theme}'),
            initialValue: preferences.theme,
            decoration: InputDecoration(labelText: context.l10n.appearance),
            items: [
              DropdownMenuItem(
                value: 'system',
                child: Text(context.l10n.system),
              ),
              DropdownMenuItem(value: 'light', child: Text(context.l10n.light)),
              DropdownMenuItem(value: 'dark', child: Text(context.l10n.dark)),
            ],
            onChanged: busy
                ? null
                : (value) => save(preferences.copyWith(theme: value)),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey('language:${preferences.language}'),
            initialValue: preferences.language,
            decoration: InputDecoration(labelText: context.l10n.language),
            items: [
              DropdownMenuItem(
                value: 'system',
                child: Text(context.l10n.system),
              ),
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'ro', child: Text('Română')),
            ],
            onChanged: busy
                ? null
                : (value) => save(preferences.copyWith(language: value)),
          ),
          SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.hapticFeedback),
            subtitle: Text(context.l10n.aGentleTapWhenUsageIsRecorded),
            value: preferences.haptics,
            onChanged: busy
                ? null
                : (value) => save(preferences.copyWith(haptics: value)),
          ),
          Divider(height: 32),
          Text(
            context.l10n.yourData,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            context
                .l10n
                .everythingStaysOnThisDeviceSaveABackupBeforeChangingPhones,
          ),
          SizedBox(height: 16),
          BackupActions(),
          SizedBox(height: 24),
          Text(context.l10n.tiko10WorksEntirelyOffline),
        ],
      ),
    );
  }
}
