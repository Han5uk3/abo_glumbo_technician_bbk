import 'dart:convert';
import 'dart:io';

void main() {
  final keys = {
    'failedToSendMessage': {
      'en': 'Failed to send message: {error}',
      'ar': 'فشل إرسال الرسالة: {error}',
      'ur': 'پیغام بھیجنے میں ناکامی: {error}',
      'placeholders': {'error': {'type': 'String'}}
    },
    'failedToRetryMessage': {
      'en': 'Failed to retry message: {error}',
      'ar': 'فشل إعادة إرسال الرسالة: {error}',
      'ur': 'پیغام دوبارہ بھیجنے میں ناکامی: {error}',
      'placeholders': {'error': {'type': 'String'}}
    },
    'chat': {
      'en': 'Chat',
      'ar': 'دردشة',
      'ur': 'بات چیت'
    },
    'enterFullName': {
      'en': 'Enter full name',
      'ar': 'أدخل الاسم الكامل',
      'ur': 'پورا نام درج کریں'
    },
    'emailAddress': {
      'en': 'Email Address',
      'ar': 'البريد الإلكتروني',
      'ur': 'ای میل ایڈریس'
    },
    'enterEmailAddress': {
      'en': 'Enter email address',
      'ar': 'أدخل البريد الإلكتروني',
      'ur': 'ای میل ایڈریس درج کریں'
    },
    'phoneHintExample': {
      'en': 'e.g. 50XXXXXXX',
      'ar': 'مثال 50XXXXXXX',
      'ur': 'مثال کے طور پر 50XXXXXXX'
    },
    'certificateNumberLabel': {
      'en': 'Certificate {number}',
      'ar': 'شهادة {number}',
      'ur': 'سرٹیفکیٹ {number}',
      'placeholders': {'number': {'type': 'String'}}
    },
    'nameUrdu': {
      'en': 'Name (Urdu)',
      'ar': 'الاسم (أوردو)',
      'ur': 'نام (اردو)'
    },
    'descriptionUrdu': {
      'en': 'Description (Urdu)',
      'ar': 'الوصف (أوردو)',
      'ur': 'تفصیل (اردو)'
    },
    'enterReasonForRejection': {
      'en': 'Enter reason for rejection',
      'ar': 'أدخل سبب الرفض',
      'ur': 'مسترد کرنے کی وجہ درج کریں'
    }
  };

  final Map<String, String> files = {
    'en': 'c:/Hansuke/Work/abo_glumbo_technician_bbk/lib/l10n/app_en.arb',
    'ar': 'c:/Hansuke/Work/abo_glumbo_technician_bbk/lib/l10n/app_ar.arb',
    'ur': 'c:/Hansuke/Work/abo_glumbo_technician_bbk/lib/l10n/app_ur.arb'
  };

  for (final lang in files.keys) {
    final file = File(files[lang]!);
    final content = file.readAsStringSync();
    
    try {
      final Map<String, dynamic> jsonMap = json.decode(content);
      
      for (final key in keys.keys) {
        final entry = keys[key]!;
        jsonMap[key] = entry[lang];
        
        if (entry.containsKey('placeholders') && lang == 'en') {
          jsonMap['@$key'] = {
            'placeholders': entry['placeholders']
          };
        }
      }
      
      final encoder = JsonEncoder.withIndent('  ');
      file.writeAsStringSync(encoder.convert(jsonMap));
      print('Updated $lang ARB file');
    } catch (e) {
      print('Error parsing ${files[lang]}: $e');
    }
  }
}
