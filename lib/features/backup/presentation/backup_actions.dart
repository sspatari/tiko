part of '../../../main.dart';

Future<void> shareExport(
  BuildContext context,
  String content,
  String name,
  String mimeType,
) async {
  final box = context.findRenderObject() as RenderBox?;
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          Uint8List.fromList(utf8.encode(content)),
          mimeType: mimeType,
          name: name,
        ),
      ],
      fileNameOverrides: [name],
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}

class BackupActions extends ConsumerStatefulWidget {
  const BackupActions({super.key});
  @override
  ConsumerState<BackupActions> createState() => _BackupActionsState();
}

class _BackupActionsState extends ConsumerState<BackupActions> {
  bool busy = false;
  Future<void> run(String action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final repository = BackupRepository(ref.read(databaseProvider));
      if (action == 'json') {
        final json = await repository.exportJson();
        if (mounted) {
          await shareExport(
            context,
            json,
            'tiko-backup.json',
            'application/json',
          );
        }
      } else if (action == 'csv') {
        final csv = await repository.exportCsv();
        if (mounted) {
          await shareExport(context, csv, 'tiko-history.csv', 'text/csv');
        }
      } else {
        final file = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
          withData: true,
        );
        if (file == null || !mounted) return;
        final bytes = file.files.single.bytes;
        if (bytes == null) throw FormatException('Could not read backup file');
        final backup = BackupRepository.decode(utf8.decode(bytes));
        if (!mounted) return;
        final confirmed = await confirmAction(
          context,
          context.l10n.importBackup,
          context.l10n.importPreview(
            backup.subscriptions.length,
            backup.events.length,
          ),
          context.l10n.import,
        );
        if (!confirmed || !mounted) return;
        final result = await repository.restore(backup);
        await ref.read(preferencesProvider.notifier).load();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.importSummary(result.added, result.skipped),
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is FormatException
                  ? context.l10n.invalidOrConflictingBackupNothingWasImported
                  : context.l10n.couldNotCompleteExportOrImportPleaseRetry,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OutlinedButton.icon(
        onPressed: busy ? null : () => run('json'),
        icon: Icon(Icons.ios_share),
        label: Text(context.l10n.exportJSONBackup),
      ),
      OutlinedButton.icon(
        onPressed: busy ? null : () => run('import'),
        icon: Icon(Icons.file_open_outlined),
        label: Text(context.l10n.importJSONBackup),
      ),
      OutlinedButton.icon(
        onPressed: busy ? null : () => run('csv'),
        icon: Icon(Icons.table_chart_outlined),
        label: Text(context.l10n.exportUsageCSV),
      ),
      if (busy)
        Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
    ],
  );
}
