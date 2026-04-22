import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../api_service.dart';
import '../../services/location_formatter_service.dart';
import '../../services/philsms_service.dart';
import '../dashboard_constants.dart';
import '../dashboard_widgets.dart';

class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key, required this.profileFuture});

  final Future<UserProfile> profileFuture;

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  UserProfile? _profile;
  bool _isSending = false;
  String _currentLocationLabel = 'Press SOS to capture your current location.';

  // Ready-only config (replace with your real values when ready to go live).
  static const PhilSmsConfig _smsConfig = PhilSmsConfig(
    endpoint: 'https://dashboard.philsms.com/api/v3/',
    apiKey: '2635|19hTVHGV2p0gf9tjJMYqvk1U0ccc4f3ndYNpblNl3890acf0',
    senderId: 'PhilSMS',
  );

  final PhilSmsService _smsService = const PhilSmsService(_smsConfig);

  @override
  void initState() {
    super.initState();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
          ..repeat(reverse: true);
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant ContactsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileFuture != widget.profileFuture) {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = null;
      });
    }
  }

Future<void> _handleEmergency() async {
  final profile = _profile;
  if (profile == null) {
    _showSnackBar('Profile is still loading.', Colors.red);
    return;
  }

  if (profile.phone.isEmpty) {
    _showSnackBar('No phone number found in the profile.', Colors.red);
    return;
  }

  setState(() {
    _isSending = true;
  });

  try {
    // 1. Format the phone number to 639XXXXXXXXX
    String rawPhone = profile.phone.replaceAll(RegExp(r'\D'), ''); 
    if (rawPhone.startsWith('0')) {
      rawPhone = '63${rawPhone.substring(1)}';
    } else if (rawPhone.startsWith('9')) {
      rawPhone = '63$rawPhone';
    }

    final position = await _getCurrentPosition();
    final resolvedLocation = await LocationFormatterService.resolveAddress(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    // Fixed the Map Link string interpolation (added '$' before {position...})
    final mapsLink = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
    
    final message =
        'SOS ALERT from SafeWalk\nName: ${profile.fullname}\nLocation: $resolvedLocation\nMap: $mapsLink';

    setState(() {
      _currentLocationLabel = resolvedLocation;
    });

    // 2. Send using the formatted phone number
    await _smsService.send(
      PhilSmsMessage(recipient: rawPhone, message: message),
    );
    
    _showSnackBar('SOS message sent to $rawPhone.', Colors.green);
  } catch (error) {
    // Improved error display to see the API response clearly
    _showSnackBar(error.toString(), Colors.red);
  } finally {
    if (mounted) {
      setState(() {
        _isSending = false;
      });
    }
  }
}

  Future<Position> _getCurrentPosition() async {
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

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 0.96, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHeading(
                title: 'ARE YOU IN AN EMERGENCY?',
                subtitle: 'Tap SOS to capture your location and prepare an alert message.',
              ),
              const SizedBox(height: 18),
              FormPanel(
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: scale,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: scale.value,
                          child: child,
                        );
                      },
                      child: GestureDetector(
                        onTap: _isSending ? null : _handleEmergency,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE53935),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE53935).withValues(alpha: 0.28),
                                blurRadius: 28,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'SOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isSending ? 'SENDING...' : 'TAP TO ALERT',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Your current location',
                        style: TextStyle(
                          color: darkNavy,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1F8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _currentLocationLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isSending)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
      ],
    );
  }
}
