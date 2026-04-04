const Map<String, String> trStrings = {
  'completedLessonCount': 'Tamamlanan Ders: {count}',
  // Lesson Reason
  'reasonResmiTatil': 'Resmi Tatil',
  'reasonSporcuHasta': 'Sporcu Hasta',
  'reasonTrainerHasta': 'Trainer Hasta',
  'reasonSporcuKisisel': 'Sporcu Kişisel',
  'reasonTrainerKisisel': 'Trainer Kişisel',
  // Period sonuna ders ekleme dialogu
  'addLessonToPeriodEndTitle': 'Period Sonuna Ders Eklensin mi?',
  'addLessonToPeriodEndBody':
      'Bu dersi iptal ettiniz. Period sonuna yeni bir ders eklemek ister misiniz?',
  'yes': 'Evet',
  'no': 'Hayır',
  // Genel
  'showPassiveClients': 'Pasifleri Göster',
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
  'thisWeek': 'Bu Hafta',
  'makeup': 'Telafi',
  'periodLabel': 'Periyot {index}',
  'noPeriod': 'Periyot Yok',

  // Settings & About
  'settings': 'Ayarlar',
  'appInfo': 'Uygulama Bilgileri',
  'versionLabel': 'Versiyon',
  'buildNumber': 'Build Numarası',
  'appVersionLabel': 'Uygulama Versiyonu',
  'copyrightLabel': 'Telif Hakkı',
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

  // Premium
  'premiumTitle': 'Premium',
  'premiumActive': 'AKTİF',
  'premiumThanks': 'Premium üyesiniz!',
  'premiumUnlock': 'Tüm Özelliklerin Kilidini Aç',
  'premiumActiveDesc': 'Tüm özelliklerden sınırsız yararlanıyorsunuz.',
  'premiumDesc':
      'Premium üyelik ile sınırsız sporcu, periyot, beden ölçümü, haftalık plan ve ödeme takibi.',
  'premiumFeatureClients': 'Sporcu Sayısı',
  'premiumFeaturePeriods': 'Periyot / Sporcu',
  'premiumFeatureMeasurements': 'Beden Ölçümleri',
  'premiumFeatureWeeklyPlan': 'Haftalık Plan',
  'premiumFeaturePayments': 'Ödeme Takibi',
  'premiumUnlimited': 'Sınırsız',
  'premiumFree': 'Ücretsiz',
  'premiumLabel': 'Premium',
  'premiumChoosePlan': 'Bir plan seçin',
  'premiumMonthly': 'Aylık',
  'premiumYearly': 'Yıllık',
  'premiumMonthlyDesc': 'Her ay faturalandırılır',
  'premiumYearlyDesc': 'Yılda bir kez faturalandırılır',
  'premiumBestValue': 'En Avantajlı',
  'premiumMonthlyActive': 'Aylık plan aktif',
  'premiumYearlyActive': 'Yıllık plan aktif',
  'premiumBuy': 'Premium Al',
  'premiumRestore': 'Satın Almayı Geri Yükle',
  'premiumComingSoon': 'Yakında satın alma aktif olacak!',
  'maxClientsReached':
      'Ücretsiz planda en fazla {max} sporcu ekleyebilirsiniz. Premium\'a geçin!',
  'maxPeriodsReached':
      'Ücretsiz planda sporcu başına en fazla {max} periyot ekleyebilirsiniz. Premium\'a geçin!',
  'premiumRequired': 'Bu özellik Premium üyelik gerektirir.',
  'premiumPlan': 'Mevcut Plan',
  'upgradeToPremium': 'Premium\'a Yükselt',
  'premiumPurchaseSuccess': 'Premium başarıyla aktifleştirildi! 🎉',
  'premiumRestoreSuccess': 'Satın alma başarıyla geri yüklendi!',
  'premiumPurchaseError': 'Satın alma sırasında bir hata oluştu.',
  'premiumStoreUnavailable': 'Mağaza şu anda kullanılamıyor.',
  'premiumProductNotFound':
      'Ürün bulunamadı. Lütfen daha sonra tekrar deneyin.',
  'selectReason': 'Sebep Seçin',
  'help': 'Yardım',
  'helpGuideTitle': 'Uygulama Kullanım Rehberi',
  'helpGuidePurpose':
      '1. Amaç ve Genel Bakış\n   - Bu uygulama, sporcu takibi, ders planlama ve periyot yönetimi için tasarlanmıştır.',
  'helpGuideFeatures':
      '2. Ana Özellikler\n   - Sporcu ekleme, düzenleme ve silme\n   - Periyot oluşturma ve ders günlerini belirleme\n   - Haftalık ders planı ve takvim görüntüleme\n   - Ders iptal/telafi işlemleri ve sebep seçimi\n   - Tamamlanan ders sayısı ve ilerleme takibi',
  'helpGuideScreens':
      '3. Ekranlar ve Navigasyon\n   - Ana sayfa: Sporcular ve genel özet\n   - Sporcu Detay: Periyotlar, ölçümler ve geçmiş dersler\n   - Periyot Takvimi: Günlük ders durumu, iptal/telafi işlemleri\n   - Haftalık Plan: Haftanın ders programı',
  'helpGuideFAQ':
      '4. Sıkça Sorulanlar\n   - Ders nasıl iptal edilir?\n   - Periyot nasıl uzatılır?\n   - Tamamlanan dersler nasıl hesaplanır?\n   - Hatalı girişlerde ne yapılmalı?',
  'helpGuideContact':
      '5. İletişim ve Destek\n   - Sorunlarınız için uygulama geliştiricisine ulaşabilirsiniz: ptrainer@edhelperapp.com',
};
