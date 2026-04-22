import 'package:flutter/material.dart';

import 'api_service.dart';
import 'dashboard/dashboard_constants.dart';
import 'dashboard/tabs/contacts_tab.dart';
import 'dashboard/tabs/create_report_tab.dart';
import 'dashboard/tabs/profile_tab.dart';
import 'dashboard/tabs/reports_map_tab.dart';

class MapDashboardScreen extends StatefulWidget {
  const MapDashboardScreen({
    super.key,
    required this.username,
    required this.onLogout,
  });

  final String username;
  final Future<void> Function() onLogout;

  @override
  State<MapDashboardScreen> createState() => _MapDashboardScreenState();
}

class _MapDashboardScreenState extends State<MapDashboardScreen> {
  int _selectedIndex = 0;
  late Future<List<Report>> _reportsFuture;
  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = ApiService.fetchReports();
    _profileFuture = ApiService.fetchProfileByUsername(widget.username);
  }

  Future<void> _reloadReports() async {
    setState(() {
      _reportsFuture = ApiService.fetchReports();
    });
  }

  Future<void> _reloadProfile() async {
    setState(() {
      _profileFuture = ApiService.fetchProfileByUsername(widget.username);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: darkNavy,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SafeWalk',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
            Text(
              widget.username,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await widget.onLogout();
            },
            child: const Text(
              'LOG OUT',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ReportsMapTab(
            reportsFuture: _reportsFuture,
            onRetry: _reloadReports,
          ),
          CreateReportTab(
            profileFuture: _profileFuture,
            onReportSubmitted: _reloadReports,
          ),
          ContactsTab(profileFuture: _profileFuture),
          ProfileTab(
            profileFuture: _profileFuture,
            onProfileUpdated: _reloadProfile,
          ),
        ],
      ),
      bottomNavigationBar: DashboardNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class DashboardNavBar extends StatelessWidget {
  const DashboardNavBar({super.key, required this.selectedIndex, required this.onItemSelected});

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(color: darkNavy),
      child: Row(
        children: [
          DashboardNavItem(label: 'MAP', isActive: selectedIndex == 0, onTap: () => onItemSelected(0)),
          DashboardNavItem(label: 'REPORT', isActive: selectedIndex == 1, onTap: () => onItemSelected(1)),
          DashboardNavItem(label: 'CONTACTS', isActive: selectedIndex == 2, onTap: () => onItemSelected(2)),
          DashboardNavItem(label: 'PROFILE', isActive: selectedIndex == 3, onTap: () => onItemSelected(3)),
        ],
      ),
    );
  }
}

class DashboardNavItem extends StatelessWidget {
  const DashboardNavItem({super.key, required this.label, required this.isActive, required this.onTap});

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: isActive ? activeTabColor : Colors.transparent,
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}
