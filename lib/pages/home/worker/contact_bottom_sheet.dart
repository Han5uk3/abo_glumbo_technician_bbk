
import 'package:aboglumbo_bbk_panel/common_widget/cached_async_builder.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ContactService {
  static Future<void> launchEmail(BuildContext context, String email) async {
    final url = "mailto:$email";
    try {
      await launchUrlString(url);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.couldNotLaunchEmail ??
                  'Could not launch email client',
            ),
          ),
        );
      }
    }
  }

  static Future<void> launchWhatsApp(
    BuildContext context,
    String phoneNumber,
  ) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final whatsappUrl = 'https://wa.me/$cleanPhone';
    try {
      final success = await launchUrlString(
        whatsappUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!success) {
        await launchUrlString(whatsappUrl);
      }
    } catch (e) {
      try {
        await launchUrlString(whatsappUrl);
      } catch (err) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.couldNotLaunchWhatsapp ??
                    'Could not launch WhatsApp',
              ),
            ),
          );
        }
      }
    }
  }

  static Future<void> launchPhone(
    BuildContext context,
    String phoneNumber,
  ) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final url = "tel:$cleanPhone";
    try {
      // canLaunch is unreliable for tel: on some devices; launch either way.
      await launchUrlString(
        url,
        mode: LaunchMode.externalNonBrowserApplication,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.errorOccurred(e.toString()) ??
                  'Error: ${e.toString()}',
            ),
          ),
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
      child: CachedStreamBuilder(
        create: () => AppServices.getCustomerSupportdata(),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        style: TextStyle(fontSize: 16, color: AppColors.black1),
      ),
      onTap: onTap,
    );
  }
}
