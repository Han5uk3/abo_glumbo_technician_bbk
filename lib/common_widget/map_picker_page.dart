import 'dart:async';
import 'package:aboglumbo_bbk_panel/common_widget/place_suggestion_api.dart';
import 'package:aboglumbo_bbk_panel/helpers/local_store.dart';
import 'package:aboglumbo_bbk_panel/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/address.dart';
import '../models/nominatim_places_model.dart';
import '../services/nominatim_services.dart';
import '../styles/color.dart';

class LocationMapPicker extends StatefulWidget {
  final double? userLatitude;
  final double? userLongitude;
  final Function(AddressModel)? onAddressSelected;
  final Function(Map<String, dynamic>)? onLocationSelected;
  final bool isFromHomeAddress;

  final List<Map<String, dynamic>>? initialLocations;

  const LocationMapPicker({
    super.key,
    this.userLatitude,
    this.userLongitude,
    this.onAddressSelected,
    this.onLocationSelected,
    this.isFromHomeAddress = false,
    this.initialLocations,
  });

  @override
  State<LocationMapPicker> createState() => _LocationMapPickerState();
}

class _LocationMapPickerState extends State<LocationMapPicker> {
  GoogleMapController? mapController;
  late LatLng _initialPosition;
  LatLng? _selectedLocation;
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final _selectedLocationsSearchController = TextEditingController();
  String _selectedLocationsSearchQuery = '';
  List<String> _predictions = [];
  bool _isLoading = false;
  bool _mapReady = false;
  bool _hasLocationPermission = false;
  bool _locationInitialized = false;
  bool _isSearchingZone = false;
  bool _isZoneSearchLoading = false;
  final _zoneSearchController = TextEditingController();
  List<PlaceResult> _zoneSearchResults = [];
  Timer? _debounceTimer;

  final _buildingNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final bool _isAddingAddress = false;
  final _formKey = GlobalKey<FormState>();

  String _locationTitle = '';
  String _locationSubtitle = '';

  final List<LatLng> _currentPolygonPoints = [];
  Set<Polygon> _polygons = {};
  bool _isDrawingPolygon = false;

  final TextEditingController _nameEnController = TextEditingController();
  final TextEditingController _nameArController = TextEditingController();
  final TextEditingController _nameUrController = TextEditingController();
  final TextEditingController _priorityController = TextEditingController(
    text: '0',
  );
  final int _priority = 0;
  final GlobalKey<FormState> _dialogFormKey = GlobalKey<FormState>();

  String? _selectedZoneNameEn;
  String? _selectedZoneNameAr;
  String? _selectedZoneNameUr;

  static const List<Color> _regionColors = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  final arabicFullRegex = RegExp(r'''^[\u0600-\u06FF
       \u0750-\u077F
       \u08A0-\u08FF
       \uFB50-\uFDFF
       \uFE70-\uFEFF
       \u0660-\u0669
       \u06F0-\u06F9
       \u200C-\u200F
       \s\n\r\d
       \.\,\!\?\،\؛\؟\:\-\(\)\[\]\"\'\\u061F]+$''', multiLine: true);

  final urduFullRegex = RegExp(r'''^[\u0600-\u06FF
       \u0750-\u077F
       \u08A0-\u08FF
       \uFB50-\uFDFF
       \uFE70-\uFEFF
       \u0660-\u0669
       \u06F0-\u06F9
       \u200C-\u200F
       \s\n\r\d
       \.\,\!\?\،\؛\؟\:\-\(\)\[\]\"\'\\u061F]+$''', multiLine: true);

  List<Map<String, dynamic>> _selectedLocations = [];
  Set<Marker> _markers = {};

  static const Duration _debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_locationInitialized) {
      _locationInitialized = true;
      _initializeLocation();
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      setState(() {
        _hasLocationPermission = true;
      });
    }
  }

  void _initializeLocation() {
    const defaultLat = 24.7136; // Riyadh, Saudi Arabia
    const defaultLng = 46.6753;
    _initialPosition = LatLng(
      widget.userLatitude ?? defaultLat,
      widget.userLongitude ?? defaultLng,
    );
    _selectedLocation = _initialPosition;

    if (widget.initialLocations != null &&
        widget.initialLocations!.isNotEmpty) {
      _selectedLocations = widget.initialLocations!.map((loc) {
        final lat = (loc['lat'] as num?)?.toDouble();
        final lng = (loc['lng'] as num?)?.toDouble();

        // If lat/lng are missing (legacy or polygon-only), use default or first polygon point
        LatLng pos;
        if (lat != null && lng != null) {
          pos = LatLng(lat, lng);
        } else if (loc['polygon'] != null &&
            (loc['polygon'] as List).isNotEmpty) {
          final firstPoint = (loc['polygon'] as List).first;
          pos = LatLng(
            (firstPoint['lat'] as num).toDouble(),
            (firstPoint['lng'] as num).toDouble(),
          );
        } else {
          pos = _initialPosition;
        }

        return {...loc, 'location': pos};
      }).toList();
    }

    _updateMapElements();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() => _mapReady = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _moveCameraToLocation(_selectedLocation!, animate: false);
      _getAddressFromLatLng(_selectedLocation!);
    });
  }

  void _updateMapElements() {
    Set<Marker> updatedMarkers = {};
    Set<Polygon> updatedPolygons = {};

    for (var i = 0; i < _selectedLocations.length; i++) {
      var loc = _selectedLocations[i];
      LatLng pos = loc['location'];
      Color regionColor = _regionColors[i % _regionColors.length];

      updatedMarkers.add(
        Marker(
          markerId: MarkerId('m_$i'),
          position: pos,
          infoWindow: InfoWindow(
            title:
                loc['address'] ??
                AppLocalizations.of(context)!.locationNumber(i + 1),
            snippet:
                '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue((i * 35.0) % 360.0),
          draggable: false,
        ),
      );

      if (loc['polygon'] != null) {
        List<dynamic> rawPoints = loc['polygon'];
        List<LatLng> points = rawPoints
            .where((p) => p['lat'] != null && p['lng'] != null)
            .map(
              (p) => LatLng(
                (p['lat'] as num).toDouble(),
                (p['lng'] as num).toDouble(),
              ),
            )
            .toList();

        if (points.isNotEmpty) {
          updatedPolygons.add(
            Polygon(
              polygonId: PolygonId('p_$i'),
              points: points,
              fillColor: regionColor.withOpacity(0.2),
              strokeColor: regionColor,
              strokeWidth: 2,
            ),
          );
        }
      }
    }

    if (_currentPolygonPoints.isNotEmpty) {
      updatedPolygons.add(
        Polygon(
          polygonId: const PolygonId('current_drawing'),
          points: _currentPolygonPoints,
          fillColor: Colors.orange.withOpacity(0.2),
          strokeColor: Colors.orange,
          strokeWidth: 2,
        ),
      );

      for (var j = 0; j < _currentPolygonPoints.length; j++) {
        updatedMarkers.add(
          Marker(
            markerId: MarkerId('current_p_$j'),
            position: _currentPolygonPoints[j],
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueCyan,
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = updatedMarkers;
      _polygons = updatedPolygons;
    });
  }

  void _addLocation(
    String nameEn,
    String nameAr,
    String nameUr,
    int priority, {
    int? editIndex,
  }) {
    if (_selectedLocation == null) return;

    if (editIndex == null) {
      // Check if location already exists (only for new additions)
      bool exists = _selectedLocations.any((loc) {
        LatLng pos = loc['location'];
        return (pos.latitude - _selectedLocation!.latitude).abs() < 0.0001 &&
            (pos.longitude - _selectedLocation!.longitude).abs() < 0.0001;
      });

      if (exists) {
        _showSnackBar(
          AppLocalizations.of(context)!.locationAlreadyAdded,
          Colors.orange,
        );
        return;
      }
    }

    setState(() {
      final locData = {
        'location': _selectedLocation,
        'en_name': nameEn,
        'ar_name': nameAr,
        'ur_name': nameUr,
        'polygon': _currentPolygonPoints.isNotEmpty
            ? _currentPolygonPoints
                  .map((p) => {'lat': p.latitude, 'lng': p.longitude})
                  .toList()
            : (editIndex != null
                  ? _selectedLocations[editIndex]['polygon'] ?? []
                  : []),
        'priority': priority,
        'lat': _selectedLocation!.latitude,
        'lng': _selectedLocation!.longitude,
      };

      if (editIndex != null) {
        _selectedLocations[editIndex] = locData;
      } else {
        _selectedLocations.add(locData);
      }
      _currentPolygonPoints.clear();
      _updateMapElements();
    });
    _showSnackBar(
      editIndex != null
          ? AppLocalizations.of(context)!.locationUpdated
          : AppLocalizations.of(context)!.locationAddedToList,
      Colors.green,
    );
  }

  void _removeLocation(int index) {
    setState(() {
      _selectedLocations.removeAt(index);
      _updateMapElements();
    });
  }

  Future<void> _confirmRemoveLocation(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.removeLocation),
        content: Text(
          AppLocalizations.of(context)!.areYouSureYouWantToRemoveThisLocation,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _removeLocation(index);
    }
  }

  void _clearLocations() {
    setState(() {
      _selectedLocations.clear();
      _markers.clear();
      _polygons.clear();
    });
  }

  // Priority mapping handled by text controller now

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: Duration(seconds: 1),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    if (LocalStore.isCurrentUserAdmin()) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      setState(() => _isLoading = true);

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar(
          AppLocalizations.of(context)!.pleaseEnableLocationServices,
          Colors.red,
        );
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar(
            AppLocalizations.of(context)!.locationPermissionDenied,
            Colors.red,
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        setState(() {
          _hasLocationPermission = true;
        });
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      final currentLocation = LatLng(position.latitude, position.longitude);
      setState(() => _selectedLocation = currentLocation);

      await _moveCameraToLocation(currentLocation);
      await _getAddressFromLatLng(currentLocation);
    } catch (e) {
      _showSnackBar(AppLocalizations.of(context)!.locationError, Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      ).timeout(Duration(seconds: 10));

      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks[0];
        List<String> addressParts = [];

        if (p.name != null && p.name!.isNotEmpty) addressParts.add(p.name!);
        if (p.street != null && p.street!.isNotEmpty) {
          addressParts.add(p.street!);
        }
        if (p.subLocality != null && p.subLocality!.isNotEmpty) {
          addressParts.add(p.subLocality!);
        }
        if (p.locality != null && p.locality!.isNotEmpty) {
          addressParts.add(p.locality!);
        }

        String address = addressParts.join(', ');

        setState(() {
          _locationTitle = (p.locality != null && p.locality!.isNotEmpty)
              ? p.locality!
              : (p.subLocality != null && p.subLocality!.isNotEmpty)
              ? p.subLocality!
              : AppLocalizations.of(context)!.selectedLocation;
          _locationSubtitle = address.isNotEmpty
              ? address
              : '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      setState(() {
        _locationTitle = AppLocalizations.of(context)!.selectedLocation;
        _locationSubtitle =
            '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
      });
    }
  }

  Future<void> _searchPlaces(String input) async {
    if (input.isEmpty) {
      setState(() => _predictions.clear());
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () async {
      try {
        setState(() => _isLoading = true);
        final results = await getPlaceSuggestions(input);
        if (mounted) setState(() => _predictions = results);
      } catch (e) {
        debugPrint('Search error: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _moveCameraToPlace(String address) async {
    _searchFocusNode.unfocus();
    setState(() {
      _isLoading = true;
      _predictions.clear();
    });

    try {
      List<Location> locations = await locationFromAddress(
        address,
      ).timeout(Duration(seconds: 10));
      if (locations.isNotEmpty && mounted) {
        final latLng = LatLng(locations[0].latitude, locations[0].longitude);
        await _moveCameraToLocation(latLng);
      } else {
        _showSnackBar(
          AppLocalizations.of(context)!.locationNotFound,
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar(
        AppLocalizations.of(context)!.errorFindingLocation,
        Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onZoneSelected(PlaceResult item) async {
    final lat = item.latitude;
    final lng = item.longitude;
    final south = item.south;
    final north = item.north;
    final west = item.west;
    final east = item.east;

    final polygonPoints = [
      LatLng(south, west),
      LatLng(north, west),
      LatLng(north, east),
      LatLng(south, east),
    ];

    setState(() {
      _selectedLocation = LatLng(lat, lng);
      _selectedZoneNameEn = item.getNameEn();
      _selectedZoneNameAr = item.getNameAr();
      _selectedZoneNameUr = item.getNameUr();
      _currentPolygonPoints.clear();
      _currentPolygonPoints.addAll(polygonPoints);
      _isDrawingPolygon = true;
      _isSearchingZone = false;
      _zoneSearchController.clear();
      _zoneSearchResults.clear();
      _updateMapElements();
    });

    await _moveCameraToRegion(polygonPoints);
  }

  Future<void> _searchZones() async {
    final city = _zoneSearchController.text.trim();
    if (city.isEmpty) return;

    setState(() {
      _isZoneSearchLoading = true;
      _zoneSearchResults = [];
    });

    try {
      final jsonList = await NominatimService.search(
        query: city,
        locale: Localizations.localeOf(context),
        countryCode: 'sa',
      );

      _zoneSearchResults = jsonList
          .map((j) => PlaceResult.fromJson(j))
          .where(
            (place) =>
                place.addressType != 'state' && place.addressType != 'road',
          )
          .toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToSearchForZones),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isZoneSearchLoading = false;
        });
      }
    }
  }

  void _showLocationDetailsDialog({int? editIndex}) {
    if (editIndex != null) {
      final loc = _selectedLocations[editIndex];
      _nameEnController.text = loc['en_name'] ?? '';
      _nameArController.text = loc['ar_name'] ?? '';
      _nameUrController.text = loc['ur_name'] ?? '';
      _priorityController.text = (loc['priority'] ?? _priority).toString();
      _selectedLocation = loc['location'];
    } else {
      _nameEnController.text = _selectedZoneNameEn ?? _locationTitle;
      _nameArController.text = _selectedZoneNameAr ?? '';
      _nameUrController.text = _selectedZoneNameUr ?? '';
      _priorityController.text = _priority.toString();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        actionsAlignment: MainAxisAlignment.start,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.only(top: 20, left: 24, right: 24),
        title: Text(
          editIndex != null
              ? AppLocalizations.of(context)!.editLocation
              : AppLocalizations.of(context)!.addLocation,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        content: Form(
          key: _dialogFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  cursorColor: Colors.black,
                  controller: _nameEnController,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.englishName,
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    hintText: AppLocalizations.of(context)!.cityName,
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(
                        context,
                      )!.pleaseEnterEnglishName;
                    }

                    final normalizedValue = value.trim().toLowerCase();
                    final exists = _selectedLocations.asMap().entries.any((
                      entry,
                    ) {
                      if (editIndex != null && entry.key == editIndex) {
                        return false;
                      }
                      final name = entry.value['en_name']
                          ?.toString()
                          .trim()
                          .toLowerCase();
                      return name == normalizedValue;
                    });

                    if (exists) {
                      return AppLocalizations.of(
                            context,
                          )?.zoneNameAlreadyExists ??
                          'Name already exists';
                    }

                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  cursorColor: Colors.black,
                  controller: _nameArController,
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.arabicName,
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    hintText: AppLocalizations.of(context)!.nameArabic,
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(
                        context,
                      )!.pleaseEnterArabicName;
                    }
                    if (!arabicFullRegex.hasMatch(value)) {
                      return AppLocalizations.of(
                        context,
                      )!.pleaseEnterArabicNameOnly;
                    }

                    final normalizedValue = value.trim().toLowerCase();
                    final exists = _selectedLocations.asMap().entries.any((
                      entry,
                    ) {
                      if (editIndex != null && entry.key == editIndex) {
                        return false;
                      }
                      final name = entry.value['ar_name']
                          ?.toString()
                          .trim()
                          .toLowerCase();
                      return name == normalizedValue;
                    });

                    if (exists) {
                      return AppLocalizations.of(
                            context,
                          )?.zoneNameAlreadyExists ??
                          'Name already exists';
                    }

                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  cursorColor: Colors.black,
                  controller: _nameUrController,
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.right,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.urduName,
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    hintText: AppLocalizations.of(context)!.enterUrduName,
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context)!.pleaseEnterUrduName;
                    }
                    if (!urduFullRegex.hasMatch(value)) {
                      return AppLocalizations.of(
                        context,
                      )!.pleaseEnterUrduNameOnly;
                    }

                    final normalizedValue = value.trim().toLowerCase();
                    final exists = _selectedLocations.asMap().entries.any((
                      entry,
                    ) {
                      if (editIndex != null && entry.key == editIndex) {
                        return false;
                      }
                      final name = entry.value['ur_name']
                          ?.toString()
                          .trim()
                          .toLowerCase();
                      return name == normalizedValue;
                    });

                    if (exists) {
                      return AppLocalizations.of(
                            context,
                          )?.zoneNameAlreadyExists ??
                          'Name already exists';
                    }

                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _priorityController,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.priority,
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    hintText: AppLocalizations.of(context)!.enterPriority,
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context)!.pleaseEnterPriority;
                    }
                    if (int.tryParse(value) == null) {
                      return AppLocalizations.of(
                        context,
                      )!.pleaseEnterValidNumber;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentPolygonPoints.clear();
                _updateMapElements();
              });
            },
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_dialogFormKey.currentState!.validate()) {
                bool hasExistingPolygon =
                    editIndex != null &&
                    _selectedLocations[editIndex]['polygon'] != null &&
                    (_selectedLocations[editIndex]['polygon'] as List)
                        .isNotEmpty;

                bool hasDrawnPolygon = _currentPolygonPoints.isNotEmpty;

                if (!hasExistingPolygon && !hasDrawnPolygon) {
                  Navigator.pop(context);
                  _showSnackBar(
                    AppLocalizations.of(context)!.pleaseDrawPolygonAreaFirst,
                    Colors.red,
                  );
                  return;
                }

                final nameEn = _nameEnController.text.trim();
                final nameAr = _nameArController.text.trim();
                final nameUr = _nameUrController.text.trim();
                final priority =
                    int.tryParse(_priorityController.text.trim()) ?? _priority;

                Navigator.pop(context);
                _addLocation(
                  nameEn,
                  nameAr,
                  nameUr,
                  priority,
                  editIndex: editIndex,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              editIndex != null
                  ? AppLocalizations.of(context)!.update
                  : AppLocalizations.of(context)!.addArea,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _moveCameraToLocation(
    LatLng latLng, {
    bool animate = true,
  }) async {
    if (mapController == null) return;
    final update = CameraUpdate.newLatLngZoom(latLng, 15);
    if (animate) {
      await mapController!.animateCamera(update);
    } else {
      await mapController!.moveCamera(update);
    }
  }

  Future<void> _moveCameraToRegion(List<LatLng> points) async {
    if (mapController == null || points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Padding of 50 pixels around the region
    final update = CameraUpdate.newLatLngBounds(bounds, 50.0);
    await mapController!.animateCamera(update);
  }

  void _onMapTap(LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
      if (_isDrawingPolygon) {
        _currentPolygonPoints.add(latLng);
      }
      _predictions.clear();
      _locationTitle = AppLocalizations.of(context)!.gettingAddress;
      _updateMapElements();
    });
    _searchFocusNode.unfocus();
    _getAddressFromLatLng(latLng);
  }

  Widget _buildSearchResults() {
    if (_predictions.isEmpty) return SizedBox.shrink();
    return Container(
      constraints: BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _predictions.length,
        itemBuilder: (context, i) => Material(
          color: Colors.transparent,
          child: ListTile(
            dense: true,
            title: Text(_predictions[i], style: TextStyle(fontSize: 14)),
            leading: Icon(Icons.location_on, size: 20, color: Colors.blue),
            onTap: () => _moveCameraToPlace(_predictions[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildRadiusControl() {
    if (_isDrawingPolygon) {
      return SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPolygonPoints.length < 4) {
                    _showSnackBar(
                      AppLocalizations.of(
                        context,
                      )!.regionMustHaveAtLeast4Points,
                      Colors.orange,
                    );
                    return;
                  }
                  setState(() {
                    _isDrawingPolygon = false;
                  });
                  _showLocationDetailsDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentPolygonPoints.length >= 4
                      ? Colors.orange
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(
                    context,
                  )!.completeRegionWithPts(_currentPolygonPoints.length),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              onPressed: () {
                setState(() {
                  _isDrawingPolygon = false;
                  _currentPolygonPoints.clear();
                  _updateMapElements();
                });
              },
              icon: Icon(Icons.clear, color: Colors.red),
              tooltip: AppLocalizations.of(context)!.clearDrawing,
            ),
          ],
        ),
      );
    }

    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: _isSearchingZone
          ? Column(
              key: ValueKey('searching_zone'),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        cursorColor: Colors.black,
                        controller: _zoneSearchController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(
                            context,
                          )!.searchForZones,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.search),
                            onPressed: _searchZones,
                          ),
                        ),
                        onSubmitted: (_) => _searchZones(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _isSearchingZone = false;
                          _zoneSearchController.clear();
                          _zoneSearchResults.clear();
                        });
                      },
                    ),
                  ],
                ),
                if (_isZoneSearchLoading)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (!_isZoneSearchLoading && _zoneSearchResults.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _zoneSearchResults.length,
                    separatorBuilder: (_, __) => SizedBox(height: 2),
                    itemBuilder: (context, index) {
                      final item = _zoneSearchResults[index];
                      return Card(
                        color: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(
                            Icons.location_city,
                            color: Colors.blue,
                          ),
                          title: Text(
                            item.getLocalizedName(
                              Localizations.localeOf(context).languageCode,
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          subtitle: Text(
                            "${AppLocalizations.of(context)?.zoneType ?? 'Zone Type'} : ${item.addressType}",
                          ),

                          onTap: () => _onZoneSelected(item),
                        ),
                      );
                    },
                  ),
              ],
            )
          : Row(
              key: ValueKey('default_buttons'),
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isDrawingPolygon = true;
                        _currentPolygonPoints.clear();
                        _updateMapElements();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(
                              context,
                            )!.tapOnMapToDrawPolygonPoints,
                          ),
                          backgroundColor: Colors.blue,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: Icon(Icons.add_location_alt, color: Colors.white),
                    label: Text(
                      AppLocalizations.of(context)!.addRegion,
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _isSearchingZone = true),
                    icon: Icon(Icons.search, color: Colors.white),
                    label: Text(
                      AppLocalizations.of(context)!.searchForZones,
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLocationsList() {
    if (_selectedLocations.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.tapOnMapOrSearchToAddLocations,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedLocations.length} ${AppLocalizations.of(context)!.selected}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              if (_selectedLocations.isNotEmpty)
                TextButton(
                  onPressed: _clearLocations,
                  child: Text(
                    AppLocalizations.of(context)!.clearAll,
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          TextField(
            cursorColor: Colors.black,
            controller: _selectedLocationsSearchController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchForAPlace,
              prefixIcon: Icon(Icons.search, size: 20),
              suffixIcon: _selectedLocationsSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _selectedLocationsSearchController.clear();
                        setState(() {
                          _selectedLocationsSearchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.black),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.black),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _selectedLocationsSearchQuery = val;
              });
            },
          ),
          SizedBox(height: 8),
          Builder(
            builder: (context) {
              final filteredLocations = _selectedLocationsSearchQuery.isEmpty
                  ? _selectedLocations
                  : _selectedLocations.where((loc) {
                      final enName =
                          (loc['en_name'] as String?)?.toLowerCase() ?? '';
                      final arName =
                          (loc['ar_name'] as String?)?.toLowerCase() ?? '';
                      final query = _selectedLocationsSearchQuery.toLowerCase();
                      return enName.contains(query) || arName.contains(query);
                    }).toList();

              if (filteredLocations.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.noLocationsFound,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: filteredLocations.length,
                separatorBuilder: (_, __) => Divider(height: 1),
                itemBuilder: (context, i) {
                  var loc = filteredLocations[i];
                  // find original index for delete/edit actions
                  var originalIndex = _selectedLocations.indexOf(loc);
                  return Material(
                    color: Colors.transparent,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: i == 0 ? Colors.blue : Colors.green,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? (loc['ar_name'] ?? loc['en_name'])
                            : Localizations.localeOf(context).languageCode ==
                                  'ur'
                            ? (loc['ur_name'] ?? loc['en_name'])
                            : (loc['en_name'] ?? loc['ar_name']),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${AppLocalizations.of(context)!.priority}: ${loc['priority']} | ${AppLocalizations.of(context)!.pointsCount((loc['polygon'] as List).length)}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      onTap: () {
                        if (loc['polygon'] != null &&
                            (loc['polygon'] as List).isNotEmpty) {
                          List<LatLng> points = (loc['polygon'] as List)
                              .where(
                                (p) => p['lat'] != null && p['lng'] != null,
                              )
                              .map(
                                (p) => LatLng(
                                  (p['lat'] as num).toDouble(),
                                  (p['lng'] as num).toDouble(),
                                ),
                              )
                              .toList();
                          if (points.isNotEmpty) {
                            _moveCameraToRegion(points);
                            return;
                          }
                        }
                        if (loc['location'] != null) {
                          _moveCameraToLocation(loc['location']);
                        }
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            onPressed: () => _showLocationDetailsDialog(
                              editIndex: originalIndex,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                _confirmRemoveLocation(originalIndex),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.chooseLocations),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                backgroundColor: Colors.white,
                title: Text(AppLocalizations.of(context)!.howToUse),
                content: Text(
                  AppLocalizations.of(context)!.mapPickerInstructions,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.ok),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full-screen Map
          Stack(
            children: [
              if (!_mapReady) Center(child: CircularProgressIndicator()),
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _initialPosition,
                  zoom: 14,
                ),
                onTap: _onMapTap,
                markers: _markers,
                polygons: _polygons,
                myLocationEnabled: _hasLocationPermission,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: true,
              ),

              // Search Bar
              Positioned(
                top: 15,
                left: 15,
                right: 15,
                child: Column(
                  children: [
                    Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _searchPlaces,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(
                            context,
                          )!.searchForAPlace,
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _predictions.clear());
                                    _searchFocusNode.unfocus();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildSearchResults(),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: _getCurrentLocation,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.my_location,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  AppLocalizations.of(context)!.myLocation,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Loading indicator
              if (_isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),

          // Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.1,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),

                      // Current Location Card
                      LocationCard(
                        title: _locationTitle.isNotEmpty
                            ? _locationTitle
                            : AppLocalizations.of(context)!.noLocationSelected,
                        subtitle: _locationSubtitle.isNotEmpty
                            ? _locationSubtitle
                            : AppLocalizations.of(context)!.tapOnMapToSelect,
                        dense: true,
                      ),
                      SizedBox(height: 12),

                      // Radius Control
                      _buildRadiusControl(),
                      SizedBox(height: 12),

                      // Selected Locations List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.selectedLocations,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_selectedLocations.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_selectedLocations.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      _buildLocationsList(),
                      SizedBox(height: 16),

                      // Confirm Button
                      if (_selectedLocations.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_isLoading) return;
                              if (widget.onLocationSelected != null) {
                                widget.onLocationSelected!({
                                  'locations': _selectedLocations,
                                  'priority': _priority,
                                  'count': _selectedLocations.length,
                                });
                              }
                              _showSnackBar(
                                AppLocalizations.of(
                                  context,
                                )!.locationsSelectedCount(
                                  _selectedLocations.length,
                                ),
                                Colors.green,
                              );
                              Navigator.pop(context, _selectedLocations);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: Size(double.infinity, 45),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.confirmLocations,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),

                      SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _buildingNameController.dispose();
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _nameEnController.dispose();
    _nameArController.dispose();
    _priorityController.dispose();
    mapController?.dispose();
    super.dispose();
  }
}

// LocationCard widget
class LocationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool dense;

  const LocationCard({
    required this.title,
    required this.subtitle,
    this.dense = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(dense ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue, size: dense ? 18 : 20),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: dense ? 13 : 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: dense ? 11 : 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
