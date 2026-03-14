const Map<String, String> nlStrings = {
  // General
  'appTitle': 'P-Trainer',
  'cancel': 'Annuleren',
  'save': 'Opslaan',
  'add': 'Toevoegen',
  'update': 'Bijwerken',
  'delete': 'Verwijderen',
  'logout': 'Uitloggen',
  'edit': 'Bewerken',
  'manageAthletesDesc': 'Bekijk en beheer je sporters',
  'weeklyPlanDesc': 'Bekijk je wekelijkse lesrooster',

  // Auth
  'login': 'Inloggen',
  'register': 'Registreren',
  'username': 'Gebruikersnaam',
  'email': 'E-mailadres',
  'password': 'Wachtwoord',
  'createAccount': 'Account aanmaken',
  'alreadyHaveAccount': 'Heb je al een account? Log in',
  'usernameEmpty': 'Gebruikersnaam mag niet leeg zijn',
  'usernameMinLength': 'Gebruikersnaam moet minimaal 3 tekens bevatten',
  'usernameMaxLength': 'Gebruikersnaam mag maximaal 20 tekens bevatten',
  'usernameInvalidChars':
      'Gebruikersnaam mag alleen letters, cijfers, underscores en punten bevatten',
  'usernameStartsWithNumber': 'Gebruikersnaam mag niet met een cijfer beginnen',
  'emailEmpty': 'E-mailadres mag niet leeg zijn',
  'emailInvalid': 'Voer een geldig e-mailadres in',
  'passwordEmpty': 'Wachtwoord mag niet leeg zijn',
  'passwordMinLength': 'Wachtwoord moet minimaal 8 tekens bevatten',
  'passwordNeedsLowercase':
      'Wachtwoord moet minimaal één kleine letter bevatten',
  'passwordNeedsUppercase': 'Wachtwoord moet minimaal één hoofdletter bevatten',
  'usernameAndPasswordRequired': 'Gebruikersnaam en wachtwoord zijn verplicht',
  'invalidCredentials': 'Ongeldige gebruikersnaam of wachtwoord',
  'onlyOneUser': 'Er kan maar één gebruiker worden geregistreerd.',
  'registrationSuccess': 'Registratie succesvol. Log alsjeblieft in.',
  'tooManyAttempts': 'Te veel mislukte pogingen. Wacht {seconds} seconden.',
  'welcome': 'Welkom, {name}!',

  // Home
  'myAthletes': 'Mijn Sporters',
  'weeklyPlan': 'Wekelijks Lesrooster',
  'analysis': 'Analyse',
  'analysisComingSoon': 'Analysepagina komt binnenkort',

  // Client List
  'noAthletesYet': 'Nog geen sporters.',
  'addAthlete': 'Sporter Toevoegen',
  'packageLabel': 'Pakket: {count} Lessen',

  // Add Client
  'addNewAthlete': 'Nieuwe Sporter Toevoegen',
  'fullName': 'Volledige Naam',
  'registrationDate': 'Registratiedatum',
  'nameEmpty': 'Naam mag niet leeg zijn',
  'atLeastOneSchedule': 'U moet minimaal één lestijd toevoegen',
  'packageSize': 'Pakket (Aantal Lessen)',
  'packageOption': '{count}-Lessen Pakket',
  'lessonSchedules': 'Lesroosters',
  'addLessonTime': 'Lestijd Toevoegen',
  'noScheduleYet': 'Nog geen lestijden toegevoegd',
  'saveAthlete': 'Sporter Opslaan',

  // Schedule Dialog
  'addLessonTimeTitle': 'Lestijd Toevoegen',
  'selectDay': 'Selecteer Dag:',
  'selectTime': 'Selecteer Tijd:',
  'selectDayFirst': 'Selecteer eerst een dag',

  // Days of Week
  'monday': 'Maandag',
  'tuesday': 'Dinsdag',
  'wednesday': 'Woensdag',
  'thursday': 'Donderdag',
  'friday': 'Vrijdag',
  'saturday': 'Zaterdag',
  'sunday': 'Zondag',

  // Client Detail
  'athleteDetail': 'Sporter Detail',
  'editInfo': 'Info Bewerken',
  'editAthleteInfo': 'Sporterinfo Bewerken',
  'lessonPackage': 'Lespakket',
  'firstRegistration': 'Geregistreerd',
  'period': 'Periode',

  // Periods
  'periods': 'Perioden',
  'newPeriod': 'Nieuwe Periode',
  'noPeriodYet': 'Nog geen perioden toegevoegd',
  'periodNumber': 'Periode {n}',
  'lessonsProgress': '{attended} / {total} lessen',
  'postponed': 'Uitgesteld',
  'noPaymentInfo': 'Geen betalingsinformatie',
  'paymentPaid': '{amount} ₺ – Betaald',
  'paymentPending': '{amount} ₺ – In afwachting',
  'payment': 'Betaling',
  'calendar': 'Kalender',

  // Add Period
  'addNewPeriod': 'Nieuwe Periode Toevoegen',
  'selectStartDate': 'Selecteer Startdatum',
  'startDateLabel': 'Start: {date}',
  'selectEndDate': 'Selecteer Einddatum',
  'endDateLabel': 'Einde: {date}',
  'paymentAmount': 'Betalingsbedrag (₺)',
  'paymentReceived': 'Betaling Ontvangen',

  // Period Detail
  'periodDetail': 'Periode Detail',
  'startInfo': 'Start: {date}',
  'endInfo': 'Einde: {date}',
  'postponedInfo': 'Uitgesteld: {date}',
  'paymentInfo': 'Betalingsinformatie',
  'paymentCompleted': 'Betaling voltooid',
  'paymentAwaiting': 'Betaling in afwachting',

  // Schedules
  'lessonTimes': 'Lestijden',
  'noScheduleAdded': 'Geen lestijden toegevoegd.',
  'editLessonTime': 'Lestijd Bewerken',
  'day': 'Dag',
  'timeLabel': 'Tijd: {time}',

  // Body Measurements
  'bodyMeasurements': 'Lichaamsmaten',
  'addMeasurement': 'Meting Toevoegen',
  'noMeasurementYet': 'Nog geen metingen.',
  'chest': 'Borst (cm)',
  'waist': 'Taille (cm)',
  'hips': 'Heupen (cm)',
  'dateLabel': 'Datum: {date}',
  'atLeastOneMeasurement': 'Voer minimaal één meting in',
  'saveMeasurement': 'Meting Opslaan',
  'selectDate': 'Selecteer Datum',
  'measurementSection': 'Lichaamsmaten',

  // Period Calendar
  'periodCalendar': 'Periode Kalender',
  'postponedBadge': 'Uitgesteld',
  'cancelLesson': 'Les Annuleren',
  'cancelLessonBody':
      'De les op {date} wordt geannuleerd.\n\nEr wordt een nieuwe lesdag toegevoegd aan het einde van de periode en de einddatum wordt uitgesteld.\n\nWilt u doorgaan?',
  'giveUp': 'Terug',
  'confirmCancel': 'Les Annuleren',
  'undoCancel': 'Annulering Ongedaan Maken',
  'undoCancelBody':
      'Wilt u de annulering van de les op {date} ongedaan maken?\n\nDe einddatum van de periode wordt met één lesdag teruggeschoven.',
  'confirmUndo': 'Ongedaan Maken',
  'cancelled': 'Geannuleerd',
  'makeupLabel': 'Inhaalles: {date}',
  'postponedLesson': 'Uitgestelde les',
  'selectMakeupDate': 'Selecteer inhaaldatum',
  'undoCancelTooltip': 'Annulering ongedaan maken',
  'cancelAndPostpone': 'Annuleren en uitstellen',

  // Weekly Plan
  'noLessonToday': 'Geen lessen voor deze dag.',
  'periodLabel': 'Periode {index}',
  'noPeriod': 'Geen Periode',

  // Settings & About
  'settings': 'Instellingen',
  'appInfo': 'App Informatie',
  'versionLabel': 'Versie',
  'buildNumber': 'Build Nummer',
  'appVersionLabel': 'App Versie',
  'developerTools': 'Ontwikkelaarstools',
  'versionHistory': 'Versiegeschiedenis',

  // Error Logs
  'errorLogs': 'Foutlogboeken',
  'errorLogsDesc': 'Bekijk en exporteer applicatiefouten',
  'errorStats': 'Foutstatistieken',
  'totalEntries': 'vermeldingen',
  'noErrorLogs': 'Geen foutlogboeken gevonden',
  'exportLogs': 'Logboeken Exporteren',
  'exportError': 'Exportfout',
  'clearAllLogs': 'Alle Logboeken Wissen',
  'clearAllLogsConfirm':
      'Alle foutlogboeken worden verwijderd. Wilt u doorgaan?',
  'errorDetail': 'Foutdetail',
  'level': 'Niveau',
  'date': 'Datum',
  'platformLabel': 'Platform',
  'route': 'Route',
  'extraInfo': 'Extra Info',
  'errorMessage': 'Foutmelding',
  'deleteLog': 'Dit Logboek Verwijderen',
  'all': 'Alles',
  'unexpectedError': 'Er is een onverwachte fout opgetreden',
  'errorReported': 'Fout is geregistreerd',

  // Active/Passive
  'activeAthletes': 'Actieve Sporters',
  'passiveAthletes': 'Passieve Sporters',
  'setPassive': 'Deactiveren',
  'setActive': 'Activeren',
  'noPassiveAthletes': 'Geen passieve sporters',
  'athleteSetPassive': 'Sporter gedeactiveerd',
  'athleteSetActive': 'Sporter geactiveerd',
  'confirmDeleteTitle': 'Sporter Verwijderen',
  'confirmDeleteMessage':
      'Weet je zeker dat je deze sporter wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.',
  'confirmDeleteScheduleTitle': 'Lestijd Verwijderen',
  'confirmDeleteScheduleMessage':
      'Weet je zeker dat je deze lestijd wilt verwijderen?',
};
