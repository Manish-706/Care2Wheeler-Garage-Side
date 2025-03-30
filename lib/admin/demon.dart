import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui' as ui;

class GarageMapPage extends StatefulWidget {
  @override
  _GarageMapPageState createState() => _GarageMapPageState();
}

class _GarageMapPageState extends State<GarageMapPage> {
  final List<Map<String, dynamic>> garages = [
    {
      'id': '1',
      'name': 'Speedy Garage',
      'owner': 'John Doe',
      'phone': '+1234567890',
      'location': '123 Main Street',
      'latitude': 37.7749,
      'longitude': -122.4194,
      'icon': Icons.garage_rounded, // Built-in icon
    },
    {
      'id': '2',
      'name': 'Reliable Repairs',
      'owner': 'Jane Smith',
      'phone': '+0987654321',
      'location': '456 Elm Street',
      'latitude': 37.7849,
      'longitude': -122.4094,
      'icon': Icons.build_circle_sharp, // Built-in icon
    },
    {
      'id': '3',
      'name': 'BikeFix Pro',
      'owner': 'Mark Taylor',
      'phone': '+1122334455',
      'location': '789 Pine Street',
      'latitude': 37.7649,
      'longitude': -122.4294,
      'icon': Icons.two_wheeler, // Built-in icon
    },
  ];

  late GoogleMapController mapController;
  final LatLng initialLocation = LatLng(37.7749, -122.4194);
  final Map<MarkerId, BitmapDescriptor> customMarkers = {};

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
  }

  // Load custom marker icons
  void _loadCustomMarkers() async {
    for (var garage in garages) {
      final icon = await _getCustomMarkerIcon(
          garage['icon'], const Color.fromARGB(255, 255, 6, 6));
      customMarkers[MarkerId(garage['id'])] = icon;
    }
    setState(() {});
  }

  // Convert IconData to BitmapDescriptor for custom markers
  Future<BitmapDescriptor> _getCustomMarkerIcon(
      IconData icon, Color color) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw the icon
    final iconStr = String.fromCharCode(icon.codePoint);
    textPainter.text = TextSpan(
      text: iconStr,
      style: TextStyle(
        fontSize: 85.0, // Increase this value to make the icon larger
        fontFamily: icon.fontFamily,
        color: color,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);

    // Convert to image
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(
        64, 64); // Increase this value to match the font size
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Garage',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialLocation,
          zoom: 12,
        ),
        onMapCreated: (controller) {
          mapController = controller;
        },
        markers: garages.map((garage) {
          return Marker(
            markerId: MarkerId(garage['id']),
            position: LatLng(garage['latitude'], garage['longitude']),
            icon: customMarkers[MarkerId(garage['id'])] ??
                BitmapDescriptor.defaultMarker,
            onTap: () {
              showGarageDialog(context, garage);
            },
          );
        }).toSet(),
      ),
    );
  }

  void showGarageDialog(BuildContext context, Map<String, dynamic> garage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            garage['name'],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(Icons.person, 'Owner: ${garage['owner']}'),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.phone, 'Phone: ${garage['phone']}'),
              const SizedBox(height: 8),
              _buildInfoRow(
                  Icons.location_on, 'Location: ${garage['location']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('You selected ${garage['name']}'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.blueAccent,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Select',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
