import 'package:flutter/material.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _s = {
    'fr': {
      'app_name': 'WaQti',
      'app_subtitle': 'Gérez votre temps intelligemment',
      // Auth
      'login': 'Connexion',
      'login_subtitle': 'Entrez votre numéro et mot de passe',
      'phone': 'Numéro de téléphone',
      'phone_hint': 'Ex: 25XXXXXXX',
      'password': 'Mot de passe',
      'password_min': 'Mot de passe (min 6 car.)',
      'forgot_password': 'Mot de passe oublié ?',
      'sign_in': 'Se connecter',
      'no_account': 'Pas encore de compte ?',
      'create_account': 'Créer un compte',
      'register': 'Inscription',
      'full_name': 'Nom complet',
      'register_btn': 'Créer mon compte',
      'i_am': 'Je suis :',
      'client': 'Client',
      'manager': 'Gestionnaire',
      'manager_info': 'Vous pourrez enregistrer votre établissement après la connexion.',
      // OTP
      'otp_title': 'Vérification',
      'otp_subtitle': 'Un code à 6 chiffres a été envoyé par SMS à votre numéro',
      'otp_verify': 'Vérifier',
      'otp_resend': 'Renvoyer le code',
      'otp_expired': 'Code expiré',
      // Profile
      'profile': 'Mon Profil',
      'edit_profile': 'Modifier le profil',
      'logout': 'Se déconnecter',
      'nni': 'NNI',
      'nni_placeholder': 'Non renseigné',
      'status': 'Statut',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'profile_updated': 'Profil mis à jour',
      // Home
      'search': 'Rechercher un établissement...',
      'my_tickets': 'Mes tickets',
      'nearby': 'À proximité',
      'all': 'Tous',
      // General
      'error': 'Erreur',
      'loading': 'Chargement...',
      'retry': 'Réessayer',
      'delete': 'Supprimer',
      'confirm': 'Confirmer',
      'language': 'Langue',
      // Gestionnaire — navigation
      'g_nav_file': 'File',
      'g_nav_stats': 'Statistiques',
      'g_nav_services': 'Services',
      // Gestionnaire — File en direct
      'g_live': 'En direct',
      'g_guichet': 'Guichet',
      'g_current_ticket': 'Ticket en cours',
      'g_call_next': 'Appeler le suivant',
      'g_absent': 'Absent',
      'g_pause': 'Pause',
      'g_resume': 'Reprendre',
      'g_screen_room': 'Écran salle',
      'g_next_tickets': 'Prochains tickets',
      'g_priority_badge': 'Prioritaire',
      'g_no_ticket_current': 'Aucun ticket en cours',
      'g_no_tickets_waiting': 'Aucun ticket en attente',
      'g_called_snackbar': 'appelé — Le client a été notifié par SMS',
      'g_queue_empty': 'La file est vide',
      'g_no_etab': "Créez d'abord votre établissement",
      'g_pending_validation': 'En attente de validation',
      // Gestionnaire — Statistiques
      'g_stats_title': 'Statistiques du jour',
      'g_served': 'tickets servis',
      'g_waiting': 'en attente',
      'g_avg_time': 'min / client en moyenne',
      'g_absents_label': 'absents',
      'g_stats_note': 'Les rapports détaillés sont disponibles sur le dashboard web de votre établissement.',
      'g_history': 'Historique',
      // Gestionnaire — Services
      'g_my_services': 'Mes services',
      'g_open_close_hint': 'Ouvrir ou fermer un service',
      'g_service_closed': 'Fermé',
      'g_service_open': 'Ouvert',
      // Gestionnaire — Écran salle
      'g_close_display': "Fermer l'affichage",
      // Gestionnaire — Profil
      'g_manage_etab': 'Gérer mon établissement',
    },
    'ar': {
      'app_name': 'وقتي',
      'app_subtitle': 'أدر وقتك بذكاء',
      // Auth
      'login': 'تسجيل الدخول',
      'login_subtitle': 'أدخل رقمك وكلمة المرور',
      'phone': 'رقم الهاتف',
      'phone_hint': 'Ex: 25XXXXXXX',
      'password': 'كلمة المرور',
      'password_min': 'كلمة المرور (6 أحرف على الأقل)',
      'forgot_password': 'نسيت كلمة المرور ؟',
      'sign_in': 'تسجيل الدخول',
      'no_account': 'ليس لديك حساب ؟',
      'create_account': 'إنشاء حساب',
      'register': 'التسجيل',
      'full_name': 'الاسم الكامل',
      'register_btn': 'إنشاء حسابي',
      'i_am': 'أنا :',
      'client': 'عميل',
      'manager': 'مدير مؤسسة',
      'manager_info': 'يمكنك تسجيل مؤسستك بعد تسجيل الدخول.',
      // OTP
      'otp_title': 'التحقق',
      'otp_subtitle': 'تم إرسال رمز مكون من 6 أرقام عبر الرسائل القصيرة',
      'otp_verify': 'تحقق',
      'otp_resend': 'إعادة إرسال الرمز',
      'otp_expired': 'انتهت صلاحية الرمز',
      // Profile
      'profile': 'ملفي الشخصي',
      'edit_profile': 'تعديل الملف',
      'logout': 'تسجيل الخروج',
      'nni': 'الرقم الوطني',
      'nni_placeholder': 'غير محدد',
      'status': 'الحالة',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'profile_updated': 'تم تحديث الملف',
      // Home
      'search': 'البحث عن مؤسسة...',
      'my_tickets': 'تذاكري',
      'nearby': 'قريب مني',
      'all': 'الكل',
      // General
      'error': 'خطأ',
      'loading': 'جاري التحميل...',
      'retry': 'إعادة المحاولة',
      'delete': 'حذف',
      'confirm': 'تأكيد',
      'language': 'اللغة',
      // Gestionnaire — navigation
      'g_nav_file': 'الطابور',
      'g_nav_stats': 'الإحصائيات',
      'g_nav_services': 'الخدمات',
      // Gestionnaire — File en direct
      'g_live': 'مباشر',
      'g_guichet': 'الشباك',
      'g_current_ticket': 'التذكرة الحالية',
      'g_call_next': 'استدعاء التالي',
      'g_absent': 'غائب',
      'g_pause': 'توقف',
      'g_resume': 'استئناف',
      'g_screen_room': 'شاشة القاعة',
      'g_next_tickets': 'التذاكر القادمة',
      'g_priority_badge': 'أولوية',
      'g_no_ticket_current': 'لا توجد تذكرة حالياً',
      'g_no_tickets_waiting': 'لا توجد تذكرة في الانتظار',
      'g_called_snackbar': 'تم استدعاؤه — تم إشعار الزبون عبر الرسائل القصيرة',
      'g_queue_empty': 'الطابور فارغ',
      'g_no_etab': 'أنشئ مؤسستك أولاً',
      'g_pending_validation': 'في انتظار التحقق',
      // Gestionnaire — Statistiques
      'g_stats_title': 'إحصائيات اليوم',
      'g_served': 'تذكرة تمت خدمتها',
      'g_waiting': 'في الانتظار',
      'g_avg_time': 'دقيقة / زبون في المتوسط',
      'g_absents_label': 'غائبون',
      'g_stats_note': 'التقارير المفصلة متاحة على لوحة التحكم الخاصة بمؤسستك.',
      'g_history': 'السجل',
      // Gestionnaire — Services
      'g_my_services': 'خدماتي',
      'g_open_close_hint': 'فتح أو إغلاق خدمة',
      'g_service_closed': 'مغلق',
      'g_service_open': 'مفتوح',
      // Gestionnaire — Écran salle
      'g_close_display': 'إغلاق الشاشة',
      // Gestionnaire — Profil
      'g_manage_etab': 'إدارة مؤسستي',
    },
  };

  static String get(String key, String locale) =>
      _s[locale]?[key] ?? _s['fr']?[key] ?? key;
}

extension L10nContext on BuildContext {
  String tr(String key) {
    try {
      final provider = dependOnInheritedWidgetOfExactType<_LocaleInherited>();
      final locale = provider?.locale ?? 'fr';
      return AppStrings.get(key, locale);
    } catch (_) {
      return AppStrings.get(key, 'fr');
    }
  }

  bool get isArabic {
    try {
      final provider = dependOnInheritedWidgetOfExactType<_LocaleInherited>();
      return provider?.locale == 'ar';
    } catch (_) { return false; }
  }
}

class _LocaleInherited extends InheritedWidget {
  final String locale;
  const _LocaleInherited({required this.locale, required super.child});
  @override bool updateShouldNotify(_LocaleInherited old) => locale != old.locale;
}

class LocaleWrapper extends StatelessWidget {
  final String locale;
  final Widget child;
  const LocaleWrapper({super.key, required this.locale, required this.child});
  @override
  Widget build(BuildContext context) => _LocaleInherited(locale: locale, child: child);
}
