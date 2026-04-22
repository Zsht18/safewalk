import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'dashboard/dashboard_constants.dart';
import 'services/location_formatter_service.dart';

const Color _pickerNavy = Color(0xFF043464);

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _selectedPoint;
  String? _selectedAddress;
  bool _isResolvingCurrentLocation = false;

  void _selectPoint(LatLng point) {
    setState(() {
      _selectedPoint = point;
      _selectedAddress = null;
    });
    _resolveSelectedAddress(point);
  }

  Future<void> _resolveSelectedAddress(LatLng point) async {
    final resolved = await LocationFormatterService.resolveAddress(
      latitude: point.latitude,
      longitude: point.longitude,
    );

    if (!mounted || _selectedPoint != point) {
      return;
    }

    setState(() {
      _selectedAddress = resolved;
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isResolvingCurrentLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final point = LatLng(position.latitude, position.longitude);
      final resolved = await LocationFormatterService.resolveAddress(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedPoint = point;
        _selectedAddress = resolved;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResolvingCurrentLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomCardMaxHeight = MediaQuery.sizeOf(context).height * 0.38;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8FD),
      appBar: AppBar(
        backgroundColor: _pickerNavy,
        foregroundColor: Colors.white,
        title: const Text(
          'Pick Location',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _selectedPoint ?? defaultMapCenter,
              initialZoom: 13,
              onTap: (tapPosition, point) => _selectPoint(point),
            ),
            children: [
              TileLayer(
                urlTemplate: geoapifyTileUrl,
                userAgentPackageName: 'com.safewalk.app',
              ),
              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      width: 52,
                      height: 52,
                      child: const Icon(Icons.location_pin, color: Colors.redAccent, size: 46),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: bottomCardMaxHeight),
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_selectedAddress != null)
                          Text(
                            _selectedAddress!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                              color: _pickerNavy,
                            ),
                          )
                        else if (_selectedPoint != null)
                          const Text(
                            'Resolving location...',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _pickerNavy,
                            ),
                          )
                        else
                          const Text(
                            'Tap anywhere on the map to drop a pin.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _pickerNavy,
                            ),
                          ),
                        if (_selectedPoint != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${_selectedPoint!.latitude.toStringAsFixed(6)}, ${_selectedPoint!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _isResolvingCurrentLocation ? null : _useCurrentLocation,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _pickerNavy, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          icon: _isResolvingCurrentLocation
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _pickerNavy),
                                )
                              : const Icon(Icons.my_location, color: _pickerNavy, size: 18),
                          label: Text(
                            _isResolvingCurrentLocation ? 'LOCATING...' : 'USE CURRENT LOCATION',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _selectedPoint == null
                                    ? null
                                    : () {
                                        setState(() {
                                          _selectedPoint = null;
                                          _selectedAddress = null;
                                        });
                                      },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: _pickerNavy, width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                ),
                                child: const Text(
                                  'CLEAR',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _selectedPoint == null
                                    ? null
                                    : () {
                                        Navigator.of(context).pop(_selectedPoint);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _pickerNavy,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                ),
                                child: const Text(
                                  'USE PIN',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
