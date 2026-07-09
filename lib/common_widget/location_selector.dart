import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class LocationSelectorWidget<T> extends StatelessWidget {
  const LocationSelectorWidget({
    super.key,
    required this.selectedLocations,
    required this.onLocationTap,
    required this.onLocationRemove,
    required this.getLocationName,
    this.labelText = 'Select Locations',
    this.hintText = 'Tap to select locations',
    this.locationSelectedText = 'location selected',
    this.locationsSelectedText = 'locations selected',
    this.suffixIcon = const Icon(Icons.location_on),
    this.chipBackgroundColor,
    this.chipTextColor = Colors.white,
    this.chipDeleteIconColor = Colors.white,
    this.chipDeleteIconSize = 16,
    this.chipSpacing = 8,
    this.chipRunSpacing = 4,
    this.chipFontSize = 12,
    this.padding = const EdgeInsets.only(bottom: 16),
    this.decoration,
    this.enabled = true,
    this.showCounter = true,
    this.maxLines = 1,
  });

  final List<T> selectedLocations;
  final VoidCallback onLocationTap;
  final void Function(T location) onLocationRemove;
  final String Function(T location) getLocationName;
  final String labelText;
  final String hintText;
  final String locationSelectedText;
  final String locationsSelectedText;
  final Widget? suffixIcon;
  final Color? chipBackgroundColor;
  final Color chipTextColor;
  final Color chipDeleteIconColor;
  final double chipDeleteIconSize;
  final double chipSpacing;
  final double chipRunSpacing;
  final double chipFontSize;
  final EdgeInsetsGeometry padding;
  final InputDecoration? decoration;
  final bool enabled;
  final bool showCounter;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultChipColor = chipBackgroundColor ?? theme.primaryColor;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: enabled ? onLocationTap : null,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration:
                  decoration ??
                  InputDecoration(
                    labelText: labelText,
                    border: const OutlineInputBorder(),
                    suffixIcon: suffixIcon,
                    enabled: enabled,
                  ),
              child: Text(
                _getDisplayText(),
                style: TextStyle(
                  color: selectedLocations.isEmpty
                      ? Colors.grey
                      : (enabled ? null : Colors.grey),
                ),
                maxLines: maxLines,
                overflow: maxLines != null ? TextOverflow.ellipsis : null,
              ),
            ),
          ),
          if (selectedLocations.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildLocationChips(defaultChipColor),
          ],
        ],
      ),
    );
  }

  String _getDisplayText() {
    if (selectedLocations.isEmpty) return hintText;

    if (!showCounter) {
      return selectedLocations.map(getLocationName).join(', ');
    }

    final count = selectedLocations.length;
    final selectedText = count == 1
        ? locationSelectedText
        : locationsSelectedText;
    return '$count $selectedText';
  }

  Widget _buildLocationChips(Color chipColor) {
    return Wrap(
      spacing: chipSpacing,
      runSpacing: chipRunSpacing,
      children: selectedLocations.map((location) {
        final locationName = getLocationName(location);
        return Chip(
          label: Text(
            locationName,
            style: TextStyle(fontSize: chipFontSize, color: chipTextColor),
          ),
          backgroundColor: chipColor,
          deleteIcon: Icon(
            Icons.close,
            size: chipDeleteIconSize,
            color: chipDeleteIconColor,
          ),
          onDeleted: enabled ? () => onLocationRemove(location) : null,
        );
      }).toList(),
    );
  }
}

// Enhanced version with more features
class LocationSelectorWidgetEnhanced<T> extends StatelessWidget {
  const LocationSelectorWidgetEnhanced({
    super.key,
    required this.selectedLocations,
    required this.onLocationTap,
    required this.onLocationRemove,
    required this.getLocationName,
    this.getLocationId,
    this.labelText = 'Select Locations',
    this.hintText = 'Tap to select locations',
    this.locationSelectedText = 'location selected',
    this.locationsSelectedText = 'locations selected',
    this.suffixIcon = const Icon(Icons.location_on),
    this.chipBackgroundColor,
    this.chipTextColor = Colors.white,
    this.chipDeleteIconColor = Colors.white,
    this.chipDeleteIconSize = 16,
    this.chipSpacing = 8,
    this.chipRunSpacing = 4,
    this.chipFontSize = 12,
    this.padding = const EdgeInsets.only(bottom: 16),
    this.decoration,
    this.enabled = true,
    this.showCounter = true,
    this.maxLines = 1,
    this.maxChips,
    this.chipStyle,
    this.onChipTap,
    this.showSelectAll = false,
    this.onSelectAll,
    this.validator,
    this.errorText,
  });

  final List<T> selectedLocations;
  final VoidCallback onLocationTap;
  final void Function(T location) onLocationRemove;
  final String Function(T location) getLocationName;
  final String Function(T location)? getLocationId;
  final String labelText;
  final String hintText;
  final String locationSelectedText;
  final String locationsSelectedText;
  final Widget? suffixIcon;
  final Color? chipBackgroundColor;
  final Color chipTextColor;
  final Color chipDeleteIconColor;
  final double chipDeleteIconSize;
  final double chipSpacing;
  final double chipRunSpacing;
  final double chipFontSize;
  final EdgeInsetsGeometry padding;
  final InputDecoration? decoration;
  final bool enabled;
  final bool showCounter;
  final int? maxLines;
  final int? maxChips;
  final ChipThemeData? chipStyle;
  final void Function(T location)? onChipTap;
  final bool showSelectAll;
  final VoidCallback? onSelectAll;
  final String? Function(List<T>)? validator;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultChipColor = chipBackgroundColor ?? theme.primaryColor;
    final validationError = validator?.call(selectedLocations) ?? errorText;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main selector
          InkWell(
            onTap: enabled ? onLocationTap : null,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration:
                  (decoration ??
                          InputDecoration(
                            labelText: labelText,
                            border: const OutlineInputBorder(),
                            suffixIcon: suffixIcon,
                            enabled: enabled,
                          ))
                      .copyWith(
                        errorText: validationError,
                        errorBorder: validationError != null
                            ? const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.red),
                              )
                            : null,
                      ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _getDisplayText(),
                      style: TextStyle(
                        color: selectedLocations.isEmpty
                            ? Colors.grey
                            : (enabled ? null : Colors.grey),
                      ),
                      maxLines: maxLines,
                      overflow: maxLines != null ? TextOverflow.ellipsis : null,
                    ),
                  ),
                  if (showSelectAll && onSelectAll != null)
                    TextButton(
                      onPressed: enabled ? onSelectAll : null,
                      child: Text(
                        AppLocalizations.of(context)?.selectAll ?? 'Select All',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Selected location chips
          if (selectedLocations.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildLocationChips(context, defaultChipColor),
          ],

          // Counter or limit info
          if (maxChips != null && selectedLocations.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${selectedLocations.length}/$maxChips ${AppLocalizations.of(context)!.locationsSelected}',
              style: TextStyle(
                fontSize: 11,
                color: selectedLocations.length >= maxChips!
                    ? Colors.orange
                    : Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getDisplayText() {
    if (selectedLocations.isEmpty) return hintText;

    if (!showCounter) {
      final names = selectedLocations.map(getLocationName);
      final displayText = names.join(', ');
      return displayText.length > 50
          ? '${displayText.substring(0, 47)}...'
          : displayText;
    }

    final count = selectedLocations.length;
    final selectedText = count == 1
        ? locationSelectedText
        : locationsSelectedText;
    return '$count $selectedText';
  }

  Widget _buildLocationChips(BuildContext context, Color chipColor) {
    final displayChips =
        maxChips != null && selectedLocations.length > maxChips!
        ? selectedLocations.take(maxChips!).toList()
        : selectedLocations;

    final hiddenCount = selectedLocations.length - displayChips.length;

    return Wrap(
      spacing: chipSpacing,
      runSpacing: chipRunSpacing,
      children: [
        ...displayChips.map((location) {
          final locationName = getLocationName(location);
          return GestureDetector(
            onTap: onChipTap != null ? () => onChipTap!(location) : null,
            child: Chip(
              label: Text(
                locationName,
                style: TextStyle(fontSize: chipFontSize, color: chipTextColor),
              ),
              backgroundColor: chipColor,
              deleteIcon: Icon(
                Icons.close,
                size: chipDeleteIconSize,
                color: chipDeleteIconColor,
              ),
              onDeleted: enabled ? () => onLocationRemove(location) : null,
            ),
          );
        }),
        if (hiddenCount > 0)
          Chip(
            label: Text(
              '+$hiddenCount ${AppLocalizations.of(context)!.more}',
              style: TextStyle(fontSize: chipFontSize, color: chipTextColor),
            ),
            backgroundColor: Colors.grey[600],
          ),
      ],
    );
  }
}
