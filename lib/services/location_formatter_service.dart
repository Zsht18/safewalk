import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../dashboard/dashboard_constants.dart';

class LocationFormatterService {
  const LocationFormatterService._();

  static Future<String> resolveAddress({
    required double latitude,
    required double longitude,
  }) async {
    final fallback = '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) {
        final reverse = await _resolveViaGeoapify(latitude: latitude, longitude: longitude);
        return reverse ?? fallback;
      }

      final formatted = _formatPlacemark(placemarks.first, fallback: fallback);
      if (formatted != fallback) {
        return formatted;
      }

      final reverse = await _resolveViaGeoapify(latitude: latitude, longitude: longitude);
      return reverse ?? fallback;

    } catch (_) {
      final reverse = await _resolveViaGeoapify(latitude: latitude, longitude: longitude);
      return reverse ?? fallback;
    }
  }

  static Future<String> resolveCurrentAddress() async {
    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    return resolveAddress(latitude: position.latitude, longitude: position.longitude);
  }

  static String _formatPlacemark(Placemark place, {required String fallback}) {
    final streetParts = [place.subThoroughfare, place.thoroughfare]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .map((value) => value.toString().trim())
        .toList();

    final parts = [
      streetParts.isEmpty ? null : streetParts.join(' '),
      place.subLocality, // barangay
      place.locality, // city
      place.administrativeArea, // province
      place.postalCode, // zip
    ]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .map((value) => value.toString().trim())
        .toList();

    if (parts.isEmpty) {
      return fallback;
    }

    return parts.join(', ');
  }

  static Future<String?> _resolveViaGeoapify({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.https(
        'api.geoapify.com',
        '/v1/geocode/reverse',
        {
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'format': 'json',
          'apiKey': geoapifyApiKey,
        },
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final results = decoded['results'];
      if (results is! List || results.isEmpty) {
        return null;
      }

      final first = results.first;
      if (first is! Map<String, dynamic>) {
        return null;
      }

      final parts = [
        first['street'],
        first['suburb'],
        first['city'],
        first['state'],
        first['postcode'],
      ]
          .where((value) => value != null && value.toString().trim().isNotEmpty)
          .map((value) => value.toString().trim())
          .toList();

      if (parts.isEmpty) {
        final formatted = first['formatted']?.toString().trim();
        if (formatted == null || formatted.isEmpty) {
          return null;
        }
        return formatted;
      }

      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }
}
