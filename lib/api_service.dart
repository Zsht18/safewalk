import 'dart:convert';
import 'package:http/http.dart' as http;

// A simple model class to represent a report.
// The field names here should match the column names from your database table.
class Report {
  final int id;
  final double latitude;
  final double longitude;
  final String description;
  final DateTime timestamp;

  Report({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.timestamp,
  });

  // A factory constructor to create a Report from a JSON object.
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: int.parse(json['id'].toString()),
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      description: json['description'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}


class ApiService {
  // Replace this with the actual URL to your PHP script on Hostinger
  static const String _apiUrl = 'https://your-domain.com/api/get_reports.php';

  // Fetches the list of reports from your API.
  static Future<List<Report>> fetchReports() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the JSON.
        final List<dynamic> reportJson = json.decode(response.body);
        return reportJson.map((json) => Report.fromJson(json)).toList();
      } else {
        // If the server did not return a 200 OK response,
        // throw an exception.
        throw Exception('Failed to load reports from API');
      }
    } catch (e) {
      // Handle exceptions like no internet connection
      throw Exception('Failed to connect to the server: $e');
    }
  }
}
