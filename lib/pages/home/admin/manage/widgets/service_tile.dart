import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/service.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/services/edit_services_screen.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServiceTileDevWidget extends StatelessWidget {
  const ServiceTileDevWidget({super.key, required this.service});
  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 60,
                    width: 60,
                    child: _buildImageWidget(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  service.nameLocalized(
                                        languageCode:
                                            AppLocalizations.of(
                                              context,
                                            )?.localeName ??
                                            'en',
                                      ) ??
                                      service.name ??
                                      "",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  service.descriptionLocalized(
                                        languageCode:
                                            AppLocalizations.of(
                                              context,
                                            )?.localeName ??
                                            'en',
                                      ) ??
                                      service.description ??
                                      "",
                                  style: const TextStyle(
                                    color: Colors.black45,
                                    fontSize: 11,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddServicesDevPage(service: service),
                              ),
                            ),
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () => _showDeleteConfirmDialog(context),
                            icon: const Icon(
                              CupertinoIcons.delete,
                              size: 18,
                              color: Colors.red,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6),
          Divider(color: Colors.grey.shade300),
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "${AppLocalizations.of(context)!.serviceCost}:",
                  style: TextStyle(
                    color: AppColors.green1,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  "${service.price} ${AppLocalizations.of(context)!.sar}",
                  style: TextStyle(
                    color: AppColors.green1,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "${AppLocalizations.of(context)!.active}:",
                  style: TextStyle(
                    color: AppColors.green1,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: BlocBuilder<ManageAppBloc, ManageAppState>(
                  builder: (context, state) {
                    return Transform.scale(
                      scale: 0.8,
                      alignment: Directionality.of(context) == TextDirection.rtl
                          ? AlignmentDirectional.centerStart
                          : AlignmentDirectional.centerEnd,
                      child: Switch.adaptive(
                        activeColor: AppColors.primary,
                        value: service.isActive,
                        onChanged: (value) {
                          context.read<ManageAppBloc>().add(
                            ToggleServiceStatusEvent(service, value),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget() {
    final imageUrl = service.image?.trim() ?? '';

    if (imageUrl.isEmpty || !_isValidUrl(imageUrl)) {
      return Container(
        color: Colors.grey[200],
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
        color: Colors.grey[200],
        child: const Icon(Icons.error, size: 40, color: Colors.red),
      ),
    );
  }

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

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _buildDeleteConfirmDialog(context),
    );
  }

  Widget _buildDeleteConfirmDialog(BuildContext context) {
    return BlocConsumer<ManageAppBloc, ManageAppState>(
      listener: (blocContext, state) {
        if (state is ServiceDeleted) {
          // Close the dialog
          Navigator.of(context).pop();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.deletedSuccessfully ??
                    'Service deleted successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ServiceDeleteError) {
          // Close the dialog
          Navigator.of(context).pop();

          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)?.deleteError ?? 'Delete error'}: ${state.error}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (blocContext, state) {
        final isDeleting = state is DeletingService;

        return AlertDialog(
          backgroundColor: AppColors.bgWhite,
          actionsAlignment: MainAxisAlignment.start,
          title: Text(
            AppLocalizations.of(context)?.deleteService ?? 'Delete Service',
          ),
          content: Text(
            AppLocalizations.of(context)?.deleteServiceConfirmation ??
                'Are you sure you want to delete this service? This action cannot be undone.',
          ),
          actions: [
            eButton(
              textColor: Colors.black,
              context: context,
              backgroundColor: AppColors.bgWhite,
              text: AppLocalizations.of(context)!.cancel,
              onPressed: isDeleting ? null : () => Navigator.of(context).pop(),
            ),
            eButton(
              textColor: Colors.white,
              context: context,
              backgroundColor: Colors.red,

              onPressed: isDeleting
                  ? null
                  : () {
                      blocContext.read<ManageAppBloc>().add(
                        DeleteServiceEvent(service.id ?? ''),
                      );
                    },
              widget: isDeleting
                  ? SizedBox(
                      width: 30,
                      height: 20,
                      child: Loader(size: 12, color: AppColors.bgWhite),
                    )
                  : Text(
                      AppLocalizations.of(context)!.delete,
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
          ],
        );
      },
    );
  }
}
