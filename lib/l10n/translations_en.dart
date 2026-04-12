const Map<String, String> enStrings = {
  'completedLessonCount': 'Completed Attendance: {count}',
  // Lesson Reason
  'reasonResmiTatil': 'Official Holiday',
  'reasonSporcuHasta': 'Program Sick',
  'reasonTrainerHasta': 'Trainer Sick',
  'reasonSporcuKisisel': 'Program Personal',
  'reasonTrainerKisisel': 'Trainer Personal',
  // Add lesson to period end dialog
  'addLessonToPeriodEndTitle': 'Add Attendance to End of Period?',
  'addLessonToPeriodEndBody':
      'You cancelled this attendance. Would you like to add a new attendance entry to the end of the period?',
  'yes': 'Yes',
  'no': 'No',
  // General
  'showPassiveClients': 'Show Passive Clients',
  'appTitle': 'P-Trainer',
  'cancel': 'Cancel',
  'save': 'Save',
  'add': 'Add',
  'update': 'Update',
  'delete': 'Delete',
  'logout': 'Log Out',
  'edit': 'Edit',
  'manageAthletesDesc': 'View and manage your programs',
  'weeklyPlanDesc': 'Review your weekly attendance schedule',

  // Auth
  'login': 'Log In',
  'register': 'Sign Up',
  'username': 'Username',
  'email': 'Email',
  'password': 'Password',
  'createAccount': 'Create an account',
  'alreadyHaveAccount': 'Already have an account? Log in',
  'usernameEmpty': 'Username cannot be empty',
  'usernameMinLength': 'Username must be at least 3 characters',
  'usernameMaxLength': 'Username can be at most 20 characters',
  'usernameInvalidChars':
      'Username can only contain letters, numbers, underscores and dots',
  'usernameStartsWithNumber': 'Username cannot start with a number',
  'emailEmpty': 'Email address cannot be empty',
  'emailInvalid': 'Enter a valid email address',
  'passwordEmpty': 'Password cannot be empty',
  'passwordMinLength': 'Password must be at least 8 characters',
  'passwordNeedsLowercase':
      'Password must contain at least one lowercase letter',
  'passwordNeedsUppercase':
      'Password must contain at least one uppercase letter',
  'usernameAndPasswordRequired': 'Username and password are required',
  'invalidCredentials': 'Invalid username or password',
  'onlyOneUser': 'Only one user can register.',
  'registrationSuccess': 'Registration successful. Please log in.',
  'tooManyAttempts': 'Too many failed attempts. Wait {seconds} seconds.',
  'welcome': 'Welcome, {name}!',
  'forgotPassword': 'Forgot Password',
  'securityQuestion': 'Security Question',
  'securityAnswer': 'Security Answer',
  'securityQuestionEmpty': 'Security question cannot be empty',
  'securityAnswerEmpty': 'Security answer cannot be empty',
  'securityAnswerWrong': 'Security answer is incorrect',
  'userNotFound': 'User not found',
  'newPassword': 'New Password',
  'resetPassword': 'Reset Password',
  'passwordResetSuccess': 'Password reset successful. Please log in.',
  'backToLogin': 'Back to Login',
  'continueText': 'Continue',

  // Home
  'myAthletes': 'My Programs',
  'weeklyPlan': 'Weekly Attendance Plan',
  'analysis': 'Analysis',
  'analysisComingSoon': 'Analysis page coming soon',

  // Client List
  'noAthletesYet': 'No programs yet.',
  'addAthlete': 'Add Program',
  'packageLabel': 'Package: {count} Attendance',

  // Add Client
  'addNewAthlete': 'Add New Program',
  'fullName': 'Full Name',
  'registrationDate': 'Registration Date',
  'nameEmpty': 'Name cannot be empty',
  'atLeastOneSchedule': 'You must add at least one attendance time',
  'packageSize': 'Package (Attendance Count)',
  'packageCountValidation':
      'Package attendance count must be between 1 and 100',
  'programTypeLabel': 'Program Type',
  'programTypeSport': 'Sport',
  'programTypeCourse': 'Course',
  'programTypePersonal': 'Personal',
  'packageTypeLabel': 'Package Type',
  'packageTypeDaily': 'Daily',
  'packageTypeMonthly': 'Monthly',
  'packageOption': '{count}-Attendance Package',
  'lessonSchedules': 'Attendance Schedules',
  'addLessonTime': 'Add Attendance Time',
  'noScheduleYet': 'No attendance times added yet',
  'saveAthlete': 'Save Program',

  // Schedule Dialog
  'addLessonTimeTitle': 'Add Attendance Time',
  'selectDay': 'Select Day:',
  'selectTime': 'Select Time:',
  'selectDayFirst': 'Select a day first',
  'scheduleDayAlreadyExists':
      'An attendance time is already defined for this day',

  // Days of Week
  'monday': 'Monday',
  'tuesday': 'Tuesday',
  'wednesday': 'Wednesday',
  'thursday': 'Thursday',
  'friday': 'Friday',
  'saturday': 'Saturday',
  'sunday': 'Sunday',

  // Client Detail
  'athleteDetail': 'Program Detail',
  'editInfo': 'Edit Info',
  'editAthleteInfo': 'Edit Program Info',
  'lessonPackage': 'Attendance Package',
  'firstRegistration': 'Registered',
  'period': 'Period',

  // Periods
  'periods': 'Periods',
  'newPeriod': 'New Period',
  'noPeriodYet': 'No periods added yet',
  'periodNumber': 'Period {n}',
  'lessonsProgress': '{attended} / {total} attendance',
  'postponed': 'Postponed',
  'noPaymentInfo': 'No payment info',
  'paymentPaid': '{amount} ₺ – Paid',
  'paymentPending': '{amount} ₺ – Pending',
  'payment': 'Payment',
  'calendar': 'Calendar',

  // Add Period
  'addNewPeriod': 'Add New Period',
  'selectStartDate': 'Select Start Date',
  'startDateLabel': 'Start: {date}',
  'selectEndDate': 'Select End Date',
  'endDateLabel': 'End: {date}',
  'paymentAmount': 'Payment Amount (₺)',
  'paymentReceived': 'Payment Received',

  // Period Detail
  'periodDetail': 'Period Detail',
  'startInfo': 'Start: {date}',
  'endInfo': 'End: {date}',
  'postponedInfo': 'Postponed: {date}',
  'paymentInfo': 'Payment Info',
  'paymentCompleted': 'Payment completed',
  'paymentAwaiting': 'Payment pending',

  // Schedules
  'lessonTimes': 'Attendance Times',
  'noScheduleAdded': 'No attendance times added.',
  'editLessonTime': 'Edit Attendance Time',
  'day': 'Day',
  'timeLabel': 'Time: {time}',

  // Body Measurements
  'bodyMeasurements': 'Body Measurements',
  'addMeasurement': 'Add Measurement',
  'noMeasurementYet': 'No measurements yet.',
  'chest': 'Chest (cm)',
  'waist': 'Waist (cm)',
  'hips': 'Hips (cm)',
  'dateLabel': 'Date: {date}',
  'atLeastOneMeasurement': 'Enter at least one measurement',
  'saveMeasurement': 'Save Measurement',
  'selectDate': 'Select Date',
  'measurementSection': 'Body Measurements',

  // Period Calendar
  'periodCalendar': 'Period Calendar',
  'postponedBadge': 'Postponed',
  'cancelLesson': 'Cancel Attendance',
  'cancelLessonBody':
      'The attendance on {date} will be cancelled.\n\nA new attendance day will be added at the end of the period and the end date will be postponed.\n\nDo you want to continue?',
  'giveUp': 'Go Back',
  'confirmCancel': 'Cancel Attendance',
  'undoCancel': 'Undo Cancellation',
  'undoCancelBody':
      'Do you want to undo the cancellation for the attendance on {date}?\n\nThe period end date will be moved back by one attendance day.',
  'confirmUndo': 'Undo',
  'cancelled': 'Cancelled',
  'makeupLabel': 'Makeup: {date}',
  'postponedLesson': 'Postponed attendance',
  'selectMakeupDate': 'Select makeup date',
  'undoCancelTooltip': 'Undo cancellation',
  'cancelAndPostpone': 'Cancel and postpone',
  'resetAction': 'Undo Action',
  'resetActionBody':
      'All actions (attendance, makeup, etc.) for the attendance on {date} will be reset.\n\nDo you want to continue?',
  'resetActionConfirm': 'Undo',
  'actionReset': 'Action undone',

  // Weekly Plan
  'noLessonToday': 'No attendance for this day.',
  'thisWeek': 'This Week',
  'nextWeek': 'Next Week',
  'makeup': 'Makeup',
  'periodLabel': 'Period {index}',
  'noPeriod': 'No Period',

  // Settings & About
  'settings': 'Settings',
  'languageSettings': 'Language Settings',
  'appLanguage': 'App Language',
  'selectAppLanguage': 'Select app language',
  'systemDefaultLanguage': 'System Default',
  'appInfo': 'App Info',
  'versionLabel': 'Version',
  'buildNumber': 'Build Number',
  'appVersionLabel': 'App Version',
  'copyrightLabel': 'Copyright',
  'legalLinks': 'Legal Links',
  'subscriptionLegalNotice':
      'By subscribing, you agree to our Terms of Use and Privacy Policy.',
  'subscriptionAutoRenewNotice':
      'Subscription automatically renews unless cancelled.',
  'subscriptionCancelNotice': 'You can cancel anytime via App Store settings.',
  'privacyPolicy': 'Privacy Policy',
  'termsOfUse': 'Terms of Use',
  'appleStandardEula': 'Apple Standard EULA',
  'linkOpenError': 'Could not open the link.',
  'deleteAccount': 'Delete Account',
  'deleteAccountDesc': 'Delete your account and all local data',
  'deleteAccountConfirmTitle': 'Are you sure you want to delete your account?',
  'deleteAccountConfirmMessage': 'This action cannot be undone.',
  'deleteAccountError': 'An error occurred while deleting the account.',
  'dangerZone': 'Danger Zone',
  'dangerZoneDesc':
      'Actions in this section are permanent. Review carefully before continuing.',
  'developerTools': 'Developer Tools',
  'versionHistory': 'Version History',

  // Error Logs
  'errorLogs': 'Error Logs',
  'errorLogsDesc': 'View and export application errors',
  'errorStats': 'Error Statistics',
  'totalEntries': 'entries',
  'noErrorLogs': 'No error logs found',
  'exportLogs': 'Export Logs',
  'exportError': 'Export error',
  'clearAllLogs': 'Clear All Logs',
  'clearAllLogsConfirm':
      'All error logs will be deleted. Do you want to continue?',
  'errorDetail': 'Error Detail',
  'level': 'Level',
  'date': 'Date',
  'platformLabel': 'Platform',
  'route': 'Route',
  'extraInfo': 'Extra Info',
  'errorMessage': 'Error Message',
  'deleteLog': 'Delete This Log',
  'all': 'All',
  'unexpectedError': 'An unexpected error occurred',
  'errorReported': 'Error has been logged',

  // Active/Passive
  'activeAthletes': 'Active Programs',
  'passiveAthletes': 'Passive Programs',
  'setPassive': 'Set Passive',
  'setActive': 'Set Active',
  'noPassiveAthletes': 'No passive programs',
  'athleteSetPassive': 'Program set to passive',
  'athleteSetActive': 'Program set to active',
  'confirmDeleteTitle': 'Delete Program',
  'confirmDeleteMessage':
      'Are you sure you want to delete this program? This action cannot be undone.',
  'confirmDeleteScheduleTitle': 'Delete Attendance Time',
  'confirmDeleteScheduleMessage':
      'Are you sure you want to delete this attendance time?',

  // Premium
  'premiumTitle': 'Premium',
  'premiumActive': 'ACTIVE',
  'premiumThanks': 'You are a Premium member!',
  'premiumUnlock': 'Unlock All Features',
  'premiumActiveDesc': 'You have unlimited access to all features.',
  'premiumDesc':
      'Get unlimited athletes, periods, body measurements, weekly plan and payment tracking with Premium.',
  'premiumFeatureClients': 'Athletes',
  'premiumFeaturePeriods': 'Periods / Athlete',
  'premiumFeatureMeasurements': 'Body Measurements',
  'premiumFeatureWeeklyPlan': 'Weekly Plan',
  'premiumFeaturePayments': 'Payment Tracking',
  'premiumUnlimited': 'Unlimited',
  'premiumFree': 'Free',
  'premiumLabel': 'Premium',
  'premiumChoosePlan': 'Choose a plan',
  'premiumMonthly': 'Monthly',
  'premiumYearly': 'Yearly',
  'premiumMonthlyDesc': 'Billed every month',
  'premiumYearlyDesc': 'Billed once per year',
  'premiumBestValue': 'Best Value',
  'premiumMonthlyActive': 'Monthly plan active',
  'premiumYearlyActive': 'Yearly plan active',
  'premiumBuy': 'Get Premium',
  'premiumRestore': 'Restore Purchase',
  'premiumComingSoon': 'In-app purchase coming soon!',
  'maxClientsReached':
      'Free plan allows up to {max} athletes. Upgrade to Premium!',
  'maxPeriodsReached':
      'Free plan allows up to {max} periods per athlete. Upgrade to Premium!',
  'premiumRequired': 'This feature requires a Premium membership.',
  'premiumPlan': 'Current Plan',
  'upgradeToPremium': 'Upgrade to Premium',
  'premiumPurchaseSuccess': 'Premium activated successfully! 🎉',
  'premiumRestoreSuccess': 'Purchase restored successfully!',
  'premiumPurchaseError': 'An error occurred during purchase.',
  'premiumStoreUnavailable': 'Store is currently unavailable.',
  'premiumProductNotFound': 'Product not found. Please try again later.',
  'selectReason': 'Select Reason',

  // Help
  'help': 'Help',
  'helpGuideTitle': 'App Usage Guide',
  'helpGuidePurpose':
      '1. Purpose and Overview\n   - This app is designed for athlete tracking, lesson planning, and period management.',
  'helpGuideFeatures':
      '2. Main Features\n   - Add, edit, and delete athletes\n   - Create periods and set lesson days\n   - View weekly lesson plan and calendar\n   - Cancel/make up lessons and select reasons\n   - Track completed lessons and progress',
  'helpGuideScreens':
      '3. Screens and Navigation\n   - Home: Athletes and overview\n   - Athlete Detail: Periods, measurements, and lesson history\n   - Period Calendar: Daily lesson status, cancel/make up\n   - Weekly Plan: Weekly lesson schedule',
  'helpGuideFAQ':
      '4. Frequently Asked Questions\n   - How to cancel a lesson?\n   - How to extend a period?\n   - How are completed lessons calculated?\n   - What to do in case of incorrect entries?',
  'helpGuideContact':
      '5. Contact & Support\n   - For issues, contact the app developer: ecedulger90@gmail.com',
};
