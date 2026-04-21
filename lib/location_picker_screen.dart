import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'dashboard/dashboard_constants.dart';

const Color _pickerNavy = Color(0xFF043464);

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? _selectedPoint;

  void _selectPoint(LatLng point) {
    setState(() {
      _selectedPoint = point;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    Text(
                      _selectedPoint == null
                          ? 'Tap anywhere on the map to drop a pin.'
                          : 'Selected: ${_selectedPoint!.latitude.toStringAsFixed(6)}, ${_selectedPoint!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _pickerNavy,
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
        ],
      ),
    );
  }
}
