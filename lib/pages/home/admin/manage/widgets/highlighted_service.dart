import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/helpers/firestore.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/highlighted_services.dart';
import 'package:aboglumbo_bbk_panel/models/service.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HighlightedServiceWidget extends StatelessWidget {
  const HighlightedServiceWidget({
    super.key,
    required this.data,
    required this.editCallback,
  });
  final HighlightedServicesModel data;
  final VoidCallback editCallback;

  @override
  Widget build(BuildContext context) {
    final currentLanguage = AppLocalizations.of(context)?.localeName ?? 'en';
    final isRtlLanguage = currentLanguage == 'ar';

    return Container(
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    data.titleLocalized(languageCode: currentLanguage) ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    onPressed: editCallback,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: data.services?.length ?? 0,
                itemBuilder: (context, index) {
                  return FutureBuilder(
                    future: AppFirestore.servicesCollectionRef
                        .doc(data.services![index])
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingContainer(isRtlLanguage);
                      }
                      if (snapshot.hasError) {
                        return _buildErrorContainer(context, isRtlLanguage);
                      }

                      final service = ServiceModel.fromDocumentSnapshot(
                        snapshot.data as DocumentSnapshot,
                      );

                      return Container(
                        height: 110,
                        width: 140,
                        margin: const EdgeInsetsDirectional.only(end: 10),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.05),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            SizedBox.expand(child: _buildServiceImage(service)),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.8),
                                  ],
                                ),
                              ),
                              child: Text(
                                service.nameLocalized(
                                      languageCode: currentLanguage,
                                    ) ??
                                    service.name ??
                                    "",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build loading container
  Widget _buildLoadingContainer(bool isRtlLanguage) {
    return Container(
      height: 127,
      width: 127,
      alignment: Alignment.center,
      margin: const EdgeInsetsDirectional.only(end: 13),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Loader(size: 14, color: AppColors.primary),
    );
  }

  // Helper method to build error container
  Widget _buildErrorContainer(BuildContext context, bool isRtlLanguage) {
    return Container(
      height: 127,
      width: 127,
      alignment: Alignment.center,
      margin: const EdgeInsetsDirectional.only(end: 13),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 24),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)?.failedToLoadServices ?? 'Error',
            style: TextStyle(fontSize: 10, color: Colors.red),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper method to build service image with URL validation
  Widget _buildServiceImage(ServiceModel service) {
    final imageUrl = service.image?.trim() ?? '';

    // Check if URL is empty or invalid
    if (imageUrl.isEmpty || !_isValidUrl(imageUrl)) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(
          Icons.image_not_supported,
          size: 40,
          color: Colors.grey,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[100],
        child: Center(child: Loader(size: 20)),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
      ),
    );
  }

  // Helper method to validate URL
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
