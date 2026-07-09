import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/highlighted_services/edit_highlighted_services.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/highlighted_service.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/shimmer_loading.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';

import 'package:flutter/material.dart';

class HighlightedServices extends StatelessWidget {
  const HighlightedServices({super.key});

  @override
  Widget build(BuildContext context) {
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
          AppLocalizations.of(context)?.highlightedServices ??
              'Highlighted Services',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        shape: Border.all(style: BorderStyle.none),
      ),
      body: StreamBuilder(
        stream: AppServices.getAllHighlightedServicesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ManageShimmerLoading();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                AppLocalizations.of(
                      context,
                    )?.errorOccurred(snapshot.error.toString()) ??
                    'Error: ${snapshot.error}',
              ),
            );
          }

          final highlightedServices = snapshot.data ?? [];
          return ListView.builder(
            padding: EdgeInsets.only(top: 16, bottom: 100),
            itemCount: highlightedServices.length,
            itemBuilder: (context, index) {
              final service = highlightedServices[index];
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16,
                    ),
                    child: HighlightedServiceWidget(
                      data: service,
                      editCallback: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddHighlightedServices(service: service),
                        ),
                      ),
                      deleteCallback: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) {
                            return AlertDialog(
                              backgroundColor: Colors.white,
                              title: Text(
                                AppLocalizations.of(dialogContext)?.delete ??
                                    'Delete',
                              ),
                              content: Text(
                                AppLocalizations.of(
                                      dialogContext,
                                    )?.deleteItemConfirmation ??
                                    'Are you sure you want to delete this item?',
                              ),
                              actionsAlignment: MainAxisAlignment.start,
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: Text(
                                    AppLocalizations.of(
                                          dialogContext,
                                        )?.cancel ??
                                        'Cancel',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: Text(
                                    AppLocalizations.of(
                                          dialogContext,
                                        )?.delete ??
                                        'Delete',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmed == true && service.id != null) {
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          try {
                            await AppFirestore.highlightedServicesCollectionRef
                                .doc(service.id)
                                .delete();
                            if (context.mounted) {
                              Navigator.of(context).pop(); // pop loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(
                                          context,
                                        )?.deletedSuccessfully ??
                                        'Deleted successfully',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.of(context).pop(); // pop loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddHighlightedServices()),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
