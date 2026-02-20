import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/services/edit_services_screen.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/service_tile.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:flutter/material.dart';

class ManageServices extends StatelessWidget {
  const ManageServices({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.services)),
      body: StreamBuilder(
        stream: AppServices.getAllServicesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 24, child: Loader()),
                const SizedBox(height: 10),
                Text(AppLocalizations.of(context)!.loadingServices),
              ],
            ));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final services = snapshot.data ?? [];
          return ListView.builder(
            padding: EdgeInsets.only(top: 16, bottom: 100),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return ServiceTileDevWidget(service: service);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddServicesDevPage()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
