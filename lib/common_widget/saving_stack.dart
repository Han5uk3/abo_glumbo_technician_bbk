import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
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
      return const Center(
        child: CircularProgressIndicator(),
      );
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
                Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    value: (progress == 1 || progress == 0) ? null : progress,
                  ),
                ),
                const SizedBox(height: 32, width: double.infinity),
                Text(
                  (progress == 1 || progress == 0 || progress == null)
                      ? AppLocalizations.of(context)?.saving ?? 'Saving...'
                      : AppLocalizations.of(context)?.uploading ??
                          'Uploading...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
