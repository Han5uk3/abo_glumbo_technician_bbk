import 'dart:async';
import 'package:aboglumbo_bbk_panel/common_widget/place_suggestion_api.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../helpers/text_form.dart';
import '../l10n/app_localizations.dart';
import '../models/address.dart';
import 'loader.dart';
import 'location_card.dart';

class LocationMapPicker extends StatefulWidget {
  final double? userLatitude;
  final double? userLongitude;
  final Function(AddressModel)? onAddressSelected;
  final Function(Map<String, dynamic>)? onLocationSelected;
  final bool isFromHomeAddress;

  const LocationMapPicker({
    super.key,
    this.userLatitude,
    this.userLongitude,
    this.onAddressSelected,
    this.onLocationSelected,
    this.isFromHomeAddress = false,
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
  List<String> _predictions = [];
  bool _isLoading = false;
  bool _mapReady = false;
  Timer? _debounceTimer;

  final _buildingNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  bool _isAddingAddress = false;
  final _formKey = GlobalKey<FormState>();

  String _locationTitle = '';
  String _locationSubtitle = '';

  // Multiple location selection - always enabled
  double _radiusInMeters = 500;
  bool _showRadius = true;
  Set<Circle> _circles = {};
  static const double _minRadius = 100;
  static const double _maxRadius = 50000;

  List<Map<String, dynamic>> _selectedLocations = [];
  Set<Marker> _markers = {};

  static const Duration _debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  void _initializeLocation() {
    const defaultLat = 12.9716;
    const defaultLng = 77.5946;
    _initialPosition = LatLng(
      widget.userLatitude ?? defaultLat,
      widget.userLongitude ?? defaultLng,
    );
    _selectedLocation = _initialPosition;
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
    Set<Circle> updatedCircles = {};

    for (var i = 0; i < _selectedLocations.length; i++) {
      var loc = _selectedLocations[i];
      LatLng pos = loc['location'];

      updatedMarkers.add(Marker(
        markerId: MarkerId('m_$i'),
        position: pos,
        infoWindow: InfoWindow(
          title: loc['address'] ?? 'Location ${i + 1}',
          snippet: '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          i == 0 ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueGreen + (i * 10).toDouble(),
        ),
        draggable: false,
      ));

      if (_showRadius) {
        updatedCircles.add(Circle(
          circleId: CircleId('c_$i'),
          center: pos,
          radius: _radiusInMeters,
          fillColor: Colors.blue.withOpacity(0.1),
          strokeColor: i == 0 ? Colors.blue : Colors.green,
          strokeWidth: 2,
        ));
      }
    }

    setState(() {
      _markers = updatedMarkers;
      _circles = updatedCircles;
    });
  }

  void _addLocation() {
    if (_selectedLocation == null) return;

    // Check if location already exists
    bool exists = _selectedLocations.any((loc) {
      LatLng pos = loc['location'];
      // Compare with small tolerance for floating point
      return (pos.latitude - _selectedLocation!.latitude).abs() < 0.0001 &&
          (pos.longitude - _selectedLocation!.longitude).abs() < 0.0001;
    });

    if (exists) {
      _showSnackBar('Location already added', Colors.orange);
      return;
    }

    setState(() {
      _selectedLocations.add({
        'location': _selectedLocation,
        'address': _locationTitle.isNotEmpty ? _locationTitle : 'Location ${_selectedLocations.length + 1}',
        'fullAddress': _locationSubtitle,
        'lat': _selectedLocation!.latitude,
        'lng': _selectedLocation!.longitude,
      });
      _updateMapElements();
    });
    _showSnackBar('Location added to list', Colors.green);
  }

  void _removeLocation(int index) {
    setState(() {
      _selectedLocations.removeAt(index);
      _updateMapElements();
    });
  }

  void _clearLocations() {
    setState(() {
      _selectedLocations.clear();
      _markers.clear();
      if (!_showRadius) _circles.clear();
    });
  }

  void _onRadiusChanged(double value) {
    setState(() {
      _radiusInMeters = value;
      _updateMapElements();
    });
  }

  void _toggleRadius() {
    setState(() {
      _showRadius = !_showRadius;
      _updateMapElements();
    });
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: Duration(seconds: 1),
      backgroundColor: color,
    ));
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoading = true);

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar('Please enable location services', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission denied', Colors.red);
          setState(() => _isLoading = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      final currentLocation = LatLng(position.latitude, position.longitude);
      setState(() => _selectedLocation = currentLocation);

      await _moveCameraToLocation(currentLocation);
      await _getAddressFromLatLng(currentLocation);

      // Always ask to add in multi-select mode
      _showAddConfirmationDialog();

    } catch (e) {
      _showSnackBar('Location error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude, latLng.longitude,
      ).timeout(Duration(seconds: 10));

      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks[0];
        List<String> addressParts = [];

        if (p.name != null && p.name!.isNotEmpty) addressParts.add(p.name!);
        if (p.street != null && p.street!.isNotEmpty) addressParts.add(p.street!);
        if (p.subLocality != null && p.subLocality!.isNotEmpty) addressParts.add(p.subLocality!);
        if (p.locality != null && p.locality!.isNotEmpty) addressParts.add(p.locality!);

        String address = addressParts.join(', ');

        setState(() {
          _locationTitle = p.name ?? p.subLocality ?? p.locality ?? 'Selected Location';
          _locationSubtitle = address.isNotEmpty ? address : '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (e) {
      setState(() {
        _locationTitle = 'Selected Location';
        _locationSubtitle = '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
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
        print('Search error: $e');
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
      List<Location> locations = await locationFromAddress(address).timeout(Duration(seconds: 10));
      if (locations.isNotEmpty && mounted) {
        final latLng = LatLng(locations[0].latitude, locations[0].longitude);
        await _moveCameraToLocation(latLng);
        setState(() {
          _selectedLocation = latLng;
        });
        await _getAddressFromLatLng(latLng);

        // Show add confirmation dialog
        _showAddConfirmationDialog();
      } else {
        _showSnackBar('Location not found', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error finding location', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Location'),
        content: Text('Do you want to add this location to your list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addLocation();
            },
            child: Text('Yes', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Future<void> _moveCameraToLocation(LatLng latLng, {bool animate = true}) async {
    if (mapController == null) return;
    final update = CameraUpdate.newLatLngZoom(latLng, 15);
    if (animate) {
      await mapController!.animateCamera(update);
    } else {
      await mapController!.moveCamera(update);
    }
  }

  void _onMapTap(LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
      _predictions.clear();
      _locationTitle = 'Getting address...';
    });
    _searchFocusNode.unfocus();
    _getAddressFromLatLng(latLng);

    // Show option to add after getting address
    Future.delayed(Duration(milliseconds: 500), () {
      _showAddConfirmationDialog();
    });
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
          ]
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _predictions.length,
        itemBuilder: (context, i) => ListTile(
          dense: true,
          title: Text(_predictions[i], style: TextStyle(fontSize: 14)),
          leading: Icon(Icons.location_on, size: 20, color: Colors.blue),
          onTap: () => _moveCameraToPlace(_predictions[i]),
        ),
      ),
    );
  }

  Widget _buildRadiusControl() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!)
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Service Radius', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
          Row(children: [
            IconButton(
                icon: Icon(_showRadius ? Icons.visibility : Icons.visibility_off, size: 18, color: Colors.blue),
                onPressed: _toggleRadius,
                padding: EdgeInsets.zero,
                constraints: BoxConstraints()
            ),
            Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)
                ),
                child: Text(
                    '${(_radiusInMeters / 1000).toStringAsFixed(1)} km',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.w600)
                )
            ),
          ]),
        ]),
        SliderTheme(
            data: SliderThemeData(
                activeTrackColor: Colors.blue,
                thumbColor: Colors.blue,
                overlayColor: Colors.blue.withOpacity(0.1)
            ),
            child: Slider(
                value: _radiusInMeters,
                min: _minRadius,
                max: _maxRadius,
                divisions: 20,
                label: '${(_radiusInMeters / 1000).toStringAsFixed(1)} km',
                onChanged: _onRadiusChanged
            )
        ),
      ]),
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
            'Tap on map or search to add locations',
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
          border: Border.all(color: Colors.grey[300]!)
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
              '${_selectedLocations.length} Selected',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)
          ),
          if (_selectedLocations.isNotEmpty)
            TextButton(
                onPressed: _clearLocations,
                child: Text('Clear All', style: TextStyle(color: Colors.red, fontSize: 12))
            ),
        ]),
        SizedBox(height: 8),
        Container(
          constraints: BoxConstraints(maxHeight: 150),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _selectedLocations.length,
            separatorBuilder: (_, __) => Divider(height: 1),
            itemBuilder: (context, i) {
              var loc = _selectedLocations[i];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: i == 0 ? Colors.blue : Colors.green,
                    child: Text(
                        '${i + 1}',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                    )
                ),
                title: Text(
                  loc['address'] ?? 'Location',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                    '${loc['lat'].toStringAsFixed(4)}, ${loc['lng'].toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600])
                ),
                trailing: IconButton(
                  icon: Icon(Icons.close, size: 16, color: Colors.red),
                  onPressed: () => _removeLocation(i),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              );
            },
          ),
        ),
        if (_selectedLocation != null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: ElevatedButton.icon(
              onPressed: _addLocation,
              icon: Icon(Icons.add, size: 16),
              label: Text('Add Current Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Choose Multiple Locations'),
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.add_location_alt, color: Colors.blue, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Multi-Select',
                    style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('How to use'),
                content: Text(
                    '• Tap map to select a location\n'
                        '• Use search to find places\n'
                        '• Add multiple locations to the list\n'
                        '• Adjust radius - applies to all locations\n'
                        '• Remove individual locations with X\n'
                        '• Confirm to save all selected locations'
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Map section (60%)
          Expanded(
            flex: 3,

            child: Stack(
              children: [
                if (!_mapReady)
                  Center(child: CircularProgressIndicator()),
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 14),
                  onTap: _onMapTap,
                  markers: _markers,
                  circles: _circles,
                  myLocationEnabled: true,
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
                            hintText: 'Search for a place',
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
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      _buildSearchResults(),
                    ],
                  ),
                ),

                // My Location Button
                Positioned(
                  bottom: 10,
                  left: 20,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: _getCurrentLocation,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.my_location, size: 16, color: Colors.blue),
                            SizedBox(width: 4),
                            Text('My Location', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
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
          ),

          // Bottom panel (40%)
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 1)],
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Location Card
                    LocationCard(
                      title: _locationTitle.isNotEmpty ? _locationTitle : 'No location selected',
                      subtitle: _locationSubtitle.isNotEmpty ? _locationSubtitle : 'Tap on map to select',
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
                        Text('Selected Locations', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
                        if (_selectedLocations.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_selectedLocations.length}',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                            if (widget.onLocationSelected != null) {
                              widget.onLocationSelected!({
                                'locations': _selectedLocations,
                                'radius': _radiusInMeters,
                                'count': _selectedLocations.length,
                              });
                            }
                            _showSnackBar('${_selectedLocations.length} locations selected', Colors.green);
                            Navigator.pop(context, {
                              'locations': _selectedLocations,
                              'radius': _radiusInMeters,
                            });
                          },
                          child: Text('Confirm ${_selectedLocations.length} Locations', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
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
    super.key
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
                  style: GoogleFonts.poppins(
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
                        color: Colors.grey[600]
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
