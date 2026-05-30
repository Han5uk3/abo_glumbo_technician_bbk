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
  
  // 1. Error: $e or Error: ${e.toString()}
  final errorReplacements = {
    "Text('Error: \${e.toString()}')": "Text(AppLocalizations.of(context)?.errorOccurred(e.toString()) ?? 'Error: \${e.toString()}')",
    "Text('Error: \$e')": "Text(AppLocalizations.of(context)?.errorOccurred(e.toString()) ?? 'Error: \$e')",
    "Text('Error: \${snapshot.error}')": "Text(AppLocalizations.of(context)?.errorOccurred(snapshot.error.toString()) ?? 'Error: \${snapshot.error}')",
  };
  
  replaceInFile('$basePath/pages/bookings/booking_info.dart', errorReplacements);
  replaceInFile('$basePath/pages/bookings/broadcast_offer_info.dart', errorReplacements);
  replaceInFile('$basePath/pages/bookings/warranty_controllers.dart', errorReplacements);
  replaceInFile('$basePath/common_widget/booking_cards.dart', errorReplacements);
  replaceInFile('$basePath/pages/home/worker/contact_bottom_sheet.dart', errorReplacements);
  replaceInFile('$basePath/pages/home/admin/manage/payouts/manage_unified_payouts.dart', errorReplacements);
  replaceInFile('$basePath/pages/home/admin/admin_dashboard.dart', errorReplacements);
  replaceInFile('$basePath/pages/home/admin/manage/highlighted_services/highlighted_services.dart', errorReplacements);
  replaceInFile('$basePath/pages/home/admin/manage/services/manage_services.dart', errorReplacements);
  replaceInFile('$basePath/pages/home/admin/manage/admins/add_admin.dart', errorReplacements);
  replaceInFile('$basePath/pages/home/admin/manage/agents/agent_info.dart', errorReplacements);
  replaceInFile('$basePath/pages/home/admin/manage/admins/manage_admins.dart', errorReplacements);
  
  // 2. Edit Profile
  replaceInFile('$basePath/pages/account/edit_profile.dart', {
    "Text('Cannot open file: \${file.path}')": "Text(AppLocalizations.of(context)?.cannotOpenFile(file.path) ?? 'Cannot open file: \${file.path}')",
  });
  
  // 3. Chat Screen
  replaceInFile('$basePath/pages/chat_screen.dart', {
    "Text('Failed to send message: \$e')": "Text(AppLocalizations.of(context)?.failedToSendMessage(e.toString()) ?? 'Failed to send message: \$e')",
    "Text('Failed to retry message: \$e')": "Text(AppLocalizations.of(context)?.failedToRetryMessage(e.toString()) ?? 'Failed to retry message: \$e')",
  });
  
  // 4. Admin Dashboard
  replaceInFile('$basePath/pages/home/admin/admin_dashboard.dart', {
    "Text('No data available')": "Text(AppLocalizations.of(context)?.noDataAvailable ?? 'No data available')",
  });
  
  // 5. Signup
  replaceInFile('$basePath/pages/login/signup.dart', {
    "Text('Error fetching location: \$e')": "Text(AppLocalizations.of(context)?.errorFetchingLocation(e.toString()) ?? 'Error fetching location: \$e')",
    "Text('Registration failed: \$e')": "Text(AppLocalizations.of(context)?.registrationFailed(e.toString()) ?? 'Registration failed: \$e')",
  });
  
  // 6. Agent info
  replaceInFile('$basePath/pages/home/admin/manage/agents/agent_info.dart', {
    "Text(\"Cancel\")": "Text(AppLocalizations.of(context)?.cancelLower ?? 'Cancel')",
  });
  
  // 7. Manage Admins
  replaceInFile('$basePath/pages/home/admin/manage/admins/manage_admins.dart', {
    "Text('Are you sure you want to remove admin access for \$adminName?')": "Text(AppLocalizations.of(context)?.confirmRemoveAdmin(adminName) ?? 'Are you sure you want to remove admin access for \$adminName?')",
    "Text('Admin access revoked for \${admin.name}')": "Text(AppLocalizations.of(context)?.adminAccessRevoked(admin.name) ?? 'Admin access revoked for \${admin.name}')",
    "Text('Invite deleted for \${admin.name}')": "Text(AppLocalizations.of(context)?.inviteDeleted(admin.name) ?? 'Invite deleted for \${admin.name}')",
  });
  
  // 8. Location Selector
  replaceInFile('$basePath/common_widget/location_selector.dart', {
    "Text('Select All',": "Text(AppLocalizations.of(context)?.selectAll ?? 'Select All',",
  });
  
  // 9. Location Tracking Widget
  replaceInFile('$basePath/common_widget/location_tracking_widget.dart', {
    "Text('Location tracking stopped')": "Text(AppLocalizations.of(context)?.locationTrackingStopped ?? 'Location tracking stopped')",
  });
}
