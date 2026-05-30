import 'dart:io';

void main() {
  final dir = Directory('c:/Hansuke/Work/abo_glumbo_technician_bbk/lib');
  final regexes = [
    RegExp(r"Text\(\s*(const\s+)?'([^']+)'\s*\)"),
    RegExp(r'Text\(\s*(const\s+)?"([^"]+)"\s*\)')
  ];
  
  for (final file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      final lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        for (final regex in regexes) {
          final matches = regex.allMatches(line);
          for (final match in matches) {
            final text = match.group(2);
            print('${file.path}:$i -> $text');
          }
        }
      }
    }
  }
}
