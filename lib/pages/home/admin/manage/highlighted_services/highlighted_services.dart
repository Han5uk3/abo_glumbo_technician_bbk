import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/highlighted_services/edit_highlighted_services.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/highlighted_service.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 24, child: Loader()),
                  const SizedBox(height: 10),
                  Text(
                    AppLocalizations.of(context)!.loadingHighlightedServices,
                  ),
                ],
              ),
            );
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
