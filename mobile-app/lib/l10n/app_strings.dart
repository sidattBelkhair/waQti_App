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
      'phone_hint': '+222XXXXXXXX',
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
    },
    'ar': {
      'app_name': 'وقتي',
      'app_subtitle': 'أدر وقتك بذكاء',
      // Auth
      'login': 'تسجيل الدخول',
      'login_subtitle': 'أدخل رقمك وكلمة المرور',
      'phone': 'رقم الهاتف',
      'phone_hint': '+222XXXXXXXX',
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
