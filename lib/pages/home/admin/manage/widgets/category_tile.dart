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
            onPressed: () => _showDeleteConfirmDialog(context),
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    // Resolved from the tile, but captured up front: this tile is unmounted as
    // soon as the categories stream drops the deleted row, so the dialog must
    // not depend on the tile's context to finish.
    final bloc = context.read<ManageAppBloc>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => _DeleteCategoryDialog(
        category: category,
        bloc: bloc,
        messenger: messenger,
      ),
    );
  }
}

class _DeleteCategoryDialog extends StatefulWidget {
  const _DeleteCategoryDialog({
    required this.category,
    required this.bloc,
    required this.messenger,
  });

  final CategoryModel category;
  final ManageAppBloc bloc;
  final ScaffoldMessengerState messenger;

  @override
  State<_DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends State<_DeleteCategoryDialog> {
  /// Only react to delete results for the request this dialog started, so a
  /// leftover state from another action can't drive it.
  bool _requested = false;

  void _onStateChanged(BuildContext dialogContext, ManageAppState state) {
    if (!_requested || !mounted) return;

    final l10n = AppLocalizations.of(dialogContext);
    Navigator.of(dialogContext).pop();

    if (state is CategoryDeleted) {
      widget.messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.deletedSuccessfully ?? 'Category deleted successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (state is CategoryDeleteError) {
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
          current is CategoryDeleted || current is CategoryDeleteError,
      listener: (blocContext, state) => _onStateChanged(context, state),
      buildWhen: (previous, current) =>
          current is DeletingCategory ||
          current is CategoryDeleted ||
          current is CategoryDeleteError,
      builder: (blocContext, state) {
        final isDeleting = _requested && state is DeletingCategory;
        final l10n = AppLocalizations.of(context)!;

        return AlertDialog(
          backgroundColor: AppColors.bgWhite,
          actionsAlignment: MainAxisAlignment.start,
          title: Text(l10n.deleteCategory),
          content: Text(l10n.deleteCategoryConfirmation),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.of(context).pop(),
              child: Text(
                l10n.cancel,
                style: const TextStyle(color: Colors.black),
              ),
            ),
            eButton(
              text: "",
              onPressed: isDeleting
                  ? null
                  : () {
                      setState(() => _requested = true);
                      widget.bloc.add(
                        DeleteCategoryEvent(widget.category.id ?? ''),
                      );
                    },
              widget: isDeleting
                  ? SizedBox(
                      width: 30,
                      height: 20,
                      child: Loader(size: 12, color: Colors.white),
                    )
                  : Text(
                      l10n.delete,
                      style: const TextStyle(color: Colors.white),
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
