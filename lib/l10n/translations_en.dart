const Map<String, String> enStrings = {
  // General
  'appTitle': 'P-Trainer',
  'cancel': 'Cancel',
  'save': 'Save',
  'add': 'Add',
  'update': 'Update',
  'delete': 'Delete',
  'logout': 'Log Out',
  'edit': 'Edit',
  'manageAthletesDesc': 'View and manage your athletes',
  'weeklyPlanDesc': 'Review your weekly lesson schedule',

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

  // Home
  'myAthletes': 'My Athletes',
  'weeklyPlan': 'Weekly Lesson Plan',
  'analysis': 'Analysis',
  'analysisComingSoon': 'Analysis page coming soon',

  // Client List
  'noAthletesYet': 'No athletes yet.',
  'addAthlete': 'Add Athlete',
  'packageLabel': 'Package: {count} Lessons',

  // Add Client
  'addNewAthlete': 'Add New Athlete',
  'fullName': 'Full Name',
  'registrationDate': 'Registration Date',
  'nameEmpty': 'Name cannot be empty',
  'atLeastOneSchedule': 'You must add at least one lesson time',
  'packageSize': 'Package (Lesson Count)',
  'packageOption': '{count}-Lesson Package',
  'lessonSchedules': 'Lesson Schedules',
  'addLessonTime': 'Add Lesson Time',
  'noScheduleYet': 'No lesson times added yet',
  'saveAthlete': 'Save Athlete',

  // Schedule Dialog
  'addLessonTimeTitle': 'Add Lesson Time',
  'selectDay': 'Select Day:',
  'selectTime': 'Select Time:',
  'selectDayFirst': 'Select a day first',

  // Days of Week
  'monday': 'Monday',
  'tuesday': 'Tuesday',
  'wednesday': 'Wednesday',
  'thursday': 'Thursday',
  'friday': 'Friday',
  'saturday': 'Saturday',
  'sunday': 'Sunday',

  // Client Detail
  'athleteDetail': 'Athlete Detail',
  'editInfo': 'Edit Info',
  'editAthleteInfo': 'Edit Athlete Info',
  'lessonPackage': 'Lesson Package',
  'firstRegistration': 'Registered',
  'period': 'Period',

  // Periods
  'periods': 'Periods',
  'newPeriod': 'New Period',
  'noPeriodYet': 'No periods added yet',
  'periodNumber': 'Period {n}',
  'lessonsProgress': '{attended} / {total} lessons',
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
  'lessonTimes': 'Lesson Times',
  'noScheduleAdded': 'No lesson times added.',
  'editLessonTime': 'Edit Lesson Time',
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
  'cancelLesson': 'Cancel Lesson',
  'cancelLessonBody':
      'The lesson on {date} will be cancelled.\n\nA new lesson day will be added at the end of the period and the end date will be postponed.\n\nDo you want to continue?',
  'giveUp': 'Go Back',
  'confirmCancel': 'Cancel Lesson',
  'undoCancel': 'Undo Cancellation',
  'undoCancelBody':
      'Do you want to undo the cancellation for the lesson on {date}?\n\nThe period end date will be moved back by one lesson day.',
  'confirmUndo': 'Undo',
  'cancelled': 'Cancelled',
  'makeupLabel': 'Makeup: {date}',
  'postponedLesson': 'Postponed lesson',
  'selectMakeupDate': 'Select makeup date',
  'undoCancelTooltip': 'Undo cancellation',
  'cancelAndPostpone': 'Cancel and postpone',

  // Weekly Plan
  'noLessonToday': 'No lessons for this day.',
  'periodLabel': 'Period {index}',
  'noPeriod': 'No Period',

  // Settings & About
  'settings': 'Settings',
  'appInfo': 'App Info',
  'versionLabel': 'Version',
  'buildNumber': 'Build Number',
  'appVersionLabel': 'App Version',
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
  'activeAthletes': 'Active Athletes',
  'passiveAthletes': 'Passive Athletes',
  'setPassive': 'Set Passive',
  'setActive': 'Set Active',
  'noPassiveAthletes': 'No passive athletes',
  'athleteSetPassive': 'Athlete set to passive',
  'athleteSetActive': 'Athlete set to active',
  'confirmDeleteTitle': 'Delete Athlete',
  'confirmDeleteMessage':
      'Are you sure you want to delete this athlete? This action cannot be undone.',
  'confirmDeleteScheduleTitle': 'Delete Lesson Time',
  'confirmDeleteScheduleMessage':
      'Are you sure you want to delete this lesson time?',

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
};
