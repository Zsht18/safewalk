import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../api_service.dart';
import '../dashboard_constants.dart';
import '../dashboard_widgets.dart';

class ReportsMapTab extends StatefulWidget {
  const ReportsMapTab({super.key, required this.reportsFuture});

  final Future<List<Report>> reportsFuture;

  @override
  State<ReportsMapTab> createState() => _ReportsMapTabState();
}

class _ReportsMapTabState extends State<ReportsMapTab> {
  final Map<String, LatLng> _locationCache = {};

  Future<LatLng?> _resolvePointForReport(Report report) async {
    if (report.latitude != null && report.longitude != null) {
      return LatLng(report.latitude!, report.longitude!);
    }

    final locationText = report.location.trim();
    if (locationText.isEmpty) {
      return null;
    }

    if (_locationCache.containsKey(locationText)) {
      return _locationCache[locationText];
    }

    try {
      final uri = Uri.https(
        'api.geoapify.com',
        '/v1/geocode/search',
        {
          'text': locationText,
          'limit': '1',
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

      final features = decoded['features'];
      if (features is! List || features.isEmpty) {
        return null;
      }

      final first = features.first;
      if (first is! Map<String, dynamic>) {
        return null;
      }

      final geometry = first['geometry'];
      if (geometry is! Map<String, dynamic>) {
        return null;
      }

      final coordinates = geometry['coordinates'];
      if (coordinates is! List || coordinates.length < 2) {
        return null;
      }

      final lon = double.tryParse(coordinates[0].toString());
      final lat = double.tryParse(coordinates[1].toString());
      if (lat == null || lon == null) {
        return null;
      }

      final point = LatLng(lat, lon);
      _locationCache[locationText] = point;
      return point;
    } catch (_) {
      return null;
    }
  }

  Future<List<_ResolvedReportPoint>> _resolveReportPoints(List<Report> reports) async {
    final resolved = <_ResolvedReportPoint>[];
    for (final report in reports) {
      final point = await _resolvePointForReport(report);
      if (point != null) {
        resolved.add(_ResolvedReportPoint(report: report, point: point));
      }
    }
    return resolved;
  }

  LatLng _fallbackCenter(List<Report> reports) {
    final validReports =
        reports.where((report) => report.latitude != null && report.longitude != null).toList();
    if (validReports.isEmpty) {
      return defaultMapCenter;
    }

    final averageLat =
        validReports.fold<double>(0, (sum, report) => sum + report.latitude!) / validReports.length;
    final averageLng =
        validReports.fold<double>(0, (sum, report) => sum + report.longitude!) / validReports.length;
    return LatLng(averageLat, averageLng);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Report>>(
      future: widget.reportsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: darkNavy));
        }

        if (snapshot.hasError) {
          return StatusPanel(
            title: 'Unable to load reports',
            message: snapshot.error.toString(),
            icon: Icons.error_outline,
          );
        }

        final reports = snapshot.data ?? const <Report>[];

        return FutureBuilder<List<_ResolvedReportPoint>>(
          future: _resolveReportPoints(reports),
          builder: (context, markerSnapshot) {
            if (markerSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: darkNavy));
            }

            final resolvedPoints = markerSnapshot.data ?? const <_ResolvedReportPoint>[];
            final center = resolvedPoints.isNotEmpty
                ? _averageCenter(resolvedPoints)
                : _fallbackCenter(reports);

            final markers = resolvedPoints
                .map(
                  (entry) => Marker(
                    point: entry.point,
                    width: 48,
                    height: 48,
                    child: GestureDetector(
                      onTap: () => showReportSheet(context, entry.report),
                      child: const Icon(
                        Icons.location_pin,
                        size: 42,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                )
                .toList();

            return Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 12.7,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: geoapifyTileUrl,
                      userAgentPackageName: 'com.safewalk.app',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 16,
                  child: _MapOverlayCard(
                    reportCount: reports.length,
                    markerCount: markers.length,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  LatLng _averageCenter(List<_ResolvedReportPoint> points) {
    final averageLat = points.fold<double>(0, (sum, entry) => sum + entry.point.latitude) / points.length;
    final averageLng = points.fold<double>(0, (sum, entry) => sum + entry.point.longitude) / points.length;
    return LatLng(averageLat, averageLng);
  }
}

class _MapOverlayCard extends StatelessWidget {
  const _MapOverlayCard({required this.reportCount, required this.markerCount});

  final int reportCount;
  final int markerCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: darkNavy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active reports on map',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: darkNavy,
                  ),
                ),
                Text(
                  '$reportCount report${reportCount == 1 ? '' : 's'} loaded • $markerCount marker${markerCount == 1 ? '' : 's'} on map',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolvedReportPoint {
  const _ResolvedReportPoint({required this.report, required this.point});

  final Report report;
  final LatLng point;
}
