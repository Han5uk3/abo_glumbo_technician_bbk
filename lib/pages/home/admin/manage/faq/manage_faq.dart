import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/faq.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/faq/edit_faq.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageFaq extends StatefulWidget {
  const ManageFaq({super.key});

  @override
  State<ManageFaq> createState() => _ManageFaqState();
}

class _ManageFaqState extends State<ManageFaq> {
  // Tracks whether the delete confirmation/loading dialog is currently shown.
  bool _isDeletingDialogShowing = false;
  @override
  Widget build(BuildContext context) {
    bool isEnglish = Directionality.of(context) == TextDirection.ltr;
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.manageFaqs)),
      body: BlocListener<ManageAppBloc, ManageAppState>(
        listener: (context, state) {
          // Show the loading dialog only when deleting and it's not shown.
          if (state is DeletingFaq) {
            if (!_isDeletingDialogShowing) {
              _isDeletingDialogShowing = true;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  // constraints: BoxConstraints(
                  //   maxWidth: 100,
                  //   minWidth: 100,
                  //   maxHeight: 100,
                  // ),
                  backgroundColor: Colors.white,

                  content: Center(
                    child: SizedBox(height: 24, child: Loader(size: 20)),
                  ),
                ),
              ).then((_) => _isDeletingDialogShowing = false);
            }
          } else {
            // Only pop the root navigator if the delete dialog was shown.
            if (_isDeletingDialogShowing) {
              try {
                Navigator.of(context, rootNavigator: true).pop();
              } catch (_) {}
              _isDeletingDialogShowing = false;
            }
          }

          if (state is FaqDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.faqEntryDeletedSuccessfully,
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
            if (mounted) {
              Navigator.pop(context);
            }
          }

          if (state is FaqDeleteError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${AppLocalizations.of(context)!.error}: ${state.error}',
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.red,
              ),
            );
            if (mounted) {
              Navigator.pop(context);
            }
          }
        },
        child: StreamBuilder<List<FaqModel>>(
          stream: AppServices.getFaqStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                backgroundColor: Colors.white,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 24, child: Loader()),
                    SizedBox(height: 10),
                    Text(AppLocalizations.of(context)!.loadingFaqs),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '${AppLocalizations.of(context)!.error}: ${snapshot.error}',
                ),
              );
            }

            final faqEntries = snapshot.data ?? [];
            if (faqEntries.isEmpty) {
              return Center(
                child: Text(AppLocalizations.of(context)!.noFaqEntriesFound),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: 100,
              ),
              itemCount: faqEntries.length,
              itemBuilder: (context, index) {
                final entry = faqEntries[index];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // Optional: Navigate to detail view or expand
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question and action buttons row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Question icon
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.help_outline,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Question text
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEnglish
                                          ? entry.questionEn
                                          : entry.questionAr,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // Position badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${AppLocalizations.of(context)!.positionText}: ${entry.stand}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Edit button
                              Material(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddFaqPage(faq: entry, isEdit: true),
                                    ),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          AppLocalizations.of(context)!.edit,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Delete button
                              Material(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          confirmDeleteDialog(entry),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          size: 16,
                                          color: Colors.red.shade700,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          AppLocalizations.of(context)!.delete,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to AddFaqPage (to be implemented)
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddFaqPage(isEdit: false),
            ),
          );
        },
        tooltip: AppLocalizations.of(context)!.addFaq,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget confirmDeleteDialog(FaqModel entry) {
    return AlertDialog(
      backgroundColor: Colors.white,
      actionsAlignment: MainAxisAlignment.start,
      title: Text(AppLocalizations.of(context)!.deleteFaqEntry),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppLocalizations.of(context)!.areYouSureYouWantToDeleteThisFaqEntry,
          ),
          Text(AppLocalizations.of(context)!.thisActionCannotBeUndone),
        ],
      ),
      actions: [
        eButton(
          text: AppLocalizations.of(context)!.cancel,
          onPressed: () => Navigator.of(context).pop(),
          context: context,
          textColor: Colors.black,
          backgroundColor: Colors.white,
        ),
        eButton(
          text: AppLocalizations.of(context)!.delete,
          onPressed: () {
            context.read<ManageAppBloc>().add(DeleteFaqEvent(entry.id));
          },
          context: context,
          textColor: Colors.white,
          backgroundColor: Colors.red,
        ),
      ],
    );
  }
}
