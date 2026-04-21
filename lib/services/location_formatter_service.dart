import 'package:geocoding/geocoding.dart';

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
        return fallback;
      }

      final place = placemarks.first;
      final parts = [
        place.street,
        place.subLocality, // barangay
        place.locality, // city
        place.administrativeArea, // province
        place.postalCode, // zip
      ]
          .where((value) => value != null && value.toString().trim().isNotEmpty)
          .map((value) => value.toString())
          .toList();

      if (parts.isEmpty) {
        return fallback;
      }

      return parts.join(', ');
    } catch (_) {
      return fallback;
    }
  }
}
