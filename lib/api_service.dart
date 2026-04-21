import 'dart:convert';
import 'package:http/http.dart' as http;

class UserProfile {
  final int id;
  final String fullname;
  final String username;
  final String phone;
  final String location;

  const UserProfile({
    required this.id,
    required this.fullname,
    required this.username,
    required this.phone,
    required this.location,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: int.tryParse(json['id'].toString()) ?? 0,
      fullname: json['fullname']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
    );
  }
}

class Report {
  final int id;
  final String fullname;
  final String location;
  final String description;
  final String status;
  final double? latitude;
  final double? longitude;
  final DateTime? timestamp;

  const Report({
    required this.id,
    required this.fullname,
    required this.location,
    required this.description,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: int.tryParse(json['id'].toString()) ?? 0,
      fullname: json['fullname']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      description: json['report']?.toString() ?? json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      latitude: json['latitude'] == null ? null : double.tryParse(json['latitude'].toString()),
      longitude: json['longitude'] == null ? null : double.tryParse(json['longitude'].toString()),
      timestamp: json['timestamp'] == null ? null : DateTime.tryParse(json['timestamp'].toString()),
    );
  }
}

class ApiService {
  static const String _apiHost = 'safewalk.uslsbsit.com';

  static Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    return Uri.https(_apiHost, path, queryParameters);
  }

  static Future<UserProfile> fetchProfileByUsername(String username) async {
    final response = await http.get(
      _buildUri('/get_profile.php', {'username': username}),
    ).timeout(const Duration(seconds: 15));

    final dynamic decoded = jsonDecode(response.body);
    if (response.statusCode == 200 && decoded is Map<String, dynamic> && decoded['status'] == 'success') {
      return UserProfile.fromJson(decoded['data'] as Map<String, dynamic>);
    }

    final message = decoded is Map<String, dynamic> ? decoded['message']?.toString() : response.body;
    throw Exception(message ?? 'Unable to load profile.');
  }

  static Future<List<Report>> fetchReports() async {
    final response = await http.get(
      _buildUri('/get_reports.php'),
    ).timeout(const Duration(seconds: 15));

    final dynamic decoded = jsonDecode(response.body);
    if (response.statusCode == 200 && decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Report.fromJson)
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      throw Exception(decoded['message']?.toString() ?? 'Unable to load reports.');
    }

    throw Exception('Unable to load reports.');
  }

  static Future<Map<String, dynamic>> submitReport({
    required String fullname,
    required String location,
    required String report,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      _buildUri('/create_report.php'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullname': fullname,
        'location': location,
        'report': report,
        'latitude': latitude,
        'longitude': longitude,
      }),
    ).timeout(const Duration(seconds: 15));

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      if (response.statusCode == 200 && decoded['status'] == 'success') {
        return decoded;
      }
      throw Exception(decoded['message']?.toString() ?? 'Unable to submit report.');
    }

    throw Exception('Unable to submit report.');
  }

  static Future<void> updateProfileLocation({
    required String username,
    required String location,
  }) async {
    final response = await http.post(
      _buildUri('/update_profile.php'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'location': location,
      }),
    ).timeout(const Duration(seconds: 15));

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      if (response.statusCode == 200 && decoded['status'] == 'success') {
        return;
      }
      throw Exception(decoded['message']?.toString() ?? 'Unable to update profile location.');
    }

    throw Exception('Unable to update profile location.');
  }
}
