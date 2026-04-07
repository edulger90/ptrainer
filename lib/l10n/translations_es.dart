const Map<String, String> esStrings = {
  'completedLessonCount': 'Clases Completadas: {count}',
  // Lesson Reason
  'reasonResmiTatil': 'Fiesta Oficial',
  'reasonSporcuHasta': 'Deportista Enfermo',
  'reasonTrainerHasta': 'Entrenador Enfermo',
  'reasonSporcuKisisel': 'Deportista Personal',
  'reasonTrainerKisisel': 'Entrenador Personal',
  // General
  'showPassiveClients': 'Mostrar clientes pasivos',
  'appTitle': 'P-Trainer',
  'cancel': 'Cancelar',
  'save': 'Guardar',
  'add': 'Agregar',
  'update': 'Actualizar',
  'delete': 'Eliminar',
  'logout': 'Cerrar sesión',
  'edit': 'Editar',
  'manageAthletesDesc': 'Ver y gestionar tus atletas',
  'weeklyPlanDesc': 'Revisar tu horario semanal de clases',

  // Auth
  'login': 'Iniciar sesión',
  'register': 'Registrarse',
  'username': 'Nombre de usuario',
  'email': 'Correo electrónico',
  'password': 'Contraseña',
  'createAccount': 'Crear una cuenta',
  'alreadyHaveAccount': '¿Ya tienes cuenta? Inicia sesión',
  'usernameEmpty': 'El nombre de usuario no puede estar vacío',
  'usernameMinLength': 'El nombre de usuario debe tener al menos 3 caracteres',
  'usernameMaxLength':
      'El nombre de usuario puede tener como máximo 20 caracteres',
  'usernameInvalidChars':
      'El nombre de usuario solo puede contener letras, números, guiones bajos y puntos',
  'usernameStartsWithNumber':
      'El nombre de usuario no puede empezar con un número',
  'emailEmpty': 'El correo electrónico no puede estar vacío',
  'emailInvalid': 'Introduce un correo electrónico válido',
  'passwordEmpty': 'La contraseña no puede estar vacía',
  'passwordMinLength': 'La contraseña debe tener al menos 8 caracteres',
  'passwordNeedsLowercase':
      'La contraseña debe contener al menos una letra minúscula',
  'passwordNeedsUppercase':
      'La contraseña debe contener al menos una letra mayúscula',
  'usernameAndPasswordRequired':
      'El nombre de usuario y la contraseña son obligatorios',
  'invalidCredentials': 'Nombre de usuario o contraseña incorrectos',
  'onlyOneUser': 'Solo se puede registrar un usuario.',
  'registrationSuccess': 'Registro exitoso. Por favor, inicia sesión.',
  'tooManyAttempts': 'Demasiados intentos fallidos. Espera {seconds} segundos.',
  'welcome': '¡Bienvenido/a, {name}!',
  'forgotPassword': 'Olvidé mi Contraseña',
  'securityQuestion': 'Pregunta de Seguridad',
  'securityAnswer': 'Respuesta de Seguridad',
  'securityQuestionEmpty': 'La pregunta de seguridad no puede estar vacía',
  'securityAnswerEmpty': 'La respuesta de seguridad no puede estar vacía',
  'securityAnswerWrong': 'La respuesta de seguridad es incorrecta',
  'userNotFound': 'Usuario no encontrado',
  'newPassword': 'Nueva Contraseña',
  'resetPassword': 'Restablecer Contraseña',
  'passwordResetSuccess':
      'Contraseña restablecida exitosamente. Por favor, inicia sesión.',
  'backToLogin': 'Volver al Inicio de Sesión',
  'continueText': 'Continuar',

  // Home
  'myAthletes': 'Mis Deportistas',
  'weeklyPlan': 'Plan Semanal de Clases',
  'analysis': 'Análisis',
  'analysisComingSoon': 'La página de análisis estará disponible pronto',

  // Client List
  'noAthletesYet': 'Aún no hay deportistas.',
  'addAthlete': 'Agregar Deportista',
  'packageLabel': 'Paquete: {count} Clases',

  // Add Client
  'addNewAthlete': 'Agregar Nuevo Deportista',
  'fullName': 'Nombre Completo',
  'registrationDate': 'Fecha de Registro',
  'nameEmpty': 'El nombre no puede estar vacío',
  'atLeastOneSchedule': 'Debe agregar al menos un horario de clase',
  'packageSize': 'Paquete (Número de Clases)',
  'packageOption': 'Paquete de {count} Clases',
  'lessonSchedules': 'Horarios de Clases',
  'addLessonTime': 'Agregar Horario de Clase',
  'noScheduleYet': 'Aún no se han agregado horarios de clase',
  'saveAthlete': 'Guardar Deportista',

  // Schedule Dialog
  'addLessonTimeTitle': 'Agregar Horario de Clase',
  'selectDay': 'Seleccionar Día:',
  'selectTime': 'Seleccionar Hora:',
  'selectDayFirst': 'Selecciona un día primero',

  // Days of Week
  'monday': 'Lunes',
  'tuesday': 'Martes',
  'wednesday': 'Miércoles',
  'thursday': 'Jueves',
  'friday': 'Viernes',
  'saturday': 'Sábado',
  'sunday': 'Domingo',

  // Client Detail
  'athleteDetail': 'Detalle del Deportista',
  'editInfo': 'Editar Info',
  'editAthleteInfo': 'Editar Información del Deportista',
  'lessonPackage': 'Paquete de Clases',
  'firstRegistration': 'Registrado',
  'period': 'Periodo',

  // Periods
  'periods': 'Periodos',
  'newPeriod': 'Nuevo Periodo',
  'noPeriodYet': 'Aún no se han agregado periodos',
  'periodNumber': 'Periodo {n}',
  'lessonsProgress': '{attended} / {total} clases',
  'postponed': 'Pospuesto',
  'noPaymentInfo': 'Sin información de pago',
  'paymentPaid': '{amount} ₺ – Pagado',
  'paymentPending': '{amount} ₺ – Pendiente',
  'payment': 'Pago',
  'calendar': 'Calendario',

  // Add Period
  'addNewPeriod': 'Agregar Nuevo Periodo',
  'selectStartDate': 'Seleccionar Fecha de Inicio',
  'startDateLabel': 'Inicio: {date}',
  'selectEndDate': 'Seleccionar Fecha de Fin',
  'endDateLabel': 'Fin: {date}',
  'paymentAmount': 'Monto del Pago (₺)',
  'paymentReceived': 'Pago Recibido',

  // Period Detail
  'periodDetail': 'Detalle del Periodo',
  'startInfo': 'Inicio: {date}',
  'endInfo': 'Fin: {date}',
  'postponedInfo': 'Pospuesto: {date}',
  'paymentInfo': 'Información de Pago',
  'paymentCompleted': 'Pago completado',
  'paymentAwaiting': 'Pago pendiente',

  // Schedules
  'lessonTimes': 'Horarios de Clase',
  'noScheduleAdded': 'No se han agregado horarios de clase.',
  'editLessonTime': 'Editar Horario de Clase',
  'day': 'Día',
  'timeLabel': 'Hora: {time}',

  // Body Measurements
  'bodyMeasurements': 'Medidas Corporales',
  'addMeasurement': 'Agregar Medida',
  'noMeasurementYet': 'Aún no hay medidas.',
  'chest': 'Pecho (cm)',
  'waist': 'Cintura (cm)',
  'hips': 'Cadera (cm)',
  'dateLabel': 'Fecha: {date}',
  'atLeastOneMeasurement': 'Ingrese al menos una medida',
  'saveMeasurement': 'Guardar Medida',
  'selectDate': 'Seleccionar Fecha',
  'measurementSection': 'Medidas Corporales',

  // Period Calendar
  'periodCalendar': 'Calendario del Periodo',
  'postponedBadge': 'Pospuesto',
  'cancelLesson': 'Cancelar Clase',
  'cancelLessonBody':
      'La clase del {date} será cancelada.\n\nSe agregará un nuevo día de clase al final del periodo y la fecha de fin se pospondrá.\n\n¿Desea continuar?',
  'giveUp': 'Volver',
  'confirmCancel': 'Cancelar Clase',
  'undoCancel': 'Deshacer Cancelación',
  'undoCancelBody':
      '¿Desea deshacer la cancelación de la clase del {date}?\n\nLa fecha de fin del periodo se adelantará un día de clase.',
  'confirmUndo': 'Deshacer',
  'cancelled': 'Cancelada',
  'makeupLabel': 'Recuperación: {date}',
  'postponedLesson': 'Clase pospuesta',
  'selectMakeupDate': 'Seleccionar fecha de recuperación',
  'undoCancelTooltip': 'Deshacer cancelación',
  'cancelAndPostpone': 'Cancelar y posponer',

  // Weekly Plan
  'noLessonToday': 'No hay clases para este día.',
  'thisWeek': 'Esta Semana',
  'makeup': 'Recuperación',
  'periodLabel': 'Periodo {index}',
  'noPeriod': 'Sin Periodo',

  // Settings & About
  'settings': 'Configuración',
  'appInfo': 'Información de la App',
  'versionLabel': 'Versión',
  'buildNumber': 'Número de Build',
  'appVersionLabel': 'Versión de la App',
  'copyrightLabel': 'Copyright',
  'developerTools': 'Herramientas de Desarrollo',
  'versionHistory': 'Historial de Versiones',

  // Error Logs
  'errorLogs': 'Registros de Errores',
  'errorLogsDesc': 'Ver y exportar errores de la aplicación',
  'errorStats': 'Estadísticas de Errores',
  'totalEntries': 'registros',
  'noErrorLogs': 'No se encontraron registros de errores',
  'exportLogs': 'Exportar Registros',
  'exportError': 'Error de exportación',
  'clearAllLogs': 'Borrar Todos los Registros',
  'clearAllLogsConfirm':
      'Se eliminarán todos los registros de errores. ¿Desea continuar?',
  'errorDetail': 'Detalle del Error',
  'level': 'Nivel',
  'date': 'Fecha',
  'platformLabel': 'Plataforma',
  'route': 'Ruta',
  'extraInfo': 'Info Adicional',
  'errorMessage': 'Mensaje de Error',
  'deleteLog': 'Eliminar Este Registro',
  'all': 'Todos',
  'unexpectedError': 'Ocurrió un error inesperado',
  'errorReported': 'Error registrado',

  // Active/Passive
  'activeAthletes': 'Atletas Activos',
  'passiveAthletes': 'Atletas Pasivos',
  'setPassive': 'Desactivar',
  'setActive': 'Activar',
  'noPassiveAthletes': 'No hay atletas pasivos',
  'athleteSetPassive': 'Atleta desactivado',
  'athleteSetActive': 'Atleta activado',
  'confirmDeleteTitle': 'Eliminar Atleta',
  'confirmDeleteMessage':
      '¿Estás seguro de que quieres eliminar este atleta? Esta acción no se puede deshacer.',
  'confirmDeleteScheduleTitle': 'Eliminar Horario',
  'confirmDeleteScheduleMessage':
      '¿Estás seguro de que quieres eliminar este horario de clase?',

  // Premium
  'premiumTitle': 'Premium',
  'premiumActive': 'ACTIVO',
  'premiumThanks': '¡Eres miembro Premium!',
  'premiumUnlock': 'Desbloquear Todas las Funciones',
  'premiumActiveDesc': 'Tienes acceso ilimitado a todas las funciones.',
  'premiumDesc':
      'Obtén atletas, periodos, medidas corporales, plan semanal y seguimiento de pagos ilimitados con Premium.',
  'premiumFeatureClients': 'Atletas',
  'premiumFeaturePeriods': 'Periodos / Atleta',
  'premiumFeatureMeasurements': 'Medidas Corporales',
  'premiumFeatureWeeklyPlan': 'Plan Semanal',
  'premiumFeaturePayments': 'Seguimiento de Pagos',
  'premiumUnlimited': 'Ilimitado',
  'premiumFree': 'Gratis',
  'premiumLabel': 'Premium',
  'premiumChoosePlan': 'Elige un plan',
  'premiumMonthly': 'Mensual',
  'premiumYearly': 'Anual',
  'premiumMonthlyDesc': 'Facturado cada mes',
  'premiumYearlyDesc': 'Facturado una vez al ano',
  'premiumBestValue': 'Mejor Valor',
  'premiumMonthlyActive': 'Plan mensual activo',
  'premiumYearlyActive': 'Plan anual activo',
  'premiumBuy': 'Obtener Premium',
  'premiumRestore': 'Restaurar Compra',
  'premiumComingSoon': '¡Compra dentro de la app próximamente!',
  'maxClientsReached':
      'El plan gratuito permite hasta {max} atletas. ¡Actualiza a Premium!',
  'maxPeriodsReached':
      'El plan gratuito permite hasta {max} periodos por atleta. ¡Actualiza a Premium!',
  'premiumRequired': 'Esta función requiere una membresía Premium.',
  'premiumPlan': 'Plan Actual',
  'upgradeToPremium': 'Actualizar a Premium',
  'premiumPurchaseSuccess': '¡Premium activado con éxito! 🎉',
  'premiumRestoreSuccess': '¡Compra restaurada con éxito!',
  'premiumPurchaseError': 'Ocurrió un error durante la compra.',
  'premiumStoreUnavailable': 'La tienda no está disponible actualmente.',
  'premiumProductNotFound': 'Producto no encontrado. Inténtalo más tarde.',
  'selectReason': 'Seleccionar motivo',

  // Help Guide
  'help': 'Ayuda',
  'helpGuideTitle': 'Guía de Uso de la App',
  'helpGuidePurpose':
      '1. Propósito y Visión General\n   - Esta app está diseñada para el seguimiento de deportistas, planificación de clases y gestión de periodos.',
  'helpGuideFeatures':
      '2. Funcionalidades Principales\n   - Añadir, editar y eliminar deportistas\n   - Crear periodos y definir días de clase\n   - Ver el plan semanal y el calendario\n   - Cancelar/recuperar clases y seleccionar motivos\n   - Seguimiento de clases completadas y progreso',
  'helpGuideScreens':
      '3. Pantallas y Navegación\n   - Inicio: Deportistas y resumen\n   - Detalle del Deportista: Periodos, mediciones e historial de clases\n   - Calendario de Periodo: Estado diario de clases, cancelar/recuperar\n   - Plan Semanal: Horario semanal de clases',
  'helpGuideFAQ':
      '4. Preguntas Frecuentes\n   - ¿Cómo cancelar una clase?\n   - ¿Cómo extender un periodo?\n   - ¿Cómo se calculan las clases completadas?\n   - ¿Qué hacer ante entradas incorrectas?',
  'helpGuideContact':
      '5. Contacto y Soporte\n   - Para problemas, contacta al desarrollador: ecedulger90@gmail.com',
};
