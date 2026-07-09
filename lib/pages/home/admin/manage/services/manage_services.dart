import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/services/edit_services_screen.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/shimmer_loading.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/service_tile.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/models/service.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';

class ManageServices extends StatefulWidget {
  const ManageServices({super.key});

  @override
  State<ManageServices> createState() => _ManageServicesState();
}

class _ManageServicesState extends State<ManageServices> {
  late Stream<List<CategoryModel>> _categoriesStream;
  late Stream<List<ServiceModel>> _servicesStream;

  @override
  void initState() {
    super.initState();
    _categoriesStream = AppFirestore.categoriesCollectionRef.snapshots().map(
      (s) => s.docs.map((d) => CategoryModel.fromQuerySnapshot(d)).toList(),
    );
    _servicesStream = AppServices.getAllServicesStream();
  }

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
          AppLocalizations.of(context)!.manageServices,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        shape: Border.all(style: BorderStyle.none),
      ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: _categoriesStream,
        builder: (context, catSnapshot) {
          final categories = catSnapshot.data ?? [];

          return StreamBuilder<List<ServiceModel>>(
            stream: _servicesStream,
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
