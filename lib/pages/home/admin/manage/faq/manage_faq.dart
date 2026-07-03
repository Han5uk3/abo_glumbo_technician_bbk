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
  late Stream<List<FaqModel>> _faqStream;

  @override
  void initState() {
    super.initState();
    _faqStream = AppServices.getFaqStream();
  }

  @override
  Widget build(BuildContext context) {
    bool isEnglish = Directionality.of(context) == TextDirection.ltr;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
        title: Text(
          AppLocalizations.of(context)!.manageFaqs,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        shape: Border.all(style: BorderStyle.none),
      ),
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
                  backgroundColor: AppColors.bgWhite,
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
          stream: _faqStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: Loader());
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: faqEntries.length,
              itemBuilder: (context, index) {
                final entry = faqEntries[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.help_outline_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isEnglish
                                        ? entry.questionEn
                                        : entry.questionAr,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${AppLocalizations.of(context)!.positionText}: ${entry.stand}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddFaqPage(faq: entry, isEdit: true),
                                ),
                              ),
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      confirmDeleteDialog(entry),
                                );
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
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
      backgroundColor: AppColors.bgWhite,
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
          backgroundColor: AppColors.bgWhite,
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
