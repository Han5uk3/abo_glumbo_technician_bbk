import 'dart:convert';
import 'dart:io';

void main() async {
  final updates = {
    'app_en.arb': {
      'urduName': 'Urdu Name',
      'enterUrduName': 'Enter Urdu name',
      'pleaseEnterUrduName': 'Please enter Urdu name',
      'pleaseEnterUrduNameOnly': 'Please enter Urdu name only',
      'searchForZones': 'Search for zones...',
      'failedToSearchForZones': 'Failed to search for zones. Please try again.',
    },
    'app_ar.arb': {
      'urduName': 'الاسم بالأردية',
      'enterUrduName': 'أدخل الاسم بالأردية',
      'pleaseEnterUrduName': 'يرجى إدخال الاسم بالأردية',
      'pleaseEnterUrduNameOnly': 'يرجى إدخال الاسم بالأردية فقط',
      'searchForZones': 'البحث عن المناطق...',
      'failedToSearchForZones': 'فشل البحث عن المناطق. يرجى المحاولة مرة أخرى.',
    },
    'app_ur.arb': {
      'urduName': 'اردو نام',
      'enterUrduName': 'اردو نام درج کریں',
      'pleaseEnterUrduName': 'براہ کرم اردو نام درج کریں',
      'pleaseEnterUrduNameOnly': 'براہ کرم صرف اردو نام درج کریں',
      'searchForZones': 'علاقوں کے لیے تلاش کریں...',
      'failedToSearchForZones':
          'علاقوں کی تلاش میں ناکامی۔ براہ کرم دوبارہ کوشش کریں۔',
    },
  };

  for (final file in ['app_en.arb', 'app_ar.arb', 'app_ur.arb']) {
    final f = File('lib/l10n/$file');
    if (await f.exists()) {
      final content = await f.readAsString();
      Map<String, dynamic> data = jsonDecode(content);
      updates[file]!.forEach((key, value) {
        data[key] = value;
      });
      final newContent = JsonEncoder.withIndent('  ').convert(data);
      await f.writeAsString(newContent);
    }
  }
}
