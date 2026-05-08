import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/account/bloc/account_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/account/widgets/language_dialog.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class LanguageSelectorCard extends StatelessWidget {
  final bool isInLoginPage;

  const LanguageSelectorCard({super.key, required this.isInLoginPage});

  static String _getFlag(String code) {
    switch (code) {
      case 'ar':
        return '🇸🇦';
      case 'ur':
        return '🇵🇰';
      default:
        return '🇬🇧';
    }
  }

  static String _getLanguageLabel(String code) {
    switch (code) {
      case 'ar':
        return 'العربية';
      case 'ur':
        return 'اردو';
      default:
        return 'EN';
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final currentCode = context.read<AccountBloc>().state.locale.languageCode;

    showDialog(
      context: context,
      builder: (dialogContext) => LanguageSelectionDialog(
        title:
            AppLocalizations.of(context)?.selectLanguage ?? 'Select Language',
        currentLanguageCode: currentCode,
        onEnglishSelected: () {
          context.read<AccountBloc>().add(ChangeLanguageEvent('en'));
        },
        onArabicSelected: () {
          context.read<AccountBloc>().add(ChangeLanguageEvent('ar'));
        },
        onUrduSelected: () {
          context.read<AccountBloc>().add(ChangeLanguageEvent('ur'));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountBloc, AccountState>(
      builder: (context, state) {
        final currentCode = state.locale.languageCode;
        final flag = _getFlag(currentCode);
        final label = _getLanguageLabel(currentCode);

        return GestureDetector(
          onTap: () => _showLanguageDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(flag, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: AppColors.black1,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.black1,
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
