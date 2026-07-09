import 'package:aboglumbo_bbk_panel/common_widget/elevated_button.dart';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/categories.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/bloc/manage_app_bloc.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/categories/add_new_categories.dart';
import 'package:aboglumbo_bbk_panel/pages/home/admin/manage/widgets/shimmer_loading.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryTileDevWidget extends StatelessWidget {
  const CategoryTileDevWidget({super.key, required this.category});
  final CategoryModel category;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: category.svg ?? '',
              height: 60,
              width: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => const ImageShimmer(),
              errorWidget: (context, url, error) =>
                  Icon(Icons.error, color: Colors.red.withOpacity(0.7)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  category.nameLocalized(
                        languageCode:
                            AppLocalizations.of(context)?.localeName ?? 'en',
                      ) ??
                      category.name ??
                      "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddNewCategories(category: category),
              ),
            ),
            icon: Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) =>
                    showDeleteConfirmDialog(dialogContext),
              );
            },
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
          ),
        ],
      ),
    );
  }

  // Updated showDeleteConfirmDialog method with delete functionality
  Widget showDeleteConfirmDialog(BuildContext context) {
    return BlocConsumer<ManageAppBloc, ManageAppState>(
      listener: (blocContext, state) {
        if (state is CategoryDeleted) {
          // Generic deletion success
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.deletedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is CategoryDeleteError) {
          // Generic deletion error
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)?.deleteError}: ${state is BannerDeleteError ? (state).error : (state as FaqDeleteError).error}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (blocContext, state) {
        final isDeleting = state is DeletingCategory;

        return AlertDialog(
          backgroundColor: AppColors.bgWhite,
          actionsAlignment: MainAxisAlignment.start,
          title: Text(AppLocalizations.of(context)!.deleteCategory),
          content: Text(
            AppLocalizations.of(context)!.deleteCategoryConfirmation,
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: TextStyle(color: Colors.black),
              ),
            ),
            eButton(
              text: "",
              onPressed: isDeleting
                  ? null
                  : () {
                      // Trigger delete event
                      context.read<ManageAppBloc>().add(
                        DeleteCategoryEvent(category.id ?? ''),
                      );
                    },
              widget: isDeleting
                  ? SizedBox(
                      width: 30,
                      height: 20,
                      child: Loader(size: 12, color: Colors.white),
                    )
                  : Text(
                      AppLocalizations.of(context)!.delete,
                      style: TextStyle(color: Colors.white),
                    ),
              context: context,
              textColor: Colors.white,
              backgroundColor: Colors.red,
            ),
          ],
        );
      },
    );
  }
}
