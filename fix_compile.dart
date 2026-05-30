import 'dart:io';

void replaceInFile(String path, Map<String, String> replacements) {
  final file = File(path);
  if (!file.existsSync()) {
    print('File not found: $path');
    return;
  }
  
  String content = file.readAsStringSync();
  bool changed = false;
  
  replacements.forEach((target, replacement) {
    if (content.contains(target)) {
      content = content.replaceAll(target, replacement);
      changed = true;
    }
  });
  
  if (changed) {
    file.writeAsStringSync(content);
    print('Updated $path');
  } else {
    print('No changes needed for $path');
  }
}

void main() {
  final basePath = 'c:/Hansuke/Work/abo_glumbo_technician_bbk/lib';
  
  // 1. location_selector.dart
  replaceInFile('$basePath/common_widget/location_selector.dart', {
    "const Text(AppLocalizations.of(context)?.selectAll ?? 'Select All', style: TextStyle(fontSize: 12))": 
    "Text(AppLocalizations.of(context)?.selectAll ?? 'Select All', style: const TextStyle(fontSize: 12))",
    "const Text(AppLocalizations.of(context)?.selectAll ?? 'Select All',)": 
    "Text(AppLocalizations.of(context)?.selectAll ?? 'Select All',)",
  });
  
  // 2. admin_dashboard.dart
  replaceInFile('$basePath/pages/home/admin/admin_dashboard.dart', {
    "return const Center(child: Text(AppLocalizations.of(context)?.noDataAvailable ?? 'No data available'));": 
    "return Center(child: Text(AppLocalizations.of(context)?.noDataAvailable ?? 'No data available'));",
  });
  
  // 3. agent_info.dart
  replaceInFile('$basePath/pages/home/admin/manage/agents/agent_info.dart', {
    "child: const Text(AppLocalizations.of(context)?.cancelLower ?? 'Cancel'),": 
    "child: Text(AppLocalizations.of(context)?.cancelLower ?? 'Cancel'),",
  });
  
  // 4. edit_profile.dart
  replaceInFile('$basePath/pages/account/edit_profile.dart', {
    "AppLocalizations.of(context)?.cannotOpenFile(file.path)": 
    "AppLocalizations.of(context)?.cannotOpenFile(file.path ?? '')",
  });
  
  // 5. signup.dart
  replaceInFile('$basePath/pages/login/signup.dart', {
    "AppLocalizations.of(context)?.registrationFailed(e.toString())": 
    "'\${AppLocalizations.of(context)?.registrationFailed} \${e.toString()}'",
  });
}
