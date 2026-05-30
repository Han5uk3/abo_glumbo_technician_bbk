import 'dart:io';

void main() {
  final dir = Directory('c:/Hansuke/Work/abo_glumbo_technician_bbk/lib');
  
  for (final file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      var original = content;
      
      // Alignment
      content = content.replaceAll('Alignment.centerLeft', 'AlignmentDirectional.centerStart');
      content = content.replaceAll('Alignment.centerRight', 'AlignmentDirectional.centerEnd');
      content = content.replaceAll('Alignment.topLeft', 'AlignmentDirectional.topStart');
      content = content.replaceAll('Alignment.topRight', 'AlignmentDirectional.topEnd');
      content = content.replaceAll('Alignment.bottomLeft', 'AlignmentDirectional.bottomStart');
      content = content.replaceAll('Alignment.bottomRight', 'AlignmentDirectional.bottomEnd');

      // Replace simple EdgeInsets.only(left: X) with EdgeInsetsDirectional.only(start: X)
      content = content.replaceAllMapped(
        RegExp(r'EdgeInsets\.only\(([^)]*)\)'), 
        (match) {
          String inner = match.group(1)!;
          if (inner.contains('left:') || inner.contains('right:')) {
            inner = inner.replaceAll('left:', 'start:');
            inner = inner.replaceAll('right:', 'end:');
            return 'EdgeInsetsDirectional.only(\$inner)';
          }
          return match.group(0)!; // No change if no left/right
        }
      );

      // Positioned
      content = content.replaceAllMapped(
        RegExp(r'Positioned\(([^)]*)\)'),
        (match) {
          String inner = match.group(1)!;
          if (inner.contains('left:') || inner.contains('right:')) {
            inner = inner.replaceAll('left:', 'start:');
            inner = inner.replaceAll('right:', 'end:');
            // Adding textDirection requires context, which might not be available, but usually is.
            // Let's just use start/end with Positioned.directional
            return 'Positioned.directional(textDirection: Directionality.of(context), \$inner)';
          }
          return match.group(0)!;
        }
      );

      if (content != original) {
        file.writeAsStringSync(content);
        print('Updated \${file.path}');
      }
    }
  }
}
