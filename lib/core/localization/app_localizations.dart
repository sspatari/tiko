import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ro.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ro'),
  ];

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @everyUseCounts.
  ///
  /// In en, this message translates to:
  /// **'Every use counts.'**
  String get everyUseCounts;

  /// No description provided for @usageHistory.
  ///
  /// In en, this message translates to:
  /// **'Usage history'**
  String get usageHistory;

  /// No description provided for @createCounter.
  ///
  /// In en, this message translates to:
  /// **'Create counter'**
  String get createCounter;

  /// No description provided for @detailsHistory.
  ///
  /// In en, this message translates to:
  /// **'Details & history'**
  String get detailsHistory;

  /// No description provided for @couldNotLoadCounters.
  ///
  /// In en, this message translates to:
  /// **'Could not load counters.'**
  String get couldNotLoadCounters;

  /// No description provided for @couldNotLoadUsage.
  ///
  /// In en, this message translates to:
  /// **'Could not load usage.'**
  String get couldNotLoadUsage;

  /// No description provided for @makeEveryUseCount.
  ///
  /// In en, this message translates to:
  /// **'Make every use count'**
  String get makeEveryUseCount;

  /// No description provided for @createACounterForYourPassMembershipOrPrepaidService.
  ///
  /// In en, this message translates to:
  /// **'Create a counter for your pass, membership, or prepaid service.'**
  String get createACounterForYourPassMembershipOrPrepaidService;

  /// No description provided for @noUsesRecordedYet.
  ///
  /// In en, this message translates to:
  /// **'No uses recorded yet'**
  String get noUsesRecordedYet;

  /// No description provided for @outsideValidityPeriod.
  ///
  /// In en, this message translates to:
  /// **'Outside validity period'**
  String get outsideValidityPeriod;

  /// No description provided for @recordThisUseAnyway.
  ///
  /// In en, this message translates to:
  /// **'Record this use anyway?'**
  String get recordThisUseAnyway;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @recordUse.
  ///
  /// In en, this message translates to:
  /// **'Record use'**
  String get recordUse;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @couldNotUndoPleaseRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not undo. Please retry.'**
  String get couldNotUndoPleaseRetry;

  /// No description provided for @couldNotSaveThisUsePleaseRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not save this use. Please retry.'**
  String get couldNotSaveThisUsePleaseRetry;

  /// No description provided for @label1USE.
  ///
  /// In en, this message translates to:
  /// **'+1 USE'**
  String get label1USE;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @allSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'All subscriptions'**
  String get allSubscriptions;

  /// No description provided for @allDates.
  ///
  /// In en, this message translates to:
  /// **'All dates'**
  String get allDates;

  /// No description provided for @clearDateFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear date filter'**
  String get clearDateFilter;

  /// No description provided for @subscriptionNoLongerExistsSelectAnotherSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription no longer exists. Select another subscription.'**
  String get subscriptionNoLongerExistsSelectAnotherSubscription;

  /// No description provided for @couldNotLoadHistoryTapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not load history. Tap to retry.'**
  String get couldNotLoadHistoryTapToRetry;

  /// No description provided for @noUsageEventsForTheseFilters.
  ///
  /// In en, this message translates to:
  /// **'No usage events for these filters.'**
  String get noUsageEventsForTheseFilters;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @subscriptionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Subscription unavailable'**
  String get subscriptionUnavailable;

  /// No description provided for @eventActions.
  ///
  /// In en, this message translates to:
  /// **'Event actions'**
  String get eventActions;

  /// No description provided for @editEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get editEvent;

  /// No description provided for @deleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Delete event'**
  String get deleteEvent;

  /// No description provided for @deleteEventLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete event?'**
  String get deleteEventLabel;

  /// No description provided for @thisUsageEventWillBePermanentlyDeleted.
  ///
  /// In en, this message translates to:
  /// **'This usage event will be permanently deleted.'**
  String get thisUsageEventWillBePermanentlyDeleted;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @couldNotDeleteEventPleaseRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not delete event. Please retry.'**
  String get couldNotDeleteEventPleaseRetry;

  /// No description provided for @addForgottenUse.
  ///
  /// In en, this message translates to:
  /// **'Add forgotten use'**
  String get addForgottenUse;

  /// No description provided for @editUsageEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit usage event'**
  String get editUsageEvent;

  /// No description provided for @couldNotLoadSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Could not load subscriptions.'**
  String get couldNotLoadSubscriptions;

  /// No description provided for @createOrRestoreASubscriptionBeforeAddingUsage.
  ///
  /// In en, this message translates to:
  /// **'Create or restore a subscription before adding usage.'**
  String get createOrRestoreASubscriptionBeforeAddingUsage;

  /// No description provided for @chooseASubscription.
  ///
  /// In en, this message translates to:
  /// **'Choose a subscription'**
  String get chooseASubscription;

  /// No description provided for @restoreThisSubscriptionBeforeAddingUsage.
  ///
  /// In en, this message translates to:
  /// **'Restore this subscription before adding usage.'**
  String get restoreThisSubscriptionBeforeAddingUsage;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @enterAPositiveWholeNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive whole number'**
  String get enterAPositiveWholeNumber;

  /// No description provided for @noteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteOptional;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @saveEvent.
  ///
  /// In en, this message translates to:
  /// **'Save event'**
  String get saveEvent;

  /// No description provided for @couldNotSaveEventPleaseRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not save event. Please retry.'**
  String get couldNotSaveEventPleaseRetry;

  /// No description provided for @thisDateIsOutsideTheSubscriptionValidityPeriodSaveThisUseAnyway.
  ///
  /// In en, this message translates to:
  /// **'This date is outside the subscription validity period. Save this use anyway?'**
  String get thisDateIsOutsideTheSubscriptionValidityPeriodSaveThisUseAnyway;

  /// No description provided for @saveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get saveAnyway;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @noExpiration.
  ///
  /// In en, this message translates to:
  /// **'No expiration'**
  String get noExpiration;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get manageSubscription;

  /// No description provided for @editSubscription.
  ///
  /// In en, this message translates to:
  /// **'Edit subscription'**
  String get editSubscription;

  /// No description provided for @renewSubscription.
  ///
  /// In en, this message translates to:
  /// **'Renew subscription'**
  String get renewSubscription;

  /// No description provided for @restoreSubscription.
  ///
  /// In en, this message translates to:
  /// **'Restore subscription'**
  String get restoreSubscription;

  /// No description provided for @archiveSubscription.
  ///
  /// In en, this message translates to:
  /// **'Archive subscription'**
  String get archiveSubscription;

  /// No description provided for @deleteSubscription.
  ///
  /// In en, this message translates to:
  /// **'Delete subscription'**
  String get deleteSubscription;

  /// No description provided for @deleteSubscriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete subscription?'**
  String get deleteSubscriptionLabel;

  /// No description provided for @couldNotSaveChangesPleaseRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not save changes. Please retry.'**
  String get couldNotSaveChangesPleaseRetry;

  /// No description provided for @couldNotLoadSubscription.
  ///
  /// In en, this message translates to:
  /// **'Could not load subscription.'**
  String get couldNotLoadSubscription;

  /// No description provided for @subscriptionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Subscription not found.'**
  String get subscriptionNotFound;

  /// No description provided for @prepaidCost.
  ///
  /// In en, this message translates to:
  /// **'Prepaid cost'**
  String get prepaidCost;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDate;

  /// No description provided for @averageCostPerUse.
  ///
  /// In en, this message translates to:
  /// **'Average cost per use'**
  String get averageCostPerUse;

  /// No description provided for @noUsesYet.
  ///
  /// In en, this message translates to:
  /// **'No uses yet'**
  String get noUsesYet;

  /// No description provided for @singleUsePrice.
  ///
  /// In en, this message translates to:
  /// **'Single-use price'**
  String get singleUsePrice;

  /// No description provided for @equivalentIndividualCost.
  ///
  /// In en, this message translates to:
  /// **'Equivalent individual cost'**
  String get equivalentIndividualCost;

  /// No description provided for @unrecoveredCost.
  ///
  /// In en, this message translates to:
  /// **'Unrecovered cost'**
  String get unrecoveredCost;

  /// No description provided for @netSavings.
  ///
  /// In en, this message translates to:
  /// **'Net savings'**
  String get netSavings;

  /// No description provided for @breakEvenThreshold.
  ///
  /// In en, this message translates to:
  /// **'Break-even threshold'**
  String get breakEvenThreshold;

  /// No description provided for @remainingUntilBreakEven.
  ///
  /// In en, this message translates to:
  /// **'Remaining until break-even'**
  String get remainingUntilBreakEven;

  /// No description provided for @breakEvenProgress.
  ///
  /// In en, this message translates to:
  /// **'Break-even progress'**
  String get breakEvenProgress;

  /// No description provided for @savingsPercentage.
  ///
  /// In en, this message translates to:
  /// **'Savings percentage'**
  String get savingsPercentage;

  /// No description provided for @relatedSubscriptionPeriods.
  ///
  /// In en, this message translates to:
  /// **'Related subscription periods'**
  String get relatedSubscriptionPeriods;

  /// No description provided for @recentUsage.
  ///
  /// In en, this message translates to:
  /// **'Recent usage'**
  String get recentUsage;

  /// No description provided for @viewFullHistory.
  ///
  /// In en, this message translates to:
  /// **'View full history'**
  String get viewFullHistory;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @enterAName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get enterAName;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total price'**
  String get totalPrice;

  /// No description provided for @enterAValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get enterAValidPrice;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @singleUsePriceOptional.
  ///
  /// In en, this message translates to:
  /// **'Single-use price (optional)'**
  String get singleUsePriceOptional;

  /// No description provided for @enterAPositivePrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive price'**
  String get enterAPositivePrice;

  /// No description provided for @endDateOptional.
  ///
  /// In en, this message translates to:
  /// **'End date (optional)'**
  String get endDateOptional;

  /// No description provided for @clearEndDate.
  ///
  /// In en, this message translates to:
  /// **'Clear end date'**
  String get clearEndDate;

  /// No description provided for @renew.
  ///
  /// In en, this message translates to:
  /// **'Renew'**
  String get renew;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @couldNotSaveCounterPleaseRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not save counter. Please retry.'**
  String get couldNotSaveCounterPleaseRetry;

  /// No description provided for @createASubscriptionAndRecordAUseToSeeYourPatterns.
  ///
  /// In en, this message translates to:
  /// **'Create a subscription and record a use to see your patterns.'**
  String get createASubscriptionAndRecordAUseToSeeYourPatterns;

  /// No description provided for @totalRecordedUsage.
  ///
  /// In en, this message translates to:
  /// **'Total recorded usage'**
  String get totalRecordedUsage;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @last12Weeks.
  ///
  /// In en, this message translates to:
  /// **'Last 12 weeks'**
  String get last12Weeks;

  /// No description provided for @lighterSquaresIndicateFewerUsesTapASquareForItsDate.
  ///
  /// In en, this message translates to:
  /// **'Lighter squares indicate fewer uses. Tap a square for its date.'**
  String get lighterSquaresIndicateFewerUsesTapASquareForItsDate;

  /// No description provided for @actualResults.
  ///
  /// In en, this message translates to:
  /// **'Actual results'**
  String get actualResults;

  /// No description provided for @averageUsesPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Average uses per week'**
  String get averageUsesPerWeek;

  /// No description provided for @averageUsesPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Average uses per month'**
  String get averageUsesPerMonth;

  /// No description provided for @daysSinceLastUse.
  ///
  /// In en, this message translates to:
  /// **'Days since last use'**
  String get daysSinceLastUse;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @projections.
  ///
  /// In en, this message translates to:
  /// **'Projections'**
  String get projections;

  /// No description provided for @estimatesFollowYourAveragePaceDuringValidityTheyAreNotGuaranteed.
  ///
  /// In en, this message translates to:
  /// **'Estimates follow your average pace during validity. They are not guaranteed.'**
  String get estimatesFollowYourAveragePaceDuringValidityTheyAreNotGuaranteed;

  /// No description provided for @estimatedBreakEvenDate.
  ///
  /// In en, this message translates to:
  /// **'Estimated break-even date'**
  String get estimatedBreakEvenDate;

  /// No description provided for @alreadyReached.
  ///
  /// In en, this message translates to:
  /// **'Already reached'**
  String get alreadyReached;

  /// No description provided for @notEnoughActivity.
  ///
  /// In en, this message translates to:
  /// **'Not enough activity'**
  String get notEnoughActivity;

  /// No description provided for @atThisPaceBreakEvenIsAfterExpiration.
  ///
  /// In en, this message translates to:
  /// **'At this pace, break-even is after expiration.'**
  String get atThisPaceBreakEvenIsAfterExpiration;

  /// No description provided for @projectedCostPerUseAtExpiration.
  ///
  /// In en, this message translates to:
  /// **'Projected cost per use at expiration'**
  String get projectedCostPerUseAtExpiration;

  /// No description provided for @projectionsNeed7DaysOfHistoryWithActivityOnAtLeast3DatesExpiredAndArchivedP.
  ///
  /// In en, this message translates to:
  /// **'Projections need 7 days of history with activity on at least 3 dates. Expired and archived periods are not forecast.'**
  String
  get projectionsNeed7DaysOfHistoryWithActivityOnAtLeast3DatesExpiredAndArchivedP;

  /// No description provided for @chooseASubscriptionForFinancialResultsAndProjections.
  ///
  /// In en, this message translates to:
  /// **'Choose a subscription for financial results and projections.'**
  String get chooseASubscriptionForFinancialResultsAndProjections;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @hapticFeedback.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get hapticFeedback;

  /// No description provided for @aGentleTapWhenUsageIsRecorded.
  ///
  /// In en, this message translates to:
  /// **'A gentle tap when usage is recorded'**
  String get aGentleTapWhenUsageIsRecorded;

  /// No description provided for @yourData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get yourData;

  /// No description provided for @everythingStaysOnThisDeviceSaveABackupBeforeChangingPhones.
  ///
  /// In en, this message translates to:
  /// **'Everything stays on this device. Save a backup before changing phones.'**
  String get everythingStaysOnThisDeviceSaveABackupBeforeChangingPhones;

  /// No description provided for @tiko10WorksEntirelyOffline.
  ///
  /// In en, this message translates to:
  /// **'Tiko 1.0 · Works entirely offline'**
  String get tiko10WorksEntirelyOffline;

  /// No description provided for @couldNotSaveSettingsPleaseRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not save settings. Please retry.'**
  String get couldNotSaveSettingsPleaseRetry;

  /// No description provided for @exportJSONBackup.
  ///
  /// In en, this message translates to:
  /// **'Export JSON backup'**
  String get exportJSONBackup;

  /// No description provided for @importJSONBackup.
  ///
  /// In en, this message translates to:
  /// **'Import JSON backup'**
  String get importJSONBackup;

  /// No description provided for @exportUsageCSV.
  ///
  /// In en, this message translates to:
  /// **'Export usage CSV'**
  String get exportUsageCSV;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import backup?'**
  String get importBackup;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @couldNotCompleteExportOrImportPleaseRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not complete export or import. Please retry.'**
  String get couldNotCompleteExportOrImportPleaseRetry;

  /// No description provided for @invalidOrConflictingBackupNothingWasImported.
  ///
  /// In en, this message translates to:
  /// **'Invalid or conflicting backup. Nothing was imported.'**
  String get invalidOrConflictingBackupNothingWasImported;

  /// No description provided for @averageCostOverTime.
  ///
  /// In en, this message translates to:
  /// **'Average cost over time'**
  String get averageCostOverTime;

  /// No description provided for @archivedSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Archived subscriptions'**
  String get archivedSubscriptions;

  /// No description provided for @starterTemplateOptional.
  ///
  /// In en, this message translates to:
  /// **'Starter template (optional)'**
  String get starterTemplateOptional;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @trolleybus.
  ///
  /// In en, this message translates to:
  /// **'Trolleybus'**
  String get trolleybus;

  /// No description provided for @gym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get gym;

  /// No description provided for @uses.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 use} other{{count} uses}}'**
  String uses(int count);

  /// No description provided for @remainingUses.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 use until break-even} other{{count} uses until break-even}}'**
  String remainingUses(int count);

  /// No description provided for @costPerUse.
  ///
  /// In en, this message translates to:
  /// **'{amount} / use'**
  String costPerUse(String amount);

  /// No description provided for @prepaid.
  ///
  /// In en, this message translates to:
  /// **'{amount} prepaid'**
  String prepaid(String amount);

  /// No description provided for @recordedAt.
  ///
  /// In en, this message translates to:
  /// **'Recorded at {time}'**
  String recordedAt(String time);

  /// No description provided for @todayDate.
  ///
  /// In en, this message translates to:
  /// **'Today · {date}'**
  String todayDate(String date);

  /// No description provided for @yesterdayDate.
  ///
  /// In en, this message translates to:
  /// **'Yesterday · {date}'**
  String yesterdayDate(String date);

  /// No description provided for @startsOn.
  ///
  /// In en, this message translates to:
  /// **'Starts {date}'**
  String startsOn(String date);

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String expiresOn(String date);

  /// No description provided for @expiredOn.
  ///
  /// In en, this message translates to:
  /// **'Expired {date}'**
  String expiredOn(String date);

  /// No description provided for @importSummary.
  ///
  /// In en, this message translates to:
  /// **'Imported {added} records; skipped {skipped} existing records.'**
  String importSummary(int added, int skipped);

  /// No description provided for @importPreview.
  ///
  /// In en, this message translates to:
  /// **'{subscriptions} subscriptions and {events} events. Existing identical records will be skipped. Conflicting IDs reject the whole import. Appearance, language and haptics will also be restored.'**
  String importPreview(int subscriptions, int events);

  /// No description provided for @deleteSubscriptionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Delete {name} and all its usage events? Other renewal periods will be preserved.'**
  String deleteSubscriptionPrompt(String name);

  /// No description provided for @archivedName.
  ///
  /// In en, this message translates to:
  /// **'{name} (archived)'**
  String archivedName(String name);

  /// No description provided for @chartTooltip.
  ///
  /// In en, this message translates to:
  /// **'{date}: {count, plural, one{1 use} other{{count} uses}}'**
  String chartTooltip(String date, int count);

  /// No description provided for @teal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get teal;

  /// No description provided for @indigo.
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get indigo;

  /// No description provided for @violet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get violet;

  /// No description provided for @amber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get amber;

  /// No description provided for @red.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get red;

  /// No description provided for @ticketIcon.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get ticketIcon;

  /// No description provided for @fitnessIcon.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get fitnessIcon;

  /// No description provided for @bookIcon.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get bookIcon;

  /// No description provided for @coffeeIcon.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get coffeeIcon;

  /// No description provided for @travelIcon.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get travelIcon;

  /// No description provided for @otherIcon.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherIcon;

  /// No description provided for @openError.
  ///
  /// In en, this message translates to:
  /// **'Could not open Tiko. Tap to retry.'**
  String get openError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ro'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ro':
      return AppLocalizationsRo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
