import 'dart:convert';
import 'dart:io';

// Translations to add to English (keys that only exist in AR)
final Map<String, String> enAdditions = {
  'bookingDate': 'Booking Date',
  'yourAccountIsBeingVerified': 'Your account is being verified by the admin. Please check back later.',
  'aboGlumboWorker': 'Abo Glumbo Technician',
  'workerCannotBeAssignedMultipleTimes': 'The same technician cannot be assigned to more than one booking at the same time. Please choose a different time or another technician.',
  'unknownWorker': 'Unknown Technician',
  'workerCancelled': 'Booking was cancelled by the technician',
  'cancelledByWorker': 'Cancelled by Technician',
  'workerPreviouslyCancelled': 'Technician previously cancelled',
  'workerCancelledAtTime': 'This technician previously cancelled a booking at the same time. It is recommended to assign another technician for better reliability.',
  'workerRestrictedTitle': 'Technician Restricted',
  'cannotAssignCancelledWorker': 'Cannot assign a technician who previously cancelled',
  'workerCancelledRestrictionMessage': 'This technician previously cancelled a booking and is now restricted from new assignments. Please choose a different technician.',
  'managefaqs': 'Manage FAQs',
  'manageWorkers': 'Manage Technicians',
  'noWorkersMatchYourFilters': 'No technicians match your search criteria',
  'workerInformation': 'Technician Information',
  'loadingWorkers': 'Loading Technicians...',
  'serviceDeletedSuccessfully': 'Service deleted successfully',
  'netTechnicianror': 'An error occurred while loading technicians',
  'urdu': 'Urdu',
  'allTime': 'All Time',
};

// Translations to add to Arabic
final Map<String, String> arAdditions = {
  'urdu': 'أوردو',
  'allTime': 'كل الوقت',
};

// Translations to add to Urdu (from AR values + new)
final Map<String, String> urAdditions = {
  'bookingDate': 'بکنگ کی تاریخ',
  'yourAccountIsBeingVerified': 'آپ کا اکاؤنٹ ایڈمن کے ذریعے تصدیق ہو رہا ہے۔ براہ کرم بعد میں دوبارہ چیک کریں۔',
  'aboGlumboWorker': 'ابو گلمبو ٹیکنیشن',
  'workerCannotBeAssignedMultipleTimes': 'ایک ہی ٹیکنیشن کو ایک ہی وقت میں ایک سے زیادہ بکنگ پر تفویض نہیں کیا جا سکتا۔ براہ کرم مختلف وقت یا دوسرا ٹیکنیشن منتخب کریں۔',
  'unknownWorker': 'نامعلوم ٹیکنیشن',
  'workerCancelled': 'بکنگ ٹیکنیشن کے ذریعے منسوخ کی گئی',
  'cancelledByWorker': 'ٹیکنیشن کے ذریعے منسوخ',
  'workerPreviouslyCancelled': 'ٹیکنیشن نے پہلے منسوخ کیا',
  'workerCancelledAtTime': 'اس ٹیکنیشن نے ایک ہی وقت میں پہلے بکنگ منسوخ کی تھی۔ بہتر قابل اعتمادی کے لیے کسی اور ٹیکنیشن کو تفویض کرنے کی سفارش کی جاتی ہے۔',
  'workerRestrictedTitle': 'ٹیکنیشن پابند',
  'cannotAssignCancelledWorker': 'ایسے ٹیکنیشن کو تفویض نہیں کیا جا سکتا جس نے پہلے منسوخ کیا ہو',
  'workerCancelledRestrictionMessage': 'اس ٹیکنیشن نے پہلے بکنگ منسوخ کی ہے اور اب نئی تفویض سے محدود ہے۔ براہ کرم کوئی اور ٹیکنیشن منتخب کریں۔',
  'managefaqs': 'اکثر پوچھے گئے سوالات کا انتظام',
  'manageWorkers': 'ٹیکنیشنز کا انتظام',
  'noWorkersMatchYourFilters': 'آپ کی تلاش کے معیار سے کوئی ٹیکنیشن مطابقت نہیں رکھتا',
  'workerInformation': 'ٹیکنیشن کی معلومات',
  'loadingWorkers': 'ٹیکنیشنز لوڈ ہو رہے ہیں...',
  'serviceDeletedSuccessfully': 'سروس کامیابی سے حذف ہو گئی',
  'netTechnicianror': 'ٹیکنیشنز لوڈ کرتے وقت خرابی پیش آئی',
  'allTime': 'ہر وقت',
};

String removeDuplicateKey(String content, String keyToRemove) {
  // Remove the entry with the exact casing specified
  // We remove from the first occurrence and keep the second (camelCase postCode)
  final pattern = RegExp('  "$keyToRemove": "[^"]*",?\\n');
  final matches = pattern.allMatches(content).toList();
  if (matches.length > 1) {
    // Remove only the FIRST occurrence
    final firstMatch = matches.first;
    content = content.substring(0, firstMatch.start) + content.substring(firstMatch.end);
    print('Removed duplicate key: $keyToRemove');
  }
  return content;
}

void main() {
  final enFile = File('lib/l10n/app_en.arb');
  final arFile = File('lib/l10n/app_ar.arb');
  final urFile = File('lib/l10n/app_ur.arb');

  // Fix duplicate keys first (raw string manipulation before JSON decode)
  var enRaw = enFile.readAsStringSync();
  var arRaw = arFile.readAsStringSync();
  var urRaw = urFile.readAsStringSync();

  // Remove the duplicate lowercase 'postcode' entries, keeping camelCase 'postCode'
  enRaw = removeDuplicateKey(enRaw, 'postcode');
  enRaw = removeDuplicateKey(enRaw, 'postcodeIsRequired');
  arRaw = removeDuplicateKey(arRaw, 'postcode');
  arRaw = removeDuplicateKey(arRaw, 'postcodeIsRequired');

  // Parse JSON
  final enJson = json.decode(enRaw) as Map<String, dynamic>;
  final arJson = json.decode(arRaw) as Map<String, dynamic>;
  final urJson = json.decode(urRaw) as Map<String, dynamic>;

  // Apply additions
  enAdditions.forEach((k, v) { enJson.putIfAbsent(k, () => v); });
  arAdditions.forEach((k, v) { arJson.putIfAbsent(k, () => v); });
  urAdditions.forEach((k, v) { urJson.putIfAbsent(k, () => v); });

  // Write back
  const encoder = JsonEncoder.withIndent('  ');
  enFile.writeAsStringSync(encoder.convert(enJson));
  arFile.writeAsStringSync(encoder.convert(arJson));
  urFile.writeAsStringSync(encoder.convert(urJson));

  print('Done syncing ARB files.');
}
