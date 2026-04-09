import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/services/edit_services_screen.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/service_tile.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/models/service.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/app_color.dart';
import 'package:flutter/material.dart';

class ManageServices extends StatelessWidget {
  const ManageServices({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.manageServices),
        leading: IconButton(
          iconSize: 18,
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        ),
      ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: AppFirestore.categoriesCollectionRef.snapshots().map(
          (s) => s.docs.map((d) => CategoryModel.fromQuerySnapshot(d)).toList(),
        ),
        builder: (context, catSnapshot) {
          final categories = catSnapshot.data ?? [];

          return StreamBuilder<List<ServiceModel>>(
            stream: AppServices.getAllServicesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 24, child: Loader()),
                      const SizedBox(height: 10),
                      Text(AppLocalizations.of(context)!.loadingServices),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final services = snapshot.data ?? [];
              final languageCode = Localizations.localeOf(context).languageCode;

              // Group services by category name
              final Map<String, List<ServiceModel>> categorizedServices = {};
              for (var service in services) {
                final categoryObj = categories.firstWhere(
                  (c) => c.id == service.category,
                  orElse: () =>
                      CategoryModel(name: 'Uncategorized', name_ar: 'غير مصنف'),
                );
                final categoryName =
                    categoryObj.nameLocalized(languageCode: languageCode) ??
                    'Uncategorized';
                categorizedServices
                    .putIfAbsent(categoryName, () => [])
                    .add(service);
              }

              final sortedCategoryNames = categorizedServices.keys.toList()
                ..sort();

              final List<dynamic> flattenedItems = [];
              for (var catName in sortedCategoryNames) {
                flattenedItems.add(catName); // Header
                flattenedItems.addAll(
                  categorizedServices[catName]!,
                ); // Services
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 16, bottom: 100),
                itemCount: flattenedItems.length,
                itemBuilder: (context, index) {
                  final item = flattenedItems[index];

                  if (item is String) {
                    // Category Header
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index != 0) const SizedBox(height: 16),
                          Text(
                            item.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Divider(),
                        ],
                      ),
                    );
                  }

                  // Service Tile
                  return ServiceTileDevWidget(service: item as ServiceModel);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddServicesDevPage()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
