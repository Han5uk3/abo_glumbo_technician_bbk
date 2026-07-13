import 'package:arabic_reshaper/arabic_reshaper.dart';

void main() {
  String urduText = 'پاکستان';
  String reshaped = ArabicReshaper.instance.reshape(urduText);
  print('Original: $urduText');
  print('Reshaped: $reshaped');
  
  // Also check if characters are changed to presentation forms
  for (int i = 0; i < reshaped.length; i++) {
    print(reshaped[i] + ' - ' + reshaped.codeUnitAt(i).toRadixString(16));
  }
}
