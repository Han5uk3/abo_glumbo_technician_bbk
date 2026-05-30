import 'dart:convert';
import 'dart:io';

void main() {
  final enFile = File('c:/Hansuke/Work/abo_glumbo_technician_bbk/lib/l10n/app_en.arb');
  final arFile = File('c:/Hansuke/Work/abo_glumbo_technician_bbk/lib/l10n/app_ar.arb');
  final urFile = File('c:/Hansuke/Work/abo_glumbo_technician_bbk/lib/l10n/app_ur.arb');

  final enJson = json.decode(enFile.readAsStringSync()) as Map<String, dynamic>;
  final arJson = json.decode(arFile.readAsStringSync()) as Map<String, dynamic>;
  final urJson = json.decode(urFile.readAsStringSync()) as Map<String, dynamic>;

  final enKeys = enJson.keys.where((k) => !k.startsWith('@')).toSet();
  final arKeys = arJson.keys.where((k) => !k.startsWith('@')).toSet();
  final urKeys = urJson.keys.where((k) => !k.startsWith('@')).toSet();

  final allKeys = enKeys.union(arKeys).union(urKeys);

  final missingInEn = allKeys.difference(enKeys);
  final missingInAr = allKeys.difference(arKeys);
  final missingInUr = allKeys.difference(urKeys);

  print('--- Missing in English ---');
  missingInEn.forEach(print);
  
  print('\\n--- Missing in Arabic ---');
  missingInAr.forEach(print);
  
  print('\\n--- Missing in Urdu ---');
  missingInUr.forEach(print);
}
