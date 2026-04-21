import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'main.dart';

class MapDashboardScreen extends StatefulWidget {
  const MapDashboardScreen({super.key});

  @override
  State<MapDashboardScreen> createState() => _MapDashboardScreenState();
}

class _MapDashboardScreenState extends State<MapDashboardScreen> {
  final Color darkNavyColor = const Color(0xFF043464);
  final Color activeTabColor = const Color(0xFF064B85); // Slightly lighter blue for the active "MAP" tab

  // Simulating the data fetched from your PHP database script ($db->getTodaysReports())
  // Currently centered around Bacolod based on your image
  final List<LatLng> reportLocations = [
    const LatLng(10.6765, 122.9509), // Bacolod Center
    const LatLng(10.6850, 122.9600), // Estefania area
    const LatLng(10.6550, 122.9350), // Pahanocoy area
    const LatLng(10.7300, 122.9700), // Talisay area
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ==========================================
      // TOP APP BAR
      // ==========================================
      appBar: AppBar(
        backgroundColor: darkNavyColor,
        automaticallyImplyLeading: false, // Hides the default back button
        title: const Text(
          'SafeWalk',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1.0),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                  child: const Text(
                    'LOG OUT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),

      // ==========================================
      // MAP BODY (Replacing Leaflet.js)
      // ==========================================
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(10.6765, 122.9509), // Initial map center (Bacolod)
          initialZoom: 12.5,
        ),
        children: [
          // OpenStreetMap Tile Layer
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.safewalk.app', // Good practice for OSM
          ),
          // Markers Layer (Simulating the locations array from PHP)
          MarkerLayer(
            markers: reportLocations.map((location) {
              return Marker(
                point: location,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),

      // ==========================================
      // BOTTOM NAVIGATION BAR
      // ==========================================
      bottomNavigationBar: Container(
        height: 50,
        color: darkNavyColor,
        child: Row(
          children: [
            _buildNavItem('MAP', isActive: true),
            _buildNavItem('REPORT', isActive: false),
            _buildNavItem('CONTACTS', isActive: false),
            _buildNavItem('PROFILE', isActive: false),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the bottom nav tabs matching your design
  Widget _buildNavItem(String title, {required bool isActive}) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // TODO: Add navigation logic for the other tabs
        },
        child: Container(
          color: isActive ? activeTabColor : Colors.transparent,
          alignment: Alignment.center,
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}