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
import 'package:google_fonts/google_fonts.dart';

class ServiceTileDevWidget extends StatelessWidget {
  const ServiceTileDevWidget({super.key, required this.service});
  final ServiceModel service;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.all(13),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 80,
                    width: 80,
                    child: _buildImageWidget(),
                  ),
                ),
                const SizedBox(width: 17),

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
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  Directionality.of(context) ==
                                          TextDirection.rtl
                                      ? service.name_ar ?? ""
                                      : service.name ?? "",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  Directionality.of(context) ==
                                          TextDirection.rtl
                                      ? service.description_ar ?? ""
                                      : service.description ?? "",
                                  style: GoogleFonts.dmSans(
                                    color: Colors.black45,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AddServicesDevPage(service: service),
                                ),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              onPressed: () =>
                                  _showDeleteConfirmDialog(context),

                              icon: const Icon(
                                CupertinoIcons.delete,
                                size: 18,
                                color: Colors.red,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                            ),
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
                  style: GoogleFonts.dmSans(
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
                  style: GoogleFonts.dmSans(
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
                  style: GoogleFonts.dmSans(
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
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
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
          backgroundColor: Colors.white,
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
              backgroundColor: Colors.white,
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
