import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

const Color darkNavy = Color(0xFF043464);
const Color activeTabColor = Color(0xFF0B4F86);
const Color surfaceColor = Color(0xFFF3F8FD);
const LatLng defaultMapCenter = LatLng(10.6765, 122.9509);

const String geoapifyApiKey = '639d69b792674286a0731cb4bcef5bd0';
const String geoapifyTileUrl =
    'https://maps.geoapify.com/v1/tile/osm-bright/{z}/{x}/{y}.png?apiKey=$geoapifyApiKey';
