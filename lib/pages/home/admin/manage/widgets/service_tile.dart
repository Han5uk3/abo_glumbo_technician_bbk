import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/service.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/services/edit_services_screen.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/shimmer_loading.dart';
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
                  "${AppLocalizations.of(context)!.workingHoursPricing}:",
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
                  "${service.onWorkHourPrice ?? 0} ${AppLocalizations.of(context)!.sar}",
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
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  "${AppLocalizations.of(context)!.outsideWorkingHoursPricing}:",
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
                  "${service.offWorkHourPrice ?? 0} ${AppLocalizations.of(context)!.sar}",
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
      placeholder: (context, url) => const ImageShimmer(),
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
    // Resolved from the tile, but captured up front: this tile is unmounted as
    // soon as the services stream drops the deleted row, so the dialog must not
    // depend on the tile's context to finish.
    final bloc = context.read<ManageAppBloc>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => _DeleteServiceDialog(
        service: service,
        bloc: bloc,
        messenger: messenger,
      ),
    );
  }
}

class _DeleteServiceDialog extends StatefulWidget {
  const _DeleteServiceDialog({
    required this.service,
    required this.bloc,
    required this.messenger,
  });

  final ServiceModel service;
  final ManageAppBloc bloc;
  final ScaffoldMessengerState messenger;

  @override
  State<_DeleteServiceDialog> createState() => _DeleteServiceDialogState();
}

class _DeleteServiceDialogState extends State<_DeleteServiceDialog> {
  /// Only react to delete results for the request this dialog started, so a
  /// leftover state from another action can't drive it.
  bool _requested = false;

  void _onStateChanged(BuildContext dialogContext, ManageAppState state) {
    if (!_requested || !mounted) return;

    final l10n = AppLocalizations.of(dialogContext);
    Navigator.of(dialogContext).pop();

    if (state is ServiceDeleted) {
      widget.messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.deletedSuccessfully ?? 'Service deleted successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (state is ServiceDeleteError) {
      widget.messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${l10n?.deleteError ?? 'Delete error'}: ${state.error}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ManageAppBloc, ManageAppState>(
      bloc: widget.bloc,
      listenWhen: (previous, current) =>
          current is ServiceDeleted || current is ServiceDeleteError,
      listener: (blocContext, state) => _onStateChanged(context, state),
      buildWhen: (previous, current) =>
          current is DeletingService ||
          current is ServiceDeleted ||
          current is ServiceDeleteError,
      builder: (blocContext, state) {
        final isDeleting = _requested && state is DeletingService;
        final l10n = AppLocalizations.of(context);

        return AlertDialog(
          backgroundColor: AppColors.bgWhite,
          actionsAlignment: MainAxisAlignment.start,
          title: Text(l10n?.deleteService ?? 'Delete Service'),
          content: Text(
            l10n?.deleteServiceConfirmation ??
                'Are you sure you want to delete this service? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.of(context).pop(),
              child: Text(
                l10n!.cancel,
                style: const TextStyle(color: Colors.black),
              ),
            ),
            eButton(
              textColor: Colors.white,
              context: context,
              backgroundColor: Colors.red,

              onPressed: isDeleting
                  ? null
                  : () {
                      setState(() => _requested = true);
                      widget.bloc.add(
                        DeleteServiceEvent(widget.service.id ?? ''),
                      );
                    },
              widget: isDeleting
                  ? SizedBox(
                      width: 30,
                      height: 20,
                      child: Loader(size: 12, color: AppColors.bgWhite),
                    )
                  : Text(
                      l10n.delete,
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
          ],
        );
      },
    );
  }
}
