// ...existing code...

// Completed lesson count

import 'translations_tr.dart';
import 'translations_en.dart';
import 'translations_es.dart';
import 'translations_nl.dart';
import '../models/lesson_reason.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  String get editMeasurement => get('editMeasurement');
  // Haftalık plan: Pasif client göster switch'i
  String get showPassiveClients => get('showPassiveClients');
  String get selectReason => get('selectReason');
  // Lesson Reason
  String get reasonResmiTatil => get('reasonResmiTatil');
  String get reasonSporcuHasta => get('reasonSporcuHasta');
  String get reasonTrainerHasta => get('reasonTrainerHasta');
  String get reasonSporcuKisisel => get('reasonSporcuKisisel');
  String get reasonTrainerKisisel => get('reasonTrainerKisisel');
  String get reasonHastalik => get('reasonHastalik');
  String get reasonOther => get('reasonOther');
  String get reasonNoteLabel => get('reasonNoteLabel');
  String get reasonNoteHint => get('reasonNoteHint');
  String completedLessonCount(int count) =>
      get('completedLessonCount').replaceAll('{count}', count.toString());

  String lessonReasonLabel(LessonReason reason) {
    switch (reason) {
      case LessonReason.resmiTatil:
        return reasonResmiTatil;
      case LessonReason.sporcuHasta:
        return reasonSporcuHasta;
      case LessonReason.trainerHasta:
        return reasonTrainerHasta;
      case LessonReason.sporcuKisisel:
        return reasonSporcuKisisel;
      case LessonReason.trainerKisisel:
        return reasonTrainerKisisel;
      case LessonReason.hastalik:
        return reasonHastalik;
      case LessonReason.other:
        return reasonOther;
    }
    // This should never be reached
  }

  // Period sonuna ders ekleme dialogu
  String get addLessonToPeriodEndTitle => get('addLessonToPeriodEndTitle');
  String get addLessonToPeriodEndBody => get('addLessonToPeriodEndBody');
  String get yes => get('yes');
  String get no => get('no');
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('tr'),
    Locale('en'),
    Locale('es'),
    Locale('nl'),
  ];

  late final Map<String, String> _strings = _loadStrings();

  Map<String, String> _loadStrings() {
    switch (locale.languageCode) {
      case 'tr':
        return trStrings;
      case 'es':
        return esStrings;
      case 'nl':
        return nlStrings;
      default:
        return enStrings;
    }
  }

  String get(String key) => _strings[key] ?? key;

  // ── Genel ──
  String get appTitle => get('appTitle');
  String get cancel => get('cancel');
  String get save => get('save');
  String get add => get('add');
  String get update => get('update');
  String get delete => get('delete');
  String get logout => get('logout');
  String get edit => get('edit');
  String get manageAthletesDesc => get('manageAthletesDesc');
  String get weeklyPlanDesc => get('weeklyPlanDesc');

  // ── Auth ──
  String get login => get('login');
  String get register => get('register');
  String get username => get('username');
  String get email => get('email');
  String get password => get('password');
  String get createAccount => get('createAccount');
  String get alreadyHaveAccount => get('alreadyHaveAccount');
  String get usernameEmpty => get('usernameEmpty');
  String get usernameMinLength => get('usernameMinLength');
  String get usernameMaxLength => get('usernameMaxLength');
  String get usernameInvalidChars => get('usernameInvalidChars');
  String get usernameStartsWithNumber => get('usernameStartsWithNumber');
  String get emailEmpty => get('emailEmpty');
  String get emailInvalid => get('emailInvalid');
  String get passwordEmpty => get('passwordEmpty');
  String get passwordMinLength => get('passwordMinLength');
  String get passwordNeedsLowercase => get('passwordNeedsLowercase');
  String get passwordNeedsUppercase => get('passwordNeedsUppercase');
  String get usernameAndPasswordRequired => get('usernameAndPasswordRequired');
  String get invalidCredentials => get('invalidCredentials');
  String get onlyOneUser => get('onlyOneUser');
  String get registrationSuccess => get('registrationSuccess');
  String tooManyAttempts(int seconds) =>
      get('tooManyAttempts').replaceAll('{seconds}', '$seconds');
  String welcome(String name) => get('welcome').replaceAll('{name}', name);
  String get forgotPassword => get('forgotPassword');
  String get securityQuestion => get('securityQuestion');
  String get securityAnswer => get('securityAnswer');
  String get securityQuestionEmpty => get('securityQuestionEmpty');
  String get securityAnswerEmpty => get('securityAnswerEmpty');
  String get securityAnswerWrong => get('securityAnswerWrong');
  String get userNotFound => get('userNotFound');
  String get newPassword => get('newPassword');
  String get resetPassword => get('resetPassword');
  String get passwordResetSuccess => get('passwordResetSuccess');
  String get backToLogin => get('backToLogin');
  String get continueText => get('continueText');

  // ── Home ──
  String get myAthletes => get('myAthletes');
  String get weeklyPlan => get('weeklyPlan');
  String get analysis => get('analysis');
  String get analysisDesc => get('analysisDesc');
  String get analysisComingSoon => get('analysisComingSoon');
  String get analysisPreviewTitle => get('analysisPreviewTitle');
  String get analysisPreviewTeaser => get('analysisPreviewTeaser');
  String get monthlyAnalysisTitle => get('monthlyAnalysisTitle');
  String get monthlyAnalysisNoData => get('monthlyAnalysisNoData');
  String get monthlySelectedMonth => get('monthlySelectedMonth');
  String get selectMonthYear => get('selectMonthYear');
  String get monthlyOverviewTitle => get('monthlyOverviewTitle');
  String get monthlyPaidTotal => get('monthlyPaidTotal');
  String get monthlyExpectedTotal => get('monthlyExpectedTotal');
  String get monthlyCollectionRate => get('monthlyCollectionRate');
  String get monthlyOutstandingAmount => get('monthlyOutstandingAmount');
  String get monthlyInsightsTitle => get('monthlyInsightsTitle');
  String get monthlyChartsTitle => get('monthlyChartsTitle');
  String get monthlyRevenueTrendTitle => get('monthlyRevenueTrendTitle');
  String get monthlyProgramTypeChartTitle =>
      get('monthlyProgramTypeChartTitle');
  String get monthlyChartsEmpty => get('monthlyChartsEmpty');
  String get monthlyTrendPaidLegend => get('monthlyTrendPaidLegend');
  String get monthlyTrendExpectedLegend => get('monthlyTrendExpectedLegend');
  String get monthlyMostCancelledLabel => get('monthlyMostCancelledLabel');
  String get monthlyHighestCancellationRateLabel =>
      get('monthlyHighestCancellationRateLabel');
  String get monthlyCollectionStatusLabel =>
      get('monthlyCollectionStatusLabel');
  String get monthlyStatusStrong => get('monthlyStatusStrong');
  String get monthlyStatusWatch => get('monthlyStatusWatch');
  String get monthlyStatusAttention => get('monthlyStatusAttention');
  String get monthlyNonHolidayCancelCount =>
      get('monthlyNonHolidayCancelCount');
  String get monthlyTopCancellationsTitle =>
      get('monthlyTopCancellationsTitle');
  String get monthlyTopCancellationsEmpty =>
      get('monthlyTopCancellationsEmpty');
  String monthlyTopCancellationMetrics(int count, String share, String rate) =>
      get('monthlyTopCancellationMetrics')
          .replaceAll('{count}', '$count')
          .replaceAll('{share}', share)
          .replaceAll('{rate}', rate);

  // ── Client List ──
  String get noAthletesYet => get('noAthletesYet');
  String get addAthlete => get('addAthlete');
  String packageLabel(int count) =>
      get('packageLabel').replaceAll('{count}', '$count');

  // ── Add Client ──
  String get addNewAthlete => get('addNewAthlete');
  String get fullName => get('fullName');
  String get registrationDate => get('registrationDate');
  String get nameEmpty => get('nameEmpty');
  String get atLeastOneSchedule => get('atLeastOneSchedule');
  String get packageSize => get('packageSize');
  String get packageCountValidation => get('packageCountValidation');
  String get programTypeLabel => get('programTypeLabel');
  String get programTypeSport => get('programTypeSport');
  String get programTypeCourse => get('programTypeCourse');
  String get programTypePersonal => get('programTypePersonal');
  String get packageTypeLabel => get('packageTypeLabel');
  String get packageTypeDaily => get('packageTypeDaily');
  String get packageTypeMonthly => get('packageTypeMonthly');
  String packageOption(int count) =>
      get('packageOption').replaceAll('{count}', '$count');
  String get lessonSchedules => get('lessonSchedules');
  String get addLessonTime => get('addLessonTime');
  String get noScheduleYet => get('noScheduleYet');
  String get saveAthlete => get('saveAthlete');

  // ── Schedule Dialog ──
  String get addLessonTimeTitle => get('addLessonTimeTitle');
  String get selectDay => get('selectDay');
  String get selectTime => get('selectTime');
  String get selectDayFirst => get('selectDayFirst');
  String get scheduleDayAlreadyExists => get('scheduleDayAlreadyExists');

  // ── Days of Week ──
  String get monday => get('monday');
  String get tuesday => get('tuesday');
  String get wednesday => get('wednesday');
  String get thursday => get('thursday');
  String get friday => get('friday');
  String get saturday => get('saturday');
  String get sunday => get('sunday');

  List<String> get daysOfWeek => [
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday,
    sunday,
  ];

  String dayOfWeekByIndex(int weekday) {
    const keys = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    if (weekday >= 1 && weekday <= 7) return get(keys[weekday - 1]);
    return '';
  }

  // ── Client Detail ──
  String get athleteDetail => get('athleteDetail');
  String get editInfo => get('editInfo');
  String get editAthleteInfo => get('editAthleteInfo');
  String get lessonPackage => get('lessonPackage');
  String get firstRegistration => get('firstRegistration');
  String get period => get('period');

  // ── Periods ──
  String get periods => get('periods');
  String get newPeriod => get('newPeriod');
  String get noPeriodYet => get('noPeriodYet');
  String periodNumber(int n) => get('periodNumber').replaceAll('{n}', '$n');
  String lessonsProgress(int attended, int total) => get(
    'lessonsProgress',
  ).replaceAll('{attended}', '$attended').replaceAll('{total}', '$total');
  String get postponed => get('postponed');
  String get noPaymentInfo => get('noPaymentInfo');
  String paymentPaid(String amount) =>
      get('paymentPaid').replaceAll('{amount}', amount);
  String paymentPending(String amount) =>
      get('paymentPending').replaceAll('{amount}', amount);
  String get payment => get('payment');
  String get calendar => get('calendar');

  // ── Add Period Dialog ──
  String get addNewPeriod => get('addNewPeriod');
  String get selectStartDate => get('selectStartDate');
  String startDateLabel(String date) =>
      get('startDateLabel').replaceAll('{date}', date);
  String get selectEndDate => get('selectEndDate');
  String endDateLabel(String date) =>
      get('endDateLabel').replaceAll('{date}', date);
  String get paymentAmount => get('paymentAmount');
  String get paymentReceived => get('paymentReceived');

  // ── Period Detail Dialog ──
  String get periodDetail => get('periodDetail');
  String startInfo(String date) => get('startInfo').replaceAll('{date}', date);
  String endInfo(String date) => get('endInfo').replaceAll('{date}', date);
  String postponedInfo(String date) =>
      get('postponedInfo').replaceAll('{date}', date);
  String get paymentInfo => get('paymentInfo');
  String get paymentCompleted => get('paymentCompleted');
  String get paymentAwaiting => get('paymentAwaiting');

  // ── Schedules ──
  String get lessonTimes => get('lessonTimes');
  String get noScheduleAdded => get('noScheduleAdded');
  String get editLessonTime => get('editLessonTime');
  String get updateLessonTimes => get('updateLessonTimes');
  String get day => get('day');
  String timeLabel(String time) => get('timeLabel').replaceAll('{time}', time);

  // ── Body Measurements ──
  String get bodyMeasurements => get('bodyMeasurements');
  String get addMeasurement => get('addMeasurement');
  String get noMeasurementYet => get('noMeasurementYet');
  String get chest => get('chest');
  String get waist => get('waist');
  String get hips => get('hips');
  String dateLabel(String date) => get('dateLabel').replaceAll('{date}', date);
  String get atLeastOneMeasurement => get('atLeastOneMeasurement');
  String get saveMeasurement => get('saveMeasurement');
  String get selectDate => get('selectDate');
  String get measurementSection => get('measurementSection');

  // ── Period Calendar ──
  String get periodCalendar => get('periodCalendar');
  String get postponedBadge => get('postponedBadge');
  String get cancelLesson => get('cancelLesson');
  String cancelLessonBody(String date) =>
      get('cancelLessonBody').replaceAll('{date}', date);
  String get giveUp => get('giveUp');
  String get confirmCancel => get('confirmCancel');
  String get undoCancel => get('undoCancel');
  String undoCancelBody(String date) =>
      get('undoCancelBody').replaceAll('{date}', date);
  String get confirmUndo => get('confirmUndo');
  String get cancelled => get('cancelled');
  String makeupLabel(String date) =>
      get('makeupLabel').replaceAll('{date}', date);
  String get postponedLesson => get('postponedLesson');
  String get selectMakeupDate => get('selectMakeupDate');
  String get undoCancelTooltip => get('undoCancelTooltip');
  String get cancelAndPostpone => get('cancelAndPostpone');
  String get resetAction => get('resetAction');
  String resetActionBody(String date) =>
      get('resetActionBody').replaceAll('{date}', date);
  String get resetActionConfirm => get('resetActionConfirm');
  String get actionReset => get('actionReset');
  String get pastPeriodUpdateConfirmTitle =>
      get('pastPeriodUpdateConfirmTitle');
  String pastPeriodUpdateConfirmBody(String date) =>
      get('pastPeriodUpdateConfirmBody').replaceAll('{date}', date);

  // ── Weekly Plan ──
  String get noLessonToday => get('noLessonToday');
  String get thisWeek => get('thisWeek');
  String get nextWeek => get('nextWeek');
  String get weeklyAttendanceListTitle => get('weeklyAttendanceListTitle');
  String get markAttendanceDone => get('markAttendanceDone');
  String get makeup => get('makeup');
  String periodLabel(int index) =>
      get('periodLabel').replaceAll('{index}', '$index');
  String get noPeriod => get('noPeriod');
  String scheduleRealignedPendingLessons(int count) =>
      get('scheduleRealignedPendingLessons').replaceAll('{count}', '$count');

  // ── Settings & About ──
  String get settings => get('settings');
  String get languageSettings => get('languageSettings');
  String get appLanguage => get('appLanguage');
  String get selectAppLanguage => get('selectAppLanguage');
  String get systemDefaultLanguage => get('systemDefaultLanguage');
  String get notificationSettings => get('notificationSettings');
  String get notificationSettingsDesc => get('notificationSettingsDesc');
  String get notificationSettingsLoading => get('notificationSettingsLoading');
  String get notificationSettingsDisabled =>
      get('notificationSettingsDisabled');
  String get notificationSettingsSaved => get('notificationSettingsSaved');
  String get notificationBeforeProgram => get('notificationBeforeProgram');
  String get notificationBeforeProgramDesc =>
      get('notificationBeforeProgramDesc');
  String get notificationBeforeProgramMinutes =>
      get('notificationBeforeProgramMinutes');
  String get notificationBeforeProgramOff =>
      get('notificationBeforeProgramOff');
  String get notificationMorningPlan => get('notificationMorningPlan');
  String get notificationMorningPlanDesc => get('notificationMorningPlanDesc');
  String get notificationMorningTime => get('notificationMorningTime');
  String get notificationMorningPlanOff => get('notificationMorningPlanOff');
  String notificationMinuteValue(int minutes) =>
      get('notificationMinuteValue').replaceAll('{minutes}', '$minutes');
  String notificationBeforeProgramSummary(int minutes) => get(
    'notificationBeforeProgramSummary',
  ).replaceAll('{minutes}', '$minutes');
  String notificationMorningPlanSummary(int hour, int minute) =>
      get('notificationMorningPlanSummary')
          .replaceAll('{hour}', hour.toString().padLeft(2, '0'))
          .replaceAll('{minute}', minute.toString().padLeft(2, '0'));
  String get notificationSessionReminderTitle =>
      get('notificationSessionReminderTitle');
  String notificationSessionReminderBody(
    String clientName,
    String time,
    int minutes,
  ) => get('notificationSessionReminderBody')
      .replaceAll('{name}', clientName)
      .replaceAll('{time}', time)
      .replaceAll('{minutes}', '$minutes');
  String get notificationMorningPlanTitle =>
      get('notificationMorningPlanTitle');
  String notificationMorningPlanBody(int count) =>
      get('notificationMorningPlanBody').replaceAll('{count}', '$count');
  String get notificationMorningPlanBodyNoSessions =>
      get('notificationMorningPlanBodyNoSessions');
  String get appInfo => get('appInfo');
  String get versionLabel => get('versionLabel');
  String get buildNumber => get('buildNumber');
  String get appVersionLabel => get('appVersionLabel');
  String get copyrightLabel => get('copyrightLabel');
  String get legalLinks => get('legalLinks');
  String get subscriptionLegalNotice => get('subscriptionLegalNotice');
  String get subscriptionAutoRenewNotice => get('subscriptionAutoRenewNotice');
  String get subscriptionCancelNotice => get('subscriptionCancelNotice');
  String get privacyPolicy => get('privacyPolicy');
  String get termsOfUse => get('termsOfUse');
  String get appleStandardEula => get('appleStandardEula');
  String get linkOpenError => get('linkOpenError');
  String get deleteAccount => get('deleteAccount');
  String get deleteAccountDesc => get('deleteAccountDesc');
  String get deleteAccountConfirmTitle => get('deleteAccountConfirmTitle');
  String get deleteAccountConfirmMessage => get('deleteAccountConfirmMessage');
  String get deleteAccountError => get('deleteAccountError');
  String get dangerZone => get('dangerZone');
  String get dangerZoneDesc => get('dangerZoneDesc');
  String get developerTools => get('developerTools');
  String get versionHistory => get('versionHistory');

  // ── Error Logs ──
  String get errorLogs => get('errorLogs');
  String get errorLogsDesc => get('errorLogsDesc');
  String get errorStats => get('errorStats');
  String get totalEntries => get('totalEntries');
  String get noErrorLogs => get('noErrorLogs');
  String get exportLogs => get('exportLogs');
  String get exportError => get('exportError');
  String get clearAllLogs => get('clearAllLogs');
  String get clearAllLogsConfirm => get('clearAllLogsConfirm');
  String get errorDetail => get('errorDetail');
  String get level => get('level');
  String get date => get('date');
  String get platformLabel => get('platformLabel');
  String get route => get('route');
  String get extraInfo => get('extraInfo');
  String get errorMessage => get('errorMessage');
  String get deleteLog => get('deleteLog');
  String get all => get('all');
  String get unexpectedError => get('unexpectedError');
  String get errorReported => get('errorReported');

  // Active/Passive
  String get activeAthletes => get('activeAthletes');
  String get passiveAthletes => get('passiveAthletes');
  String get setPassive => get('setPassive');
  String get setActive => get('setActive');
  String get noPassiveAthletes => get('noPassiveAthletes');
  String get athleteSetPassive => get('athleteSetPassive');
  String get athleteSetActive => get('athleteSetActive');

  // Delete confirmation
  String get confirmDeleteTitle => get('confirmDeleteTitle');
  String get confirmDeleteMessage => get('confirmDeleteMessage');
  String get confirmDeleteScheduleTitle => get('confirmDeleteScheduleTitle');
  String get confirmDeleteScheduleMessage =>
      get('confirmDeleteScheduleMessage');

  // ── Premium ──
  String get premiumTitle => get('premiumTitle');
  String get premiumActive => get('premiumActive');
  String get premiumThanks => get('premiumThanks');
  String get premiumUnlock => get('premiumUnlock');
  String get premiumActiveDesc => get('premiumActiveDesc');
  String get premiumDesc => get('premiumDesc');
  String get premiumFeatureClients => get('premiumFeatureClients');
  String get premiumFeaturePeriods => get('premiumFeaturePeriods');
  String get premiumFeatureMeasurements => get('premiumFeatureMeasurements');
  String get premiumFeatureWeeklyPlan => get('premiumFeatureWeeklyPlan');
  String get premiumFeaturePayments => get('premiumFeaturePayments');
  String get premiumUnlimited => get('premiumUnlimited');
  String get premiumFree => get('premiumFree');
  String get premiumLabel => get('premiumLabel');
  String get premiumChoosePlan => get('premiumChoosePlan');
  String get premiumMonthly => get('premiumMonthly');
  String get premiumYearly => get('premiumYearly');
  String get premiumMonthlyDesc => get('premiumMonthlyDesc');
  String get premiumYearlyDesc => get('premiumYearlyDesc');
  String get premiumBestValue => get('premiumBestValue');
  String get premiumMonthlyActive => get('premiumMonthlyActive');
  String get premiumYearlyActive => get('premiumYearlyActive');
  String get premiumBuy => get('premiumBuy');
  String get premiumRestore => get('premiumRestore');
  String get premiumComingSoon => get('premiumComingSoon');
  String maxClientsReached(int max) =>
      get('maxClientsReached').replaceAll('{max}', '$max');
  String maxPeriodsReached(int max) =>
      get('maxPeriodsReached').replaceAll('{max}', '$max');
  String get premiumRequired => get('premiumRequired');
  String get premiumPlan => get('premiumPlan');
  String get upgradeToPremium => get('upgradeToPremium');
  String get premiumPurchaseSuccess => get('premiumPurchaseSuccess');
  String get premiumRestoreSuccess => get('premiumRestoreSuccess');
  String get premiumPurchaseError => get('premiumPurchaseError');
  String get premiumStoreUnavailable => get('premiumStoreUnavailable');
  String get premiumProductNotFound => get('premiumProductNotFound');
  String get offerCodeLabel => get('offerCodeLabel');
  String get offerCodeInputHint => get('offerCodeInputHint');
  String get offerCodeButton => get('offerCodeButton');
  String get offerCodeSuccess => get('offerCodeSuccess');
  String get offerCodeError => get('offerCodeError');
  String get offerCodeOpenStore => get('offerCodeOpenStore');
  // ── Help Guide ──
  String get help => get('help');
  String get helpGuideTitle => get('helpGuideTitle');
  String get helpGuidePurpose => get('helpGuidePurpose');
  String get helpGuideFeatures => get('helpGuideFeatures');
  String get helpGuideScreens => get('helpGuideScreens');
  String get helpGuideFAQ => get('helpGuideFAQ');
  String get helpGuideContact => get('helpGuideContact');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['tr', 'en', 'es', 'nl'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}
