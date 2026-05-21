import 'dart:developer';

import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ContactService {
  static Future<void> launchEmail(BuildContext context, String email) async {
    final url = "mailto:$email";
    log('Attempting to launch email: $url');
    try {
      final success = await launchUrlString(url);
      log('Email launch result: $success');
    } catch (e) {
      log('Cannot launch email: $url; Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch email client')),
        );
      }
    }
  }

  static Future<void> launchWhatsApp(BuildContext context, String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final whatsappUrl = 'https://wa.me/$cleanPhone';
    log('Attempting to launch WhatsApp: $whatsappUrl');
    try {
      final success = await launchUrlString(whatsappUrl, mode: LaunchMode.externalApplication);
      if (!success) {
        log('canLaunchUrlString returned false or failed; attempting fallback launch...');
        await launchUrlString(whatsappUrl);
      }
    } catch (e) {
      log('WhatsApp launch failed; attempting direct launch fallback... Error: $e');
      try {
        await launchUrlString(whatsappUrl);
      } catch (err) {
        log('All WhatsApp launch attempts failed: $err');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch WhatsApp')),
          );
        }
      }
    }
  }

  static Future<void> launchPhone(BuildContext context, String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final url = "tel:$cleanPhone";
    log('Attempting to launch phone: $url');
    try {
      if (await canLaunchUrlString(url)) {
        log('Url can be launched: $url');
        final success = await launchUrlString(url, mode: LaunchMode.externalNonBrowserApplication);
        log('Phone launch result: $success');
      } else {
        log('canLaunchUrlString returned false for: $url');
        // Try direct launch as fallback for some devices where canLaunch fails
        log('Attempting direct launch without canLaunch check...');
        final success = await launchUrlString(url, mode: LaunchMode.externalNonBrowserApplication);
        log('Direct phone launch result: $success');
      }
    } catch (e) {
      log('Error launching phone: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}

class ContactBottomSheet extends StatelessWidget {
  const ContactBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: StreamBuilder(
        stream: AppServices.getCustomerSupportdata(),
        builder: (context, asyncSnapshot) {
          if (asyncSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Loader(color: AppColors.primary));
          }
          if (asyncSnapshot.hasError) {
            return Center(
              child: Text(
                '${AppLocalizations.of(context)?.error ?? "Error"}: ${asyncSnapshot.error}',
              ),
            );
          }
          if (!asyncSnapshot.hasData || asyncSnapshot.data!.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)?.noSupportAvailable ??
                    "No support available",
              ),
            );
          }
          final data = asyncSnapshot.data!;

          log('Customer support data: ${data.map((e) => "${e.type}: ${e.detail}").toList()}');
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 60,
                decoration: BoxDecoration(
                  color: AppColors.grey1,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)?.contactSupportOptions ?? "",
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final type = data[index].type;
                    final content = data[index].detail;
                    if (data[index].isActive == false) {
                      return const SizedBox.shrink();
                    }
                    return _ContactOption(
                      icon: getIcon(type),
                      iconColor: getColor(type),
                      title: getTitle(type, context),
                      onTap: getOnTap(type, content, context),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

IconData getIcon(String type) {
  switch (type) {
    case "Email":
      return Icons.email;
    case "WhatsApp":
      return Icons.chat;
    case "Phone":
      return Icons.phone;
    default:
      return Icons.help_outline;
  }
}

Color getColor(String type) {
  switch (type) {
    case "Email":
      return AppColors.primary;
    case "WhatsApp":
      return Colors.green;
    case "Phone":
      return AppColors.secondary;
    default:
      return AppColors.black2;
  }
}

String getTitle(String type, BuildContext context) {
  switch (type) {
    case "Email":
      return AppLocalizations.of(context)?.contactByEmail ?? "";
    case "WhatsApp":
      return AppLocalizations.of(context)?.contactByWhatsApp ?? "";
    case "Phone":
      return AppLocalizations.of(context)?.contactByPhone ?? "";
    default:
      return AppLocalizations.of(context)?.contactByPhone ?? "";
  }
}

getOnTap(String type, String content, BuildContext context) {
  switch (type) {
    case "Email":
      return () async {
        await ContactService.launchEmail(context, content);
      };
    case "WhatsApp":
      return () async {
        await ContactService.launchWhatsApp(context, content);
      };
    case "Phone":
      return () async {
        await ContactService.launchPhone(context, content);
      };
    default:
      return () {};
  }
}

class _ContactOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _ContactOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: GoogleFonts.dmSans(fontSize: 16, color: AppColors.black1),
      ),
      onTap: onTap,
    );
  }
}
