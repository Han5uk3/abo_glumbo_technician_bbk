import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';

class SavingStackWidget extends StatelessWidget {
  const SavingStackWidget({
    super.key,
    required this.isSaving,
    required this.isLoading,
    required this.child,
    this.progress,
  });
  final bool isSaving;
  final bool isLoading;
  final Widget child;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: Loader(color: AppColors.primary));
    }
    return Stack(
      children: [
        child,
        if (isSaving)
          Container(
            color: Colors.black54,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(child: Loader(color: Colors.white)),
                const SizedBox(height: 32, width: double.infinity),
                Text(
                  (progress == 1 || progress == 0 || progress == null)
                      ? AppLocalizations.of(context)?.saving ?? 'Saving...'
                      : AppLocalizations.of(context)?.uploading ??
                            'Uploading...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
