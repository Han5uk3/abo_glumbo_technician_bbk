import 'dart:io';
import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RemovableImageWidget extends StatelessWidget {
  const RemovableImageWidget({
    super.key,
    this.selectedImage,
    this.networkImageUrl,
    this.onRemove,
    this.height = 150,
    this.width = 150,
    this.borderRadius = 8,
    this.showRemoveButton = true,
    this.placeholder,
    this.errorWidget,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.centerLeft,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.removeButtonColor = Colors.red,
    this.removeButtonSize = 16,
  });

  final XFile? selectedImage;
  final String? networkImageUrl;
  final VoidCallback? onRemove;
  final double height;
  final double width;
  final double borderRadius;
  final bool showRemoveButton;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit fit;
  final Alignment alignment;
  final EdgeInsetsGeometry margin;
  final Color removeButtonColor;
  final double removeButtonSize;

  @override
  Widget build(BuildContext context) {
    // Determine if we should show an image
    final hasImage =
        selectedImage != null || (networkImageUrl?.isNotEmpty == true);

    if (!hasImage) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: margin,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: SizedBox(
                height: height,
                width: width,
                child: _buildImageWidget(),
              ),
            ),
            if (showRemoveButton && onRemove != null) _buildRemoveButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    // Priority: selected file image > network image
    if (selectedImage != null) {
      return Image.file(
        File(selectedImage!.path),
        height: height,
        width: width,
        fit: fit,
      );
    }

    if (networkImageUrl?.isNotEmpty == true) {
      return CachedNetworkImage(
        imageUrl: networkImageUrl!,
        height: height,
        width: width,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ?? _buildDefaultPlaceholder(),
        errorWidget: (context, url, error) =>
            errorWidget ?? _buildDefaultErrorWidget(),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      height: height,
      width: width,
      color: Colors.grey[300],
      child: Center(child: Loader(size: 16, color: AppColors.primary)),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      height: height,
      width: width,
      color: Colors.grey[300],
      child: const Icon(Icons.error),
    );
  }

  Widget _buildRemoveButton(BuildContext context) {
    return Positioned.directional(
      textDirection: Directionality.of(context),
      top: -10,
      end: -10,
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: removeButtonColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.close, color: Colors.white, size: removeButtonSize),
        ),
      ),
    );
  }
}

// Enhanced version with more features
class RemovableImageWidgetEnhanced extends StatelessWidget {
  const RemovableImageWidgetEnhanced({
    super.key,
    this.selectedImage,
    this.networkImageUrl,
    this.onRemove,
    this.onTap,
    this.height = 150,
    this.width = 150,
    this.borderRadius = 8,
    this.showRemoveButton = true,
    this.placeholder,
    this.errorWidget,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.centerLeft,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.removeButtonColor = Colors.red,
    this.removeButtonSize = 16,
    this.showBorder = false,
    this.borderColor = Colors.grey,
    this.borderWidth = 1,
    this.showShadow = false,
    this.removeButtonIcon = Icons.close,
    this.tooltip,
  });

  final File? selectedImage;
  final String? networkImageUrl;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  final double height;
  final double width;
  final double borderRadius;
  final bool showRemoveButton;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit fit;
  final Alignment alignment;
  final EdgeInsetsGeometry margin;
  final Color removeButtonColor;
  final double removeButtonSize;
  final bool showBorder;
  final Color borderColor;
  final double borderWidth;
  final bool showShadow;
  final IconData removeButtonIcon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        selectedImage != null || (networkImageUrl?.isNotEmpty == true);

    if (!hasImage) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: margin,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: onTap,
              child: Container(
                height: height,
                width: width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: showBorder
                      ? Border.all(color: borderColor, width: borderWidth)
                      : null,
                  boxShadow: showShadow
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: _buildImageWidget(),
                ),
              ),
            ),
            if (showRemoveButton && onRemove != null) _buildRemoveButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (selectedImage != null) {
      return Image.file(selectedImage!, height: height, width: width, fit: fit);
    }

    if (networkImageUrl?.isNotEmpty == true) {
      return CachedNetworkImage(
        imageUrl: networkImageUrl!,
        height: height,
        width: width,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ?? _buildDefaultPlaceholder(),
        errorWidget: (context, url, error) =>
            errorWidget ?? _buildDefaultErrorWidget(),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      height: height,
      width: width,
      color: Colors.grey[300],
      child: Center(child: Loader(size: 16, color: AppColors.primary)),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      height: height,
      width: width,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, color: Colors.grey[600], size: 32),
          const SizedBox(height: 4),
          Text(
            'Failed to load',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoveButton(BuildContext context) {
    Widget button = InkWell(
      onTap: onRemove,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: removeButtonColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          removeButtonIcon,
          color: Colors.white,
          size: removeButtonSize,
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return Positioned.directional(
      textDirection: Directionality.of(context),
      top: -10,
      end: -10,
      child: button,
    );
  }
}
