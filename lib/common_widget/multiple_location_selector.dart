import 'package:aboglumbo_bbk_panel/common_widget/loader.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:aboglumbo_bbk_panel/models/service_location.dart';
import 'package:aboglumbo_bbk_panel/styles/color.dart';
import 'package:flutter/material.dart';

class LocationSelectorWidget extends StatefulWidget {
  final List<ServiceLocationModel> locations;
  final ServiceLocationModel? selectedLocation;
  final List<ServiceLocationModel>? selectedLocations;
  final Function(ServiceLocationModel)? onLocationSelected;
  final Function(List<ServiceLocationModel>)? onLocationsSelected;
  final VoidCallback? onUseCurrentLocation;
  final bool isLoading;
  final String? searchHint;
  final String? title;
  final String? noLocationsMessage;
  final String? currentLocationText;
  final bool allowMultipleSelection;

  const LocationSelectorWidget({
    super.key,
    required this.locations,
    this.selectedLocation,
    this.selectedLocations,
    this.onLocationSelected,
    this.onLocationsSelected,
    this.onUseCurrentLocation,
    this.isLoading = false,
    this.searchHint,
    this.title,
    this.noLocationsMessage,
    this.currentLocationText,
    this.allowMultipleSelection = false,
  });

  @override
  State<LocationSelectorWidget> createState() => _LocationSelectorWidgetState();
}

class _LocationSelectorWidgetState extends State<LocationSelectorWidget> {
  final TextEditingController searchController = TextEditingController();
  List<ServiceLocationModel> filteredLocations = [];
  List<ServiceLocationModel> selectedLocations = [];
  String languageCode = 'en';
  bool isAllSelected = false;

  @override
  void initState() {
    super.initState();
    filteredLocations = widget.locations;

    if (widget.allowMultipleSelection && widget.selectedLocations != null) {
      selectedLocations = List.from(widget.selectedLocations!);
    }
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        selectedLocations = List.from(filteredLocations);
        isAllSelected = true;
      } else {
        selectedLocations.clear();
        isAllSelected = false;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    languageCode = AppLocalizations.of(context)?.localeName ?? 'en';
    filteredLocations = _removeDuplicates(widget.locations);
  }

  @override
  void didUpdateWidget(LocationSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locations != widget.locations) {
      filteredLocations = _removeDuplicates(widget.locations);
      _filterLocations(searchController.text);
    }
  }

  List<ServiceLocationModel> _removeDuplicates(List<ServiceLocationModel> locations) {
    final seen = <String>{};
    return locations.where((location) {
      final name = location.name;
      if (name.isEmpty) return true;

      if (seen.contains(name)) {
        return false;
      }
      seen.add(name);
      return true;
    }).toList();
  }

  void _filterLocations(String query) {
    setState(() {
      final uniqueLocations = _removeDuplicates(widget.locations);
      if (query.isEmpty) {
        filteredLocations = uniqueLocations;
      } else {
        filteredLocations = uniqueLocations.where((location) {
          final nameMatch =
              location.name.toLowerCase().contains(query.toLowerCase());
          final nameArMatch =
              location.name_ar.toLowerCase().contains(query.toLowerCase());
          final nameUrMatch =
              location.name_ur.toLowerCase().contains(query.toLowerCase());
          return nameMatch || nameArMatch || nameUrMatch;
        }).toList();
      }
      isAllSelected =
          filteredLocations.isNotEmpty &&
          selectedLocations.length == filteredLocations.length &&
          filteredLocations.every(
            (loc) => selectedLocations.any((sel) => sel.id == loc.id),
          );
    });
  }

  String _getLocationName(ServiceLocationModel location) {
    if (languageCode == 'ur') {
      return location.name_ur.isNotEmpty ? location.name_ur : (location.name_ar.isNotEmpty ? location.name_ar : location.name);
    } else if (languageCode == 'ar') {
      return location.name_ar.isNotEmpty ? location.name_ar : location.name;
    }
    return location.name;
  }

  bool _isLocationSelected(ServiceLocationModel location) {
    if (widget.allowMultipleSelection) {
      return selectedLocations.any((selected) => selected.id == location.id);
    } else {
      return widget.selectedLocation?.id == location.id;
    }
  }

  void _handleLocationTap(ServiceLocationModel location) {
    if (widget.allowMultipleSelection) {
      setState(() {
        final index = selectedLocations.indexWhere(
          (selected) => selected.id == location.id,
        );
        if (index >= 0) {
          selectedLocations.removeAt(index);
        } else {
          selectedLocations.add(location);
        }
        isAllSelected = selectedLocations.length == filteredLocations.length;
      });
    } else {
      widget.onLocationSelected?.call(location);
    }
  }

  void _handleDonePressed() {
    if (widget.allowMultipleSelection) {
      widget.onLocationsSelected?.call(selectedLocations);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final safePaddings = MediaQuery.of(context).padding;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title ??
                        AppLocalizations.of(context)?.selectLocation ??
                        'Select Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      if (widget.allowMultipleSelection &&
                          selectedLocations.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          margin: const EdgeInsetsDirectional.only(end: 8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${selectedLocations.length} ${AppLocalizations.of(context)?.selected ?? 'Selected'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Add Select All option here
            if (widget.allowMultipleSelection && filteredLocations.isNotEmpty)
              CheckboxListTile(
                value: isAllSelected,
                onChanged: _toggleSelectAll,
                title: Text(
                  AppLocalizations.of(context)?.selectAll ?? 'Select All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
                activeColor: AppColors.secondary,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),

            if (widget.allowMultipleSelection && filteredLocations.isNotEmpty)
              const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText:
                      widget.searchHint ??
                      AppLocalizations.of(context)?.searchLocation ??
                      'Search Location',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.grey2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                onChanged: _filterLocations,
              ),
            ),
            if (widget.onUseCurrentLocation != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.my_location, color: AppColors.secondary),
                ),
                title: Text(
                  widget.currentLocationText ??
                      AppLocalizations.of(context)?.useCurrentLocation ??
                      'Use Current Location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onUseCurrentLocation!();
                },
              ),
            if (widget.onUseCurrentLocation != null) const Divider(),
            Expanded(
              child: widget.isLoading
                  ? Center(child: Loader(size: 16, color: AppColors.primary))
                  : filteredLocations.isEmpty
                  ? Center(
                      child: Text(
                        widget.noLocationsMessage ?? 'No locations found',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredLocations.length,
                      padding: EdgeInsets.only(
                        bottom:
                            safePaddings.bottom +
                            (widget.allowMultipleSelection ? 80 : 16),
                      ),
                      itemBuilder: (context, index) {
                        final location = filteredLocations[index];
                        final isSelected = _isLocationSelected(location);

                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.location_on_rounded,
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.grey2,
                          ),
                          title: Text(
                            _getLocationName(location),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected ? AppColors.secondary : null,
                            ),
                          ),
                          trailing: widget.allowMultipleSelection
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    _handleLocationTap(location);
                                  },
                                  activeColor: AppColors.secondary,
                                )
                              : isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: AppColors.secondary,
                                )
                              : null,
                          onTap: () {
                            _handleLocationTap(location);
                          },
                        );
                      },
                    ),
            ),

            if (widget.allowMultipleSelection)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _handleDonePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(
                      context,
                    )!.doneSelectedCount(selectedLocations.length),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

class LocationSelectorHelper {
  static Future<ServiceLocationModel?> showLocationSelector({
    required BuildContext context,
    required List<ServiceLocationModel> locations,
    ServiceLocationModel? selectedLocation,
    VoidCallback? onUseCurrentLocation,
    bool isLoading = false,
    String? searchHint,
    String? title,
    String? noLocationsMessage,
    String? currentLocationText,
  }) async {
    return await showModalBottomSheet<ServiceLocationModel>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return LocationSelectorWidget(
          locations: locations,
          selectedLocation: selectedLocation,
          onLocationSelected: (location) {
            Navigator.pop(context, location);
          },
          onUseCurrentLocation: onUseCurrentLocation,
          isLoading: isLoading,
          searchHint: searchHint,
          title: title,
          noLocationsMessage: noLocationsMessage,
          currentLocationText: currentLocationText,
          allowMultipleSelection: false,
        );
      },
    );
  }

  static Future<List<ServiceLocationModel>?> showMultipleLocationSelector({
    required BuildContext context,
    required List<ServiceLocationModel> locations,
    List<ServiceLocationModel>? selectedLocations,
    VoidCallback? onUseCurrentLocation,
    bool isLoading = false,
    String? searchHint,
    String? title,
    String? noLocationsMessage,
    String? currentLocationText,
  }) async {
    List<ServiceLocationModel>? result;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return LocationSelectorWidget(
          locations: locations,
          selectedLocations: selectedLocations,
          onLocationsSelected: (locations) {
            result = locations;
          },
          onUseCurrentLocation: onUseCurrentLocation,
          isLoading: isLoading,
          searchHint: searchHint,
          title: title,
          noLocationsMessage: noLocationsMessage,
          currentLocationText: currentLocationText,
          allowMultipleSelection: true,
        );
      },
    );

    return result;
  }

  static List<String> getLocationNames(
    List<ServiceLocationModel> locations, {
    String languageCode = 'en',
  }) {
    return locations.map((location) {
      if (languageCode == 'ur') {
        return location.name_ur.isNotEmpty ? location.name_ur : (location.name_ar.isNotEmpty ? location.name_ar : location.name);
      } else if (languageCode == 'ar') {
        return location.name_ar.isNotEmpty ? location.name_ar : location.name;
      }
      return location.name;
    }).toList();
  }
}
