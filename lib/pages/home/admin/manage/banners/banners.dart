import "package:aboglumbo_bbk_panel/styles/color.dart";
import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/banner.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/banners/add_banner.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/banner_tile.dart';
import 'package:aboglumbo_bbk_panel/services/app_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageBanners extends StatelessWidget {
  const ManageBanners({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ManageAppBloc, ManageAppState>(
      listener: (context, state) {
        if (state is BannerDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.bannerDeleted ??
                    'Banner deleted successfully',
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon:
                const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          ),
          title: Text(
            AppLocalizations.of(context)?.manageBanners ?? 'Manage Banners',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          shape: Border.all(style: BorderStyle.none),
        ),
        body: StreamBuilder(
          stream: AppServices.getAllBannersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 24, child: Loader()),
                    const SizedBox(height: 10),
                    Text(AppLocalizations.of(context)!.loadingBanners),
                  ],
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '${AppLocalizations.of(context)?.error}: ${snapshot.error}',
                ),
              );
            }

            if (snapshot.data == null || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront, size: 100, color: Colors.grey[400]),
                    Text(
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      AppLocalizations.of(context)?.noBannersAAddedYet ??
                          'No Banners',
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '${AppLocalizations.of(context)?.error}: ${snapshot.error}',
                ),
              );
            }

            final banners = snapshot.data ?? [];
            return ListView.builder(
              itemCount: banners.length,
              itemBuilder: (context, index) {
                final banner = banners[index];
                return BannerTile(
                  banner: banner,
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddBanner(banner: banner),
                    ),
                  ),
                  onDelete: () =>
                      _showDeleteConfirmationDialog(context, banner),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBanner()),
          ),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, BannerModel banner) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.bgWhite,
          actionsAlignment: MainAxisAlignment.start,
          title: Text(
            AppLocalizations.of(context)?.deleteBanner ?? 'Delete Banner',
          ),
          content: Text(
            AppLocalizations.of(context)?.deleteBannerConfirmation ??
                'Are you sure you want to delete this banner? This action cannot be undone.',
          ),
          actions: [
            eButton(
              context: context,
              onPressed: () => Navigator.of(context).pop(),
              text: AppLocalizations.of(context)?.cancel ?? 'Cancel',
              textColor: Colors.black,
              backgroundColor: AppColors.bgWhite,
            ),
            eButton(
              context: context,
              onPressed: () {
                Navigator.of(context).pop();
                context.read<ManageAppBloc>().add(
                  DeleteBannerEvent(banner.id ?? ''),
                );
              },
              text: AppLocalizations.of(context)?.delete ?? 'Delete',
              textColor: Colors.white,
              backgroundColor: Colors.red,
            ),
          ],
        );
      },
    );
  }
}
