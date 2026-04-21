import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../api_service.dart';
import '../../location_picker_screen.dart';
import '../../services/location_formatter_service.dart';
import '../dashboard_constants.dart';
import '../dashboard_widgets.dart';

class CreateReportTab extends StatefulWidget {
  const CreateReportTab({
    super.key,
    required this.profileFuture,
    required this.onReportSubmitted,
  });

  final Future<UserProfile> profileFuture;
  final Future<void> Function() onReportSubmitted;

  @override
  State<CreateReportTab> createState() => _CreateReportTabState();
}

class _CreateReportTabState extends State<CreateReportTab> {
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _reportController = TextEditingController();

  LatLng? _selectedPoint;
  bool _isSubmitting = false;
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant CreateReportTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileFuture != widget.profileFuture) {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _locationController.dispose();
    _reportController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await widget.profileFuture;
      if (!mounted) {
        return;
      }
      setState(() {
        _fullnameController.text = profile.fullname;
        _locationController.text = profile.location;
        _profileLoaded = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _profileLoaded = true;
      });
    }
  }

  Future<void> _pickLocation() async {
    final selectedPoint = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => const LocationPickerScreen(),
      ),
    );

    if (selectedPoint == null || !mounted) {
      return;
    }

    setState(() {
      _selectedPoint = selectedPoint;
    });

    await _fillReadableAddress(selectedPoint);
  }

  Future<void> _fillReadableAddress(LatLng point) async {
    final resolved = await LocationFormatterService.resolveAddress(
      latitude: point.latitude,
      longitude: point.longitude,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _locationController.text = resolved;
    });
  }

  Future<void> _submitReport() async {
    if (_fullnameController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _reportController.text.trim().isEmpty ||
        _selectedPoint == null) {
      _showSnackBar('Select a pin and complete the report details.', Colors.red);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.submitReport(
        fullname: _fullnameController.text.trim(),
        location: _locationController.text.trim(),
        report: _reportController.text.trim(),
        latitude: _selectedPoint!.latitude,
        longitude: _selectedPoint!.longitude,
      );

      _showSnackBar('Report submitted successfully.', Colors.green);
      _reportController.clear();
      await widget.onReportSubmitted();
    } catch (error) {
      _showSnackBar(error.toString(), Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ScreenHeading(
            title: 'CREATE A REPORT',
            subtitle: 'Pin the incident, describe it, and send it to the database.',
          ),
          const SizedBox(height: 18),
          FormPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const LabelText(text: 'FULLNAME'),
                const SizedBox(height: 8),
                TextField(
                  controller: _fullnameController,
                  readOnly: true,
                  decoration: _fieldDecoration('User fullname from profile'),
                ),
                const SizedBox(height: 16),
                const LabelText(text: 'LOCATION'),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationController,
                  readOnly: true,
                  decoration: _fieldDecoration(
                    _selectedPoint == null ? 'Tap to pin a location on the map' : 'Pinned location selected',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.map_outlined, color: darkNavy),
                      onPressed: _pickLocation,
                    ),
                  ),
                  onTap: _pickLocation,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: _selectedPoint ?? defaultMapCenter,
                        initialZoom: 13,
                        onTap: (tapPosition, point) {
                          setState(() {
                            _selectedPoint = point;
                          });
                          _fillReadableAddress(point);
                        },
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
                                width: 48,
                                height: 48,
                                child: const Icon(Icons.location_pin, size: 44, color: Colors.redAccent),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const LabelText(text: 'REPORT DESCRIPTION'),
                const SizedBox(height: 8),
                TextField(
                  controller: _reportController,
                  maxLines: 5,
                  decoration: _fieldDecoration('Describe what happened, who is involved, or what you need.'),
                ),
                const SizedBox(height: 18),
                _isSubmitting
                    ? const Center(child: CircularProgressIndicator(color: darkNavy))
                    : SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _profileLoaded ? _submitReport : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkNavy,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: const Text(
                            'PASS REPORT',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hintText, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }
}
