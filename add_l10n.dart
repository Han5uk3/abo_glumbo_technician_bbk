import 'dart:convert';
import 'dart:io';

void main() async {
  final l10nDir = Directory('c:/Hansuke/Work/abo_glumbo_technician_bbk/lib/l10n');
  final enFile = File('${l10nDir.path}/app_en.arb');
  final arFile = File('${l10nDir.path}/app_ar.arb');
  final urFile = File('${l10nDir.path}/app_ur.arb');

  final newKeys = {
    'errorOccurred': {
      'en': 'Error: {error}',
      'ar': 'حدث خطأ: {error}',
      'ur': 'خرابی: {error}',
      'placeholders': {
        'error': {
          'type': 'String'
        }
      }
    },
    'cannotOpenFile': {
      'en': 'Cannot open file: {path}',
      'ar': 'لا يمكن فتح الملف: {path}',
      'ur': 'فائل نہیں کھولی جا سکی: {path}',
      'placeholders': {
        'path': {
          'type': 'String'
        }
      }
    },
    'failedToSendMessage': {
      'en': 'Failed to send message: {error}',
      'ar': 'فشل إرسال الرسالة: {error}',
      'ur': 'پیغام بھیجنے میں ناکام: {error}',
      'placeholders': {
        'error': {
          'type': 'String'
        }
      }
    },
    'failedToRetryMessage': {
      'en': 'Failed to retry message: {error}',
      'ar': 'فشل إعادة المحاولة: {error}',
      'ur': 'پیغام دوبارہ بھیجنے میں ناکام: {error}',
      'placeholders': {
        'error': {
          'type': 'String'
        }
      }
    },
    'noDataAvailable': {
      'en': 'No data available',
      'ar': 'لا توجد بيانات متاحة',
      'ur': 'کوئی ڈیٹا دستیاب نہیں'
    },
    'errorFetchingLocation': {
      'en': 'Error fetching location: {error}',
      'ar': 'خطأ في جلب الموقع: {error}',
      'ur': 'مقام لانے میں خرابی: {error}',
      'placeholders': {
        'error': {
          'type': 'String'
        }
      }
    },
    'registrationFailed': {
      'en': 'Registration failed: {error}',
      'ar': 'فشل التسجيل: {error}',
      'ur': 'رجسٹریشن ناکام ہو گئی: {error}',
      'placeholders': {
        'error': {
          'type': 'String'
        }
      }
    },
    'cancelLower': {
      'en': 'Cancel',
      'ar': 'إلغاء',
      'ur': 'منسوخ کریں'
    },
    'confirmRemoveAdmin': {
      'en': 'Are you sure you want to remove admin access for {name}?',
      'ar': 'هل أنت متأكد أنك تريد إزالة وصول المسؤول لـ {name}؟',
      'ur': 'کیا آپ واقعی {name} کی ایڈمن رسائی ختم کرنا چاہتے ہیں؟',
      'placeholders': {
        'name': {
          'type': 'String'
        }
      }
    },
    'adminAccessRevoked': {
      'en': 'Admin access revoked for {name}',
      'ar': 'تم إبطال وصول المسؤول لـ {name}',
      'ur': '{name} کی ایڈمن رسائی منسوخ کر دی گئی',
      'placeholders': {
        'name': {
          'type': 'String'
        }
      }
    },
    'inviteDeleted': {
      'en': 'Invite deleted for {name}',
      'ar': 'تم حذف دعوة {name}',
      'ur': '{name} کی دعوت حذف کر دی گئی',
      'placeholders': {
        'name': {
          'type': 'String'
        }
      }
    },
    'selectAll': {
      'en': 'Select All',
      'ar': 'تحديد الكل',
      'ur': 'سب منتخب کریں'
    },
    'locationTrackingStopped': {
      'en': 'Location tracking stopped',
      'ar': 'تم إيقاف تتبع الموقع',
      'ur': 'لوکیشن ٹریکنگ روک دی گئی'
    },
    'revokeAccess': {
      'en': 'Revoke',
      'ar': 'إلغاء الوصول',
      'ur': 'رسائی منسوخ کریں'
    }
  };

  void updateArb(File file, String lang) {
    if (!file.existsSync()) return;
    
    String content = file.readAsStringSync();
    Map<String, dynamic> arb = jsonDecode(content);
    
    bool changed = false;
    newKeys.forEach((key, data) {
      if (!arb.containsKey(key)) {
        arb[key] = data[lang];
        if (data.containsKey('placeholders') && lang == 'en') {
          arb['@$key'] = {'placeholders': data['placeholders']};
        }
        changed = true;
      }
    });
    
    if (changed) {
      file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(arb));
      print('Updated ${file.path}');
    } else {
      print('No changes needed for ${file.path}');
    }
  }

  updateArb(enFile, 'en');
  updateArb(arFile, 'ar');
  updateArb(urFile, 'ur');
}
