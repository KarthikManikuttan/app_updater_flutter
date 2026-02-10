import 'enums.dart';

/// Defines the messages used in the updater package.
///
/// Extend this class to provide custom translations or to override specific messages.
class UpdaterMessages {
  /// The language code to use for localization (e.g., 'en', 'es').
  /// If null, the system's locale (or default) is used.
  final String? languageCode;

  /// Override for the dialog title.
  final String? title;

  /// Override for the dialog body text.
  final String? body;

  /// Override for the "Update Now" button text.
  final String? buttonTitleUpdate;

  /// Override for the "Later" button text.
  final String? buttonTitleLater;

  /// Override for the "Ignore" button text.
  final String? buttonTitleIgnore;

  /// Override for the "Release Notes" header.
  final String? releaseNotes;

  /// Override for the prompt text (e.g. "Would you like to update?").
  final String? prompt;

  const UpdaterMessages({
    this.languageCode,
    this.title,
    this.body,
    this.buttonTitleUpdate,
    this.buttonTitleLater,
    this.buttonTitleIgnore,
    this.releaseNotes,
    this.prompt,
  });

  /// Returns the localized message for the given [messageKey].
  String message(UpdaterMessage messageKey) {
    // 1. Check for overrides
    switch (messageKey) {
      case UpdaterMessage.title:
        if (title != null) return title!;
        break;
      case UpdaterMessage.body:
        if (body != null) return body!;
        break;
      case UpdaterMessage.buttonTitleUpdate:
        if (buttonTitleUpdate != null) return buttonTitleUpdate!;
        break;
      case UpdaterMessage.buttonTitleLater:
        if (buttonTitleLater != null) return buttonTitleLater!;
        break;
      case UpdaterMessage.buttonTitleIgnore:
        if (buttonTitleIgnore != null) return buttonTitleIgnore!;
        break;
      case UpdaterMessage.releaseNotes:
        if (releaseNotes != null) return releaseNotes!;
        break;
      case UpdaterMessage.prompt:
        if (prompt != null) return prompt!;
        break;
    }

    // 2. Fallback to dictionary
    final language = languageCode ?? 'en';
    final dict = _vocabularies[language] ?? _vocabularies['en']!;

    switch (messageKey) {
      case UpdaterMessage.title:
        return dict['title']!;
      case UpdaterMessage.body:
        return dict['body']!;
      case UpdaterMessage.buttonTitleUpdate:
        return dict['buttonTitleUpdate']!;
      case UpdaterMessage.buttonTitleLater:
        return dict['buttonTitleLater']!;
      case UpdaterMessage.buttonTitleIgnore:
        return dict['buttonTitleIgnore']!;
      case UpdaterMessage.releaseNotes:
        return dict['releaseNotes']!;
      case UpdaterMessage.prompt:
        return dict['prompt']!;
    }
  }

  static const Map<String, Map<String, String>> _vocabularies = {
    'en': {
      'title': 'Update App?',
      'body':
          'A new version of {{appName}} is available! Version {{latestVersion}} is now available-you have {{currentInstalledVersion}}',
      'buttonTitleUpdate': 'Update Now',
      'buttonTitleLater': 'Later',
      'buttonTitleIgnore': 'Ignore',
      'releaseNotes': 'Release Notes',
      'prompt': 'Would you like to update it now?',
    },
    'ar': {
      'title': 'هل تريد تحديث التطبيق؟',
      'body': 'نسخة جديدة من {{appName}} متوفرة!',
      'buttonTitleUpdate': 'حدث الآن',
      'buttonTitleLater': 'لاحقاً',
      'buttonTitleIgnore': 'تجاهل',
      'releaseNotes': 'ملاحظات الإصدار',
      'prompt': 'هل ترغب في التحديث الآن؟',
    },
    'es': {
      'title': '¿Actualizar aplicación?',
      'body': '¡Hay una nueva versión de {{appName}} disponible!',
      'buttonTitleUpdate': 'Actualizar ahora',
      'buttonTitleLater': 'Más tarde',
      'buttonTitleIgnore': 'Ignorar',
      'releaseNotes': 'Notas de la versión',
      'prompt': '¿Te gustaría actualizar ahora?',
    },
    'fr': {
      'title': 'Mettre à jour l\'application ?',
      'body': 'Une nouvelle version de {{appName}} est disponible !',
      'buttonTitleUpdate': 'Mettre à jour',
      'buttonTitleLater': 'Plus tard',
      'buttonTitleIgnore': 'Ignorer',
      'releaseNotes': 'Notes de version',
      'prompt': 'Voulez-vous mettre à jour maintenant ?',
    },
    'de': {
      'title': 'App aktualisieren?',
      'body': 'Eine neue Version von {{appName}} ist verfügbar!',
      'buttonTitleUpdate': 'Jetzt aktualisieren',
      'buttonTitleLater': 'Später',
      'buttonTitleIgnore': 'Ignorieren',
      'releaseNotes': 'Versionshinweise',
      'prompt': 'Möchten Sie jetzt aktualisieren?',
    },
    'it': {
      'title': 'Aggiornare l\'app?',
      'body': 'È disponibile una nuova versione di {{appName}}!',
      'buttonTitleUpdate': 'Aggiorna ora',
      'buttonTitleLater': 'Più tardi',
      'buttonTitleIgnore': 'Ignora',
      'releaseNotes': 'Note di rilascio',
      'prompt': 'Vuoi aggiornare ora?',
    },
    'pt': {
      'title': 'Atualizar aplicativo?',
      'body': 'Uma nova versão do {{appName}} está disponível!',
      'buttonTitleUpdate': 'Atualizar agora',
      'buttonTitleLater': 'Mais tarde',
      'buttonTitleIgnore': 'Ignorar',
      'releaseNotes': 'Notas da versão',
      'prompt': 'Gostaria de atualizar agora?',
    },
    'ru': {
      'title': 'Обновить приложение?',
      'body': 'Доступна новая версия {{appName}}!',
      'buttonTitleUpdate': 'Обновить сейчас',
      'buttonTitleLater': 'Позже',
      'buttonTitleIgnore': 'Игнорировать',
      'releaseNotes': 'Примечания к выпуску',
      'prompt': 'Хотите обновить сейчас?',
    },
    'zh': {
      'title': '更新应用？',
      'body': '{{appName}} 有新版本可用！',
      'buttonTitleUpdate': '立即更新',
      'buttonTitleLater': '稍后',
      'buttonTitleIgnore': '忽略',
      'releaseNotes': '版本说明',
      'prompt': '您想现在更新吗？',
    },
    'ja': {
      'title': 'アプリを更新しますか？',
      'body': '{{appName}} の新しいバージョンが利用可能です！',
      'buttonTitleUpdate': '今すぐ更新',
      'buttonTitleLater': '後で',
      'buttonTitleIgnore': '無視',
      'releaseNotes': 'リリースノート',
      'prompt': '今すぐ更新しますか？',
    },
    'ko': {
      'title': '앱을 업데이트하시겠습니까?',
      'body': '{{appName}}의 새 버전을 사용할 수 있습니다!',
      'buttonTitleUpdate': '지금 업데이트',
      'buttonTitleLater': '나중에',
      'buttonTitleIgnore': '무시',
      'releaseNotes': '릴리스 노트',
      'prompt': '지금 업데이트하시겠습니까?',
    },
    'tr': {
      'title': 'Uygulamayı Güncelle?',
      'body': '{{appName}} uygulamasının yeni bir sürümü mevcut!',
      'buttonTitleUpdate': 'Şimdi Güncelle',
      'buttonTitleLater': 'Daha Sonra',
      'buttonTitleIgnore': 'Yoksay',
      'releaseNotes': 'Sürüm Notları',
      'prompt': 'Şimdi güncellemek ister misiniz?',
    },
    'vi': {
      'title': 'Cập nhật ứng dụng?',
      'body': 'Đã có phiên bản mới của {{appName}}!',
      'buttonTitleUpdate': 'Cập nhật ngay',
      'buttonTitleLater': 'Để sau',
      'buttonTitleIgnore': 'Bỏ qua',
      'releaseNotes': 'Ghi chú phát hành',
      'prompt': 'Bạn có muốn cập nhật ngay bây giờ không?',
    },
    'id': {
      'title': 'Perbarui Aplikasi?',
      'body': 'Versi baru {{appName}} tersedia!',
      'buttonTitleUpdate': 'Perbarui Sekarang',
      'buttonTitleLater': 'Nanti',
      'buttonTitleIgnore': 'Abaikan',
      'releaseNotes': 'Catatan Rilis',
      'prompt': 'Apakah Anda ingin memperbarui sekarang?',
    },
    'hi': {
      'title': 'ऐप अपडेट करें?',
      'body': '{{appName}} का एक नया संस्करण उपलब्ध है!',
      'buttonTitleUpdate': 'अभी अपडेट करें',
      'buttonTitleLater': 'बाद में',
      'buttonTitleIgnore': 'अनदेखा करें',
      'releaseNotes': 'रिलीज़ नोट',
      'prompt': 'क्या आप अभी अपडेट करना चाहेंगे?',
    },
    'bn': {
      'title': 'অ্যাপ আপডেট করবেন?',
      'body': '{{appName}} এর একটি নতুন সংস্করণ উপলব্ধ!',
      'buttonTitleUpdate': 'এখনই আপডেট করুন',
      'buttonTitleLater': 'পরে',
      'buttonTitleIgnore': 'এড়িয়ে যান',
      'releaseNotes': 'রিলিজ নোট',
      'prompt': 'আপনি কি এখনই আপডেট করতে চান?',
    },
    'da': {
      'title': 'Opdater app?',
      'body': 'Ny version af {{appName}} er tilgængelig!',
      'buttonTitleUpdate': 'Opdater nu',
      'buttonTitleLater': 'Senere',
      'buttonTitleIgnore': 'Ignorer',
      'releaseNotes': 'Udgivelsesnoter',
      'prompt': 'Vil du opdatere nu?',
    },
    'nl': {
      'title': 'App updaten?',
      'body': 'Een nieuwe versie van {{appName}} is beschikbaar!',
      'buttonTitleUpdate': 'Nu updaten',
      'buttonTitleLater': 'Later',
      'buttonTitleIgnore': 'Negeren',
      'releaseNotes': 'Release-opmerkingen',
      'prompt': 'Wilt u nu updaten?',
    },
    'fil': {
      'title': 'I-update ang App?',
      'body': 'May bagong bersyon ng {{appName}} na magagamit!',
      'buttonTitleUpdate': 'I-update Ngayon',
      'buttonTitleLater': 'Mamaya',
      'buttonTitleIgnore': 'Balewalain',
      'releaseNotes': 'Mga Tala sa Paglabas',
      'prompt': 'Gusto mo bang mag-update ngayon?',
    },
    'el': {
      'title': 'Ενημέρωση εφαρμογής;',
      'body': 'Μια νέα έκδοση του {{appName}} είναι διαθέσιμη!',
      'buttonTitleUpdate': 'Ενημέρωση τώρα',
      'buttonTitleLater': 'Αργότερα',
      'buttonTitleIgnore': 'Αγνόησε',
      'releaseNotes': 'Σημειώσεις έκδοσης',
      'prompt': 'Θέλετε να ενημερώσετε τώρα;',
    },
    'ht': {
      'title': 'Mete App la ajou?',
      'body': 'Yon nouvo vèsyon {{appName}} disponib!',
      'buttonTitleUpdate': 'Mete ajou kounye a',
      'buttonTitleLater': 'Pita',
      'buttonTitleIgnore': 'Inyore',
      'releaseNotes': 'Nòt lage',
      'prompt': 'Èske w ta renmen mete ajou kounye a?',
    },
    'he': {
      'title': 'לעדכן את האפליקציה?',
      'body': 'גרסה חדשה של {{appName}} זמינה!',
      'buttonTitleUpdate': 'עדכן עכשיו',
      'buttonTitleLater': 'מאוחר יותר',
      'buttonTitleIgnore': 'התעלם',
      'releaseNotes': 'הערות גרסה',
      'prompt': 'האם תרצה לעדכן עכשיו?',
    },
    'hu': {
      'title': 'Frissíti az alkalmazást?',
      'body': 'Új {{appName}} verzió érhető el!',
      'buttonTitleUpdate': 'Frissítés most',
      'buttonTitleLater': 'Később',
      'buttonTitleIgnore': 'Mellőzés',
      'releaseNotes': 'Kiadási megjegyzések',
      'prompt': 'Szeretné most frissíteni?',
    },
    'kk': {
      'title': 'Қолданбаны жаңарту керек пе?',
      'body': '{{appName}} жаңа нұсқасы қолжетімді!',
      'buttonTitleUpdate': 'Қазір жаңарту',
      'buttonTitleLater': 'Кейінірек',
      'buttonTitleIgnore': 'Елемеу',
      'releaseNotes': 'Шығарылым ескертпелері',
      'prompt': 'Қазір жаңартқыңыз келе ме?',
    },
    'km': {
      'title': 'ធ្វើបច្ចុប្បន្នភាពកម្មវិធី?',
      'body': 'មានកំណែថ្មីនៃ {{appName}} ហើយ!',
      'buttonTitleUpdate': 'ធ្វើបច្ចុប្បន្នភាពឥឡូវនេះ',
      'buttonTitleLater': 'ពេល​ក្រោយ',
      'buttonTitleIgnore': 'មិនអើពើ',
      'releaseNotes': 'កំណត់ចំណាំនៃកំណែ',
      'prompt': 'តើអ្នកចង់ធ្វើបច្ចុប្បន្នភាពឥឡូវនេះទេ?',
    },
    'ku': {
      'title': 'نوێکردنەوەی بەرنامە؟',
      'body': 'وەشانێکی نوێی {{appName}} بەردەستە!',
      'buttonTitleUpdate': 'نوێکردنەوە ئێستا',
      'buttonTitleLater': 'دواتر',
      'buttonTitleIgnore': 'فەرامۆشکردن',
      'releaseNotes': 'تێبینیەکانی وەشان',
      'prompt': 'ئایا دەتەوێت ئێستا نوێی بکەیتەوە؟',
    },
    'lt': {
      'title': 'Atnaujinti programėlę?',
      'body': 'Yra nauja {{appName}} versija!',
      'buttonTitleUpdate': 'Atnaujinti dabar',
      'buttonTitleLater': 'Vėliau',
      'buttonTitleIgnore': 'Ignoruoti',
      'releaseNotes': 'Išleidimo pastabos',
      'prompt': 'Ar norite atnaujinti dabar?',
    },
    'mn': {
      'title': 'Програмаа шинэчлэх үү?',
      'body': '{{appName}}-н шинэ хувилбар гарлаа!',
      'buttonTitleUpdate': 'Одоо шинэчлэх',
      'buttonTitleLater': 'Дараа',
      'buttonTitleIgnore': 'Алгосах',
      'releaseNotes': 'Хувилбарын тэмдэглэл',
      'prompt': 'Та одоо шинэчлэх үү?',
    },
    'nb': {
      'title': 'Oppdater app?',
      'body': 'En ny versjon av {{appName}} er tilgjengelig!',
      'buttonTitleUpdate': 'Oppdater nå',
      'buttonTitleLater': 'Senere',
      'buttonTitleIgnore': 'Ignorer',
      'releaseNotes': 'Utgivelsesnotater',
      'prompt': 'Vil du oppdatere nå?',
    },
    'fa': {
      'title': 'بروزرسانی برنامه؟',
      'body': 'نسخه جدید {{appName}} موجود است!',
      'buttonTitleUpdate': 'بروزرسانی',
      'buttonTitleLater': 'بعدا',
      'buttonTitleIgnore': 'نادیده گرفتن',
      'releaseNotes': 'توضیحات نسخه',
      'prompt': 'آیا می‌خواهید هم‌اکنون بروزرسانی کنید؟',
    },
    'pl': {
      'title': 'Zaktualizować aplikację?',
      'body': 'Dostępna jest nowa wersja {{appName}}!',
      'buttonTitleUpdate': 'Zaktualizuj teraz',
      'buttonTitleLater': 'Później',
      'buttonTitleIgnore': 'Ignoruj',
      'releaseNotes': 'Informacje o wydaniu',
      'prompt': 'Czy chcesz zaktualizować teraz?',
    },
    'ps': {
      'title': 'اپلیکیشن نوی کول؟',
      'body': 'د {{appName}} نوې بڼه شتون لري!',
      'buttonTitleUpdate': 'اوس نوی کړئ',
      'buttonTitleLater': 'وروسته',
      'buttonTitleIgnore': 'پریښودل',
      'releaseNotes': 'د خپرولو یادښتونه',
      'prompt': 'ایا تاسو غواړئ اوس نوی کړئ؟',
    },
    'ro': {
      'title': 'Actualizați aplicația?',
      'body': 'O nouă versiune a {{appName}} este disponibilă!',
      'buttonTitleUpdate': 'Actualizați acum',
      'buttonTitleLater': 'Mai târziu',
      'buttonTitleIgnore': 'Ignorați',
      'releaseNotes': 'Note de lansare',
      'prompt': 'Doriți să actualizați acum?',
    },
    'sv': {
      'title': 'Uppdatera appen?',
      'body': 'En ny version av {{appName}} finns tillgänglig!',
      'buttonTitleUpdate': 'Uppdatera nu',
      'buttonTitleLater': 'Senare',
      'buttonTitleIgnore': 'Ignorera',
      'releaseNotes': 'Versionsinformation',
      'prompt': 'Vill du uppdatera nu?',
    },
    'ta': {
      'title': 'செயலியைப் புதுப்பிக்கவா?',
      'body': '{{appName}}-in புதிய பதிப்பு கிடைக்கிறது!',
      'buttonTitleUpdate': 'இப்போது புதுப்பி',
      'buttonTitleLater': 'பிறகு',
      'buttonTitleIgnore': 'புறக்கணி',
      'releaseNotes': 'வெளியீட்டு குறிப்புகள்',
      'prompt': 'நீங்கள் இப்போது புதுப்பிக்க விரும்புகிறீர்களா?',
    },
    'te': {
      'title': 'యాప్‌ని అప్‌డేట్ చేయాలా?',
      'body': '{{appName}} కొత్త వెర్షన్ అందుబాటులో ఉంది!',
      'buttonTitleUpdate': 'ఇప్పుడే అప్‌డేట్ చేయండి',
      'buttonTitleLater': 'తర్వాత',
      'buttonTitleIgnore': 'వదిలేయండి',
      'releaseNotes': 'విడుదల గమనికలు',
      'prompt': 'మీరు ఇప్పుడే అప్‌డేట్ చేయాలనుకుంటున్నారా?',
    },
    'uk': {
      'title': 'Оновити додаток?',
      'body': 'Доступна нова версія {{appName}}!',
      'buttonTitleUpdate': 'Оновити зараз',
      'buttonTitleLater': 'Пізніше',
      'buttonTitleIgnore': 'Ігнорувати',
      'releaseNotes': 'Примітки до випуску',
      'prompt': 'Бажаєте оновити зараз?',
    },
    'uz': {
      'title': 'Ilovani yangilaysizmi?',
      'body': '{{appName}} ning yangi versiyasi mavjud!',
      'buttonTitleUpdate': 'Hozir yangilash',
      'buttonTitleLater': 'Keyinroq',
      'buttonTitleIgnore': 'E\'tiborsiz qoldirish',
      'releaseNotes': 'Chiqarish qaydlari',
      'prompt': 'Hozir yangilashni xohlaysizmi?',
    },
  };
}
