import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../api_service.dart';
import '../../location_picker_screen.dart';
import '../../services/location_formatter_service.dart';
import '../dashboard_constants.dart';
import '../dashboard_widgets.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({
    super.key,
    required this.profileFuture,
    required this.onProfileUpdated,
  });

  final Future<UserProfile> profileFuture;
  final Future<void> Function() onProfileUpdated;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  UserProfile? _profile;
  String? _error;
  bool _isUpdatingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await widget.profileFuture;
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = profile;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
      });
    }
  }

  @override
  void didUpdateWidget(covariant ProfileTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileFuture != widget.profileFuture) {
      _loadProfile();
    }
  }

  Future<void> _openEditLocationDialog() async {
    final profile = _profile;
    if (profile == null) {
      return;
    }

    final controller = TextEditingController(text: profile.location);
    String pendingLocation = profile.location;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Update Location'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'City, street, province, zip',
                    ),
                    onChanged: (value) {
                      pendingLocation = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final selectedPoint = await Navigator.of(context).push<LatLng>(
                        MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                      );
                      if (selectedPoint == null) {
                        return;
                      }

                      final pinnedText = await LocationFormatterService.resolveAddress(
                        latitude: selectedPoint.latitude,
                        longitude: selectedPoint.longitude,
                      );
                      controller.text = pinnedText;
                      setDialogState(() {
                        pendingLocation = pinnedText;
                      });
                    },
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Pick From Map'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newLocation = pendingLocation.trim();
                    if (newLocation.isEmpty) {
                      return;
                    }
                    Navigator.of(context).pop();
                    await _updateLocation(newLocation);
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateLocation(String newLocation) async {
    final profile = _profile;
    if (profile == null) {
      return;
    }

    setState(() {
      _isUpdatingLocation = true;
    });

    try {
      await ApiService.updateProfileLocation(username: profile.username, location: newLocation);
      if (!mounted) {
        return;
      }

      setState(() {
        _profile = UserProfile(
          id: profile.id,
          fullname: profile.fullname,
          username: profile.username,
          phone: profile.phone,
          location: newLocation,
        );
      });

      await widget.onProfileUpdated();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location updated successfully.'), backgroundColor: Colors.green),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingLocation = false;
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
            title: 'PROFILE',
            subtitle: 'Your account details are loaded directly from the backend.',
          ),
          const SizedBox(height: 18),
          if (_error != null)
            StatusPanel(
              title: 'Unable to load profile',
              message: _error!,
              icon: Icons.person_off_outlined,
            )
          else if (_profile == null)
            const Center(child: CircularProgressIndicator(color: darkNavy))
          else
            FormPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: darkNavy,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(Icons.person, color: Colors.white, size: 38),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profile!.fullname,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: darkNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _profile!.username,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ProfileField(label: 'FULLNAME', value: _profile!.fullname),
                  const SizedBox(height: 12),
                  ProfileField(label: 'USERNAME', value: _profile!.username),
                  const SizedBox(height: 12),
                  ProfileField(label: 'PHONE', value: _profile!.phone),
                  const SizedBox(height: 12),
                  ProfileField(label: 'LOCATION', value: _profile!.location),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isUpdatingLocation ? null : _openEditLocationDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkNavy,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: Text(
                            _isUpdatingLocation ? 'UPDATING...' : 'EDIT PROFILE',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => showDeleteDialog(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE53935), width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: const Text(
                            'DELETE PROFILE',
                            style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
