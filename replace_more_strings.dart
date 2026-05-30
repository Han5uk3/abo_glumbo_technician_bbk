import 'dart:io';

void main() {
  final replacements = {
    // chat_screen.dart
    "Text('Failed to send message: \$e')": "Text(AppLocalizations.of(context)?.failedToSendMessage(e.toString()) ?? 'Failed to send message: \$e')",
    "Text('Failed to retry message: \$e')": "Text(AppLocalizations.of(context)?.failedToRetryMessage(e.toString()) ?? 'Failed to retry message: \$e')",
    "label: 'Retry'": "label: AppLocalizations.of(context)?.retry ?? 'Retry'",
    
    // customer_management.dart
    "label: 'Chat'": "label: AppLocalizations.of(context)?.chat ?? 'Chat'",
    
    // add_admin.dart
    "label: 'Full Name'": "label: AppLocalizations.of(context)?.fullName ?? 'Full Name'",
    "hintText: 'Enter full name'": "hintText: AppLocalizations.of(context)?.enterFullName ?? 'Enter full name'",
    "label: 'Email Address'": "label: AppLocalizations.of(context)?.emailAddress ?? 'Email Address'",
    "hintText: 'Enter email address'": "hintText: AppLocalizations.of(context)?.enterEmailAddress ?? 'Enter email address'",
    "label: 'Phone Number'": "label: AppLocalizations.of(context)?.phoneNumber ?? 'Phone Number'",
    "hintText: 'e.g. 50XXXXXXX'": "hintText: AppLocalizations.of(context)?.phoneHintExample ?? 'e.g. 50XXXXXXX'",
    
    // edit_profile.dart
    "label: 'Certificate \${index + 1}'": "label: AppLocalizations.of(context)?.certificateNumberLabel((index + 1).toString()) ?? 'Certificate \${index + 1}'",
    
    // counter_propose_sheet.dart
    "label: 'Date'": "label: AppLocalizations.of(context)?.date ?? 'Date'",
    "label: 'Time'": "label: AppLocalizations.of(context)?.time ?? 'Time'",
    
    // edit_services_screen.dart
    "hintText: 'Name (Urdu)'": "hintText: AppLocalizations.of(context)?.nameUrdu ?? 'Name (Urdu)'",
    "hintText: 'Description (Urdu)'": "hintText: AppLocalizations.of(context)?.descriptionUrdu ?? 'Description (Urdu)'",
    
    // agent_info.dart
    'const Text("Cancel")': "Text(AppLocalizations.of(context)?.cancelLower ?? 'Cancel')",
    'hintText: "Enter reason for rejection"': "hintText: AppLocalizations.of(context)?.enterReasonForRejection ?? 'Enter reason for rejection'",
    
    // manage_admins.dart
    "hintText: 'Search admins...'": "hintText: AppLocalizations.of(context)?.searchAdmins ?? 'Search admins...'",
    
    // location_selector.dart
    "const Text('Select All'": "Text(AppLocalizations.of(context)?.selectAll ?? 'Select All'",
  };

  final dir = Directory('c:/Hansuke/Work/abo_glumbo_technician_bbk/lib');
  
  for (final file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      var content = file.readAsStringSync();
      var original = content;
      
      replacements.forEach((key, value) {
        content = content.replaceAll(key, value);
      });
      
      if (content != original) {
        file.writeAsStringSync(content);
        print('Updated \${file.path}');
      }
    }
  }
}
