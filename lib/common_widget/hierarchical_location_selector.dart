import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:aboglumbo_bbk_panel/models/hierarchical_location.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';

class HierarchicalLocationSelector extends StatefulWidget {
  final List<SelectedCity> selectedCities;
  final Function(List<SelectedCity>) onChanged;
  final String? Function(List<SelectedCity>?)? validator;

  const HierarchicalLocationSelector({
    super.key,
    required this.selectedCities,
    required this.onChanged,
    this.validator,
  });

  @override
  State<HierarchicalLocationSelector> createState() =>
      _HierarchicalLocationSelectorState();
}

class _HierarchicalLocationSelectorState
    extends State<HierarchicalLocationSelector> {
  List<HierarchicalLocationModel>? hierarchicalData;
  bool isLoading = true;
  String? errorMessage;
  int _totalCitiesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadHierarchicalData();
  }

  Future<void> _loadHierarchicalData() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/saudi_hierarchical.json',
      );
      final jsonData = jsonDecode(jsonString) as List;
      final data = jsonData
          .map((item) => HierarchicalLocationModel.fromJson(item))
          .toList();

      // Calculate total cities count
      int totalCities = 0;
      for (final region in data) {
        totalCities += region.cities.length;
      }

      setState(() {
        hierarchicalData = data;
        _totalCitiesCount = totalCities;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load location data: $e';
        isLoading = false;
      });
    }
  }


  void _showLocationSelector() {
    if (hierarchicalData == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, modalState) => _LocationSelectorBottomSheet(
          hierarchicalData: hierarchicalData!,
          selectedCities: widget.selectedCities,
          totalCitiesCount: _totalCitiesCount,
          onConfirm: (selectedCities) {
            print("Selected 79 line  : ${selectedCities}");
            modalState((){

            });
            widget.onChanged(selectedCities);
            print("Selected 79 line  : ${selectedCities}");
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
  //
  // void _showLocationSelector() {
  //   if (hierarchicalData == null) return;
  //
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (context) => _LocationSelectorBottomSheet(
  //       hierarchicalData: hierarchicalData!,
  //       selectedCities: widget.selectedCities,
  //       totalCitiesCount: _totalCitiesCount,
  //       onConfirm: (selectedCities) {
  //         widget.onChanged(selectedCities);
  //         print("Selected 79 line  : ${selectedCities}");
  //         Navigator.pop(context);
  //       },
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.selectLocations ?? 'Select Cities',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ],
      );
    }

    if (errorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.selectLocations ?? 'Select Cities',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      );
    }

    return FormField<List<SelectedCity>>(
      validator: widget.validator,
      builder: (FormFieldState<List<SelectedCity>> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)?.selectLocations ?? 'Select Cities',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showLocationSelector,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: field.hasError ? Colors.red : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: widget.selectedCities.isEmpty
                          ? Text(
                              AppLocalizations.of(context)?.searchLocation ??
                                  'Tap to select cities',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            )
                          : Text(
                              'Selected ${widget.selectedCities.length}/$_totalCitiesCount cities',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.green.shade700,
                              ),
                            ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  field.errorText ?? '',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LocationSelectorBottomSheet extends StatefulWidget {
  final List<HierarchicalLocationModel> hierarchicalData;
  final List<SelectedCity> selectedCities;
  final int totalCitiesCount;
  final Function(List<SelectedCity>) onConfirm;

  const _LocationSelectorBottomSheet({
    required this.hierarchicalData,
    required this.selectedCities,
    required this.totalCitiesCount,
    required this.onConfirm,
  });

  @override
  State<_LocationSelectorBottomSheet> createState() =>
      _LocationSelectorBottomSheetState();
}

class _LocationSelectorBottomSheetState
    extends State<_LocationSelectorBottomSheet> {
  late List<SelectedCity> tempSelectedCities;
  HierarchicalLocationModel? selectedRegion;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    tempSelectedCities = List.from(widget.selectedCities);
  }

  List<HierarchicalLocationModel> get filteredRegions {
    if (searchQuery.isEmpty) return widget.hierarchicalData;
    return widget.hierarchicalData
        .where(
          (region) =>
              region.region_en.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              region.region_ar.contains(searchQuery),
        )
        .toList();
  }

  List<City> get filteredCities {
    if (selectedRegion == null) return [];
    if (searchQuery.isEmpty) return selectedRegion!.cities;
    return selectedRegion!.cities
        .where(
          (city) =>
              city.city_en.toLowerCase().contains(searchQuery.toLowerCase()) ||
              city.city_ar.contains(searchQuery),
        )
        .toList();
  }

  bool isCitySelected(City city, {String? regionId}) {
    return tempSelectedCities.any(
      (c) =>
          c.cityId == city.city_id &&
          (regionId == null || c.regionId == regionId),
    );
  }

  void toggleCity(City city) {
    setState(() {
      final selectedCity = tempSelectedCities.firstWhere(
        (c) =>
            c.cityId == city.city_id && c.regionId == selectedRegion!.region_id,
        orElse: () => SelectedCity(
          regionId: selectedRegion!.region_id,
          regionEn: selectedRegion!.region_en,
          regionAr: selectedRegion!.region_ar,
          cityId: city.city_id,
          cityEn: city.city_en,
          cityAr: city.city_ar,
        ),
      );
print("The temp : 315 : ${selectedCity}");
      if (tempSelectedCities.contains(selectedCity)) {
        setState(() {

        });
        tempSelectedCities.remove(selectedCity);
      } else {
        setState(() {

        });
        tempSelectedCities.add(selectedCity);
      }
      widget.onConfirm(tempSelectedCities);
    });
  }

  // Check if all cities in current region are selected
  bool get areAllCitiesInRegionSelected {
    if (selectedRegion == null) return false;
    return areAllCitiesSelectedInRegion(selectedRegion!);
  }

  // Check if all cities in a specific region are selected
  bool areAllCitiesSelectedInRegion(HierarchicalLocationModel region) {
    if (region.cities.isEmpty) return false;
    return region.cities.every(
      (city) => isCitySelected(city, regionId: region.region_id),
    );
  }

  // Check if all cities in all regions are selected
  bool get areAllCitiesSelected {
    return tempSelectedCities.length == widget.totalCitiesCount;
  }

  // Select/Deselect all cities in current region
  void toggleAllCitiesInRegion() {
    if (selectedRegion == null) {
      return;
    }

    setState(() {
      if (areAllCitiesInRegionSelected) {
        // Deselect all cities in this region

        tempSelectedCities.removeWhere(
          (c) => c.regionId == selectedRegion!.region_id,
        );
      } else {
        // Select all cities in this region

        for (final city in selectedRegion!.cities) {
          if (!isCitySelected(city, regionId: selectedRegion!.region_id)) {
            tempSelectedCities.add(
              SelectedCity(
                regionId: selectedRegion!.region_id,
                regionEn: selectedRegion!.region_en,
                regionAr: selectedRegion!.region_ar,
                cityId: city.city_id,
                cityEn: city.city_en,
                cityAr: city.city_ar,
              ),
            );
          }
        }
      }
    });
  }

  // Select/Deselect all cities in all regions
  void toggleAllCities() {
    setState(() {
      if (areAllCitiesSelected) {
        // Deselect all
        tempSelectedCities.clear();
      } else {
        // Select all

        tempSelectedCities.clear();
        for (final region in widget.hierarchicalData) {
          for (final city in region.cities) {
            tempSelectedCities.add(
              SelectedCity(
                regionId: region.region_id,
                regionEn: region.region_en,
                regionAr: region.region_ar,
                cityId: city.city_id,
                cityEn: city.city_en,
                cityAr: city.city_ar,
              ),
            );
          }
        }
      }
    });
  }

  // Get count of selected cities in a region
  int getSelectedCitiesCountInRegion(HierarchicalLocationModel region) {
    return tempSelectedCities
        .where((c) => c.regionId == region.region_id)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Cities',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search province or city',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Select All button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: toggleAllCities,
                        icon: Icon(
                          areAllCitiesSelected
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 20,
                        ),
                        label: Text(
                          areAllCitiesSelected
                              ? 'Deselect All (${tempSelectedCities.length})'
                              : 'Select All Cities (${widget.totalCitiesCount})',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: areAllCitiesSelected
                              ? Colors.red
                              : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Regions list
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Provinces',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                key: ValueKey(
                                  'provinces_${tempSelectedCities.length}',
                                ),
                                controller: scrollController,
                                itemCount: filteredRegions.length,
                                itemBuilder: (context, index) {
                                  final region = filteredRegions[index];
                                  final isSelected =
                                      selectedRegion?.region_id ==
                                      region.region_id;
                                  final selectedCount =
                                      getSelectedCitiesCountInRegion(region);
                                  final totalCount = region.cities.length;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedRegion = region;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.blue.withOpacity(0.1)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  region.region_en,
                                                  style: GoogleFonts.dmSans(
                                                    fontWeight: isSelected
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                    color: isSelected
                                                        ? Colors.blue
                                                        : Colors.black,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                if (selectedCount > 0)
                                                  Text(
                                                    '$selectedCount/$totalCount',
                                                    style: GoogleFonts.dmSans(
                                                      fontSize: 10,
                                                      color:
                                                          Colors.green.shade700,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (areAllCitiesSelectedInRegion(
                                            region,
                                          ))
                                            Icon(
                                              Icons.check_circle,
                                              size: 16,
                                              color: Colors.green,
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Cities list
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Cities',
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (selectedRegion != null)
                                  TextButton(
                                    onPressed: toggleAllCitiesInRegion,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size(50, 24),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      areAllCitiesInRegionSelected
                                          ? 'Deselect All in Province'
                                          : 'Select All in Province',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: filteredCities.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Select province',
                                        style: GoogleFonts.dmSans(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  :

                              ListView.builder(
                                      controller: scrollController,
                                      itemCount: filteredCities.length,
                                      itemBuilder: (context, index) {
                                        final city = filteredCities[index];
                                        final isSelected = isCitySelected(
                                          city,
                                          regionId: selectedRegion!.region_id,
                                        );

                                        return GestureDetector(
                                          onTap: () {
                                            toggleCity(city);
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.green.withOpacity(
                                                      0.2,
                                                    )
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: isSelected
                                                  ? Border.all(
                                                      color: Colors.green,
                                                    )
                                                  : null,
                                            ),
                                            padding: const EdgeInsets.all(8),
                                            child: Row(
                                              children: [
                                                Checkbox(
                                                  value: isSelected,
                                                  onChanged: (_) {
                                                    toggleCity(city);
                                                  },
                                                ),
                                                Expanded(
                                                  child: Text(
                                                    city.city_en,
                                                    style: GoogleFonts.dmSans(
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom buttons
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          print("confirmed : ${tempSelectedCities.length.toString()}");
                          setState(() {

                          });

                          widget.selectedCities.addAll(tempSelectedCities);
                          // widget.onConfirm(tempSelectedCities);
                        },
                        child: Text('Confirm (${tempSelectedCities.length})'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
