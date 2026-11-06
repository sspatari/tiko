part of '../main.dart';

ThemeData tikoTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: Color(0xff006B5E),
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? Color(0xff101816) : Color(0xffF5F8F6),
    appBarTheme: AppBarTheme(
      systemOverlayStyle: dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: dark ? Color(0xff192420) : Colors.white,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      errorMaxLines: 3,
      helperMaxLines: 3,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      fillColor: scheme.surfaceContainerLowest,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? Color(0xff101816) : Color(0xffF5F8F6),
      elevation: 0,
      indicatorColor: scheme.primaryContainer,
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: .45),
      thickness: 1,
    ),
    textTheme: ThemeData(brightness: brightness).textTheme.copyWith(
      displaySmall: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -.5,
      ),
    ),
  );
}

class SubscriptionStatusBadge extends ConsumerWidget {
  const SubscriptionStatusBadge({super.key, required this.subscription});
  final Subscription subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = subscriptionLifecycle(
      startDate: subscription.startDate,
      endDate: subscription.endDate,
      archived: subscription.isArchived,
      today: ref.watch(currentLocalDateProvider),
    );
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final (label, icon) = switch (status) {
      SubscriptionLifecycle.active => (
        context.l10n.activeStatus,
        Icons.check_circle_outline,
      ),
      SubscriptionLifecycle.expiringSoon => (
        context.l10n.expiresSoonStatus,
        Icons.schedule,
      ),
      SubscriptionLifecycle.upcoming => (
        context.l10n.upcomingStatus,
        Icons.event_outlined,
      ),
      SubscriptionLifecycle.expired => (
        context.l10n.expiredStatus,
        Icons.event_busy_outlined,
      ),
      SubscriptionLifecycle.archived => (
        context.l10n.archived,
        Icons.archive_outlined,
      ),
    };
    final (background, foreground) = switch (status) {
      SubscriptionLifecycle.active => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      SubscriptionLifecycle.expiringSoon => (
        dark ? Color(0xff49371b) : Color(0xffffefd1),
        dark ? Color(0xffffe0a0) : Color(0xff6e4700),
      ),
      SubscriptionLifecycle.upcoming => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedUsageTotal extends StatelessWidget {
  const AnimatedUsageTotal({super.key, required this.uses, this.style});
  final int uses;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      context.l10n.uses(uses),
      key: ValueKey(uses),
      style: style ?? Theme.of(context).textTheme.displaySmall,
    );
    return Semantics(
      liveRegion: true,
      label: context.l10n.uses(uses),
      excludeSemantics: true,
      child: MediaQuery.disableAnimationsOf(context)
          ? text
          : AnimatedSwitcher(
              duration: Duration(milliseconds: 180),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.centerLeft,
                children: [...previous, ?current],
              ),
              child: text,
            ),
    );
  }
}

class UsageProgress extends StatelessWidget {
  const UsageProgress({super.key, required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);
    return Semantics(
      label: context.l10n.breakEvenProgress,
      value: NumberFormat.percentPattern().format(value),
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: progress, end: progress),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : Duration(milliseconds: 220),
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class FormSectionHeading extends StatelessWidget {
  const FormSectionHeading({
    super.key,
    required this.icon,
    required this.label,
  });
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: 12, bottom: 4),
    child: Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleSmall),
        ),
      ],
    ),
  );
}

class ActionMenuLabel extends StatelessWidget {
  const ActionMenuLabel({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 20, color: foreground),
        SizedBox(width: 12),
        Flexible(
          child: Text(label, style: TextStyle(color: foreground)),
        ),
      ],
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56});
  final double size;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * .24),
    child: Image.asset(
      'assets/brand/tiko.png',
      width: size,
      height: size,
      semanticLabel: 'Tiko',
    ),
  );
}

class BrandLoading extends StatelessWidget {
  const BrandLoading({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: 72),
        SizedBox(height: 24),
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    ),
  );
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late final AppLifecycleListener lifecycle;
  @override
  void initState() {
    super.initState();
    lifecycle = AppLifecycleListener(
      onResume: () {
        ref.read(reminderRefreshProvider.notifier).refresh();
        ref.invalidate(currentLocalDateProvider);
        ref.invalidate(subscriptionsProvider);
        ref.invalidate(totalsProvider);
        ref.invalidate(eventsProvider);
        ref.invalidate(historyProvider);
      },
    );
  }

  @override
  void dispose() {
    lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: widget.navigationShell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: widget.navigationShell.currentIndex,
      onDestinationSelected: (index) => widget.navigationShell.goBranch(
        index,
        initialLocation: index == widget.navigationShell.currentIndex,
      ),
      destinations: [
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: context.l10n.home,
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: context.l10n.analytics,
        ),
        NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: context.l10n.history,
        ),
        NavigationDestination(
          icon: Icon(Icons.tune_outlined),
          selectedIcon: Icon(Icons.tune),
          label: context.l10n.settings,
        ),
      ],
    ),
  );
}

extension LocalizedContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
