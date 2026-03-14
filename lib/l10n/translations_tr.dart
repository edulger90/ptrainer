const Map<String, String> trStrings = {
  // Genel
  'appTitle': 'P-Trainer',
  'cancel': 'İptal',
  'save': 'Kaydet',
  'add': 'Ekle',
  'update': 'Güncelle',
  'delete': 'Sil',
  'logout': 'Çıkış Yap',
  'edit': 'Düzenle',
  'manageAthletesDesc': 'Sporcularını görüntüle ve yönet',
  'weeklyPlanDesc': 'Haftalık ders programını incele',

  // Auth
  'login': 'Giriş Yap',
  'register': 'Kayıt Ol',
  'username': 'Kullanıcı Adı',
  'email': 'E-posta',
  'password': 'Şifre',
  'createAccount': 'Hesap oluştur',
  'alreadyHaveAccount': 'Zaten hesabın var mı? Giriş yap',
  'usernameEmpty': 'Kullanıcı adı boş olamaz',
  'usernameMinLength': 'Kullanıcı adı en az 3 karakter olmalı',
  'usernameMaxLength': 'Kullanıcı adı en fazla 20 karakter olabilir',
  'usernameInvalidChars':
      'Kullanıcı adı sadece harf, rakam, alt çizgi ve nokta içerebilir',
  'usernameStartsWithNumber': 'Kullanıcı adı sayı ile başlayamaz',
  'emailEmpty': 'E-posta adresi boş olamaz',
  'emailInvalid': 'Geçerli bir e-posta adresi girin',
  'passwordEmpty': 'Şifre boş olamaz',
  'passwordMinLength': 'Şifre en az 8 karakter olmalı',
  'passwordNeedsLowercase': 'Şifre en az bir küçük harf içermeli',
  'passwordNeedsUppercase': 'Şifre en az bir büyük harf içermeli',
  'usernameAndPasswordRequired': 'Kullanıcı adı ve şifre gerekli',
  'invalidCredentials': 'Kullanıcı adı veya şifre hatalı',
  'onlyOneUser': 'Sadece bir kullanıcı kayıt olabilir.',
  'registrationSuccess': 'Kayıt başarılı. Lütfen giriş yapın.',
  'tooManyAttempts': 'Çok fazla hatalı deneme. {seconds} saniye bekleyin.',
  'welcome': 'Hoşgeldin, {name}!',

  // Home
  'myAthletes': 'Sporcularım',
  'weeklyPlan': 'Haftalık Ders Planı',
  'analysis': 'Analiz',
  'analysisComingSoon': 'Analiz sayfası yakında eklenecek',

  // Client List
  'noAthletesYet': 'Henüz sporcu bulunmamaktadır.',
  'addAthlete': 'Sporcu Ekle',
  'packageLabel': 'Paket: {count} Derslik',

  // Add Client
  'addNewAthlete': 'Yeni Sporcu Ekle',
  'fullName': 'Ad Soyad',
  'registrationDate': 'İlk Kayıt Tarihi',
  'nameEmpty': 'Ad Soyad boş bırakamazsınız',
  'atLeastOneSchedule': 'En az bir ders saati tanımlamanız gerekir',
  'packageSize': 'Paket (Ders Sayısı)',
  'packageOption': '{count} Derslik Paket',
  'lessonSchedules': 'Ders Saatleri',
  'addLessonTime': 'Ders Saati Ekle',
  'noScheduleYet': 'Henüz ders saati eklenmemiştir',
  'saveAthlete': 'Sporcu Kaydet',

  // Schedule Dialog
  'addLessonTimeTitle': 'Ders Saati Ekle',
  'selectDay': 'Gün Seçiniz:',
  'selectTime': 'Saat Seçiniz:',
  'selectDayFirst': 'Önce bir gün seçiniz',

  // Days of Week
  'monday': 'Pazartesi',
  'tuesday': 'Salı',
  'wednesday': 'Çarşamba',
  'thursday': 'Perşembe',
  'friday': 'Cuma',
  'saturday': 'Cumartesi',
  'sunday': 'Pazar',

  // Client Detail
  'athleteDetail': 'Sporcu Detayı',
  'editInfo': 'Bilgileri Düzenle',
  'editAthleteInfo': 'Sporcu Bilgilerini Düzenle',
  'lessonPackage': 'Derslik Paket',
  'firstRegistration': 'İlk Kayıt',
  'period': 'Periyot',

  // Periods
  'periods': 'Periyotlar',
  'newPeriod': 'Yeni Periyot',
  'noPeriodYet': 'Henüz periyot eklenmemiş',
  'periodNumber': 'Periyot {n}',
  'lessonsProgress': '{attended} / {total} ders',
  'postponed': 'Ötelenmiş',
  'noPaymentInfo': 'Ödeme bilgisi yok',
  'paymentPaid': '{amount} ₺ – Ödendi',
  'paymentPending': '{amount} ₺ – Bekliyor',
  'payment': 'Ödeme',
  'calendar': 'Takvim',

  // Add Period
  'addNewPeriod': 'Yeni Periyot Ekle',
  'selectStartDate': 'Başlangıç Tarihi Seç',
  'startDateLabel': 'Başlangıç: {date}',
  'selectEndDate': 'Bitiş Tarihi Seç',
  'endDateLabel': 'Bitiş: {date}',
  'paymentAmount': 'Ödeme Tutarı (₺)',
  'paymentReceived': 'Ödeme Alındı',

  // Period Detail
  'periodDetail': 'Periyot Detayı',
  'startInfo': 'Başlangıç: {date}',
  'endInfo': 'Bitiş: {date}',
  'postponedInfo': 'Ötelenmiş: {date}',
  'paymentInfo': 'Ödeme Bilgileri',
  'paymentCompleted': 'Ödeme tamamlandı',
  'paymentAwaiting': 'Ödeme bekleniyor',

  // Schedules
  'lessonTimes': 'Ders Saatleri',
  'noScheduleAdded': 'Henüz ders saati eklenmemiş.',
  'editLessonTime': 'Ders Saati Düzenle',
  'day': 'Gün',
  'timeLabel': 'Saat: {time}',

  // Body Measurements
  'bodyMeasurements': 'Beden Ölçümleri',
  'addMeasurement': 'Beden Ölçüsü Ekle',
  'noMeasurementYet': 'Henüz ölçüm eklenmemiş.',
  'chest': 'Göğüs (cm)',
  'waist': 'Bel (cm)',
  'hips': 'Basen (cm)',
  'dateLabel': 'Tarih: {date}',
  'atLeastOneMeasurement': 'En az bir ölçüm giriniz',
  'saveMeasurement': 'Ölçümü Kaydet',
  'selectDate': 'Tarih Seçin',
  'measurementSection': 'Beden Ölçümleri',

  // Period Calendar
  'periodCalendar': 'Periyot Takvimi',
  'postponedBadge': 'Ötelendi',
  'cancelLesson': 'Ders İptali',
  'cancelLessonBody':
      '{date} tarihli ders iptal edilecek.\n\nPeriyot sonuna yeni bir ders günü eklenecek ve bitiş tarihi ötelenecek.\n\nDevam etmek istiyor musunuz?',
  'giveUp': 'Vazgeç',
  'confirmCancel': 'İptal Et',
  'undoCancel': 'İptal Geri Al',
  'undoCancelBody':
      '{date} tarihli ders iptalini geri almak istiyor musunuz?\n\nPeriyot bitiş tarihi bir ders günü geri çekilecek.',
  'confirmUndo': 'Geri Al',
  'cancelled': 'İptal Edildi',
  'makeupLabel': 'Telafi: {date}',
  'postponedLesson': 'Ötelenen ders',
  'selectMakeupDate': 'Telafi tarihi seç',
  'undoCancelTooltip': 'İptali geri al',
  'cancelAndPostpone': 'Dersi iptal et ve ötele',

  // Weekly Plan
  'noLessonToday': 'Bu gün için ders yok.',
  'periodLabel': 'Periyot {index}',
  'noPeriod': 'Periyot Yok',

  // Settings & About
  'settings': 'Ayarlar',
  'appInfo': 'Uygulama Bilgileri',
  'versionLabel': 'Versiyon',
  'buildNumber': 'Build Numarası',
  'appVersionLabel': 'Uygulama Versiyonu',
  'developerTools': 'Geliştirici Araçları',
  'versionHistory': 'Versiyon Geçmişi',

  // Error Logs
  'errorLogs': 'Hata Kayıtları',
  'errorLogsDesc': 'Uygulama hatalarını görüntüle ve dışa aktar',
  'errorStats': 'Hata İstatistikleri',
  'totalEntries': 'kayıt',
  'noErrorLogs': 'Hata kaydı bulunmamaktadır',
  'exportLogs': 'Logları Dışa Aktar',
  'exportError': 'Dışa aktarma hatası',
  'clearAllLogs': 'Tüm Logları Temizle',
  'clearAllLogsConfirm':
      'Tüm hata kayıtları silinecek. Devam etmek istiyor musunuz?',
  'errorDetail': 'Hata Detayı',
  'level': 'Seviye',
  'date': 'Tarih',
  'platformLabel': 'Platform',
  'route': 'Sayfa',
  'extraInfo': 'Ek Bilgi',
  'errorMessage': 'Hata Mesajı',
  'deleteLog': 'Bu Kaydı Sil',
  'all': 'Tümü',
  'unexpectedError': 'Beklenmeyen bir hata oluştu',
  'errorReported': 'Hata kaydedildi',

  // Active/Passive
  'activeAthletes': 'Aktif Sporcular',
  'passiveAthletes': 'Pasif Sporcular',
  'setPassive': 'Pasife Al',
  'setActive': 'Aktife Al',
  'noPassiveAthletes': 'Pasif sporcu yok',
  'athleteSetPassive': 'Sporcu pasife alındı',
  'athleteSetActive': 'Sporcu aktife alındı',
  'confirmDeleteTitle': 'Sporcuyu Sil',
  'confirmDeleteMessage':
      'Bu sporcuyu silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
  'confirmDeleteScheduleTitle': 'Ders Saatini Sil',
  'confirmDeleteScheduleMessage':
      'Bu ders saatini silmek istediğinize emin misiniz?',
};
