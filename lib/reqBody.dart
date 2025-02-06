import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RequestBodyPage extends StatefulWidget {
  final Map<String, dynamic> requestDetails;

  const RequestBodyPage({Key? key, required this.requestDetails})
      : super(key: key);

  @override
  _RequestBodyPageState createState() => _RequestBodyPageState();
}

class _RequestBodyPageState extends State<RequestBodyPage> {
  final TextEditingController pickUpTimeController = TextEditingController();
  final TextEditingController dropOffTimeController = TextEditingController();
  late String status;
  GoogleMapController? mapController;

  // Initialize marker position from requestDetails
  LatLng? markerPosition;

  @override
  void initState() {
    super.initState();
    status = widget.requestDetails['status'] ?? 'pending';
    final location = widget.requestDetails['location'];
    if (location != null) {
      markerPosition = LatLng(location['latitude'], location['longitude']);
    }
  }

  @override
  void dispose() {
    pickUpTimeController.dispose();
    dropOffTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(
      BuildContext context, TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        final DateTime combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        controller.text = combinedDateTime.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Details"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Request details
              Text(
                "User Name: ${widget.requestDetails['userName'] ?? 'N/A'}",
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text("Phone: ${widget.requestDetails['phone'] ?? 'N/A'}"),
              const SizedBox(height: 10),
              Text(
                  "Vehicle Number: ${widget.requestDetails['vehicleNumber'] ?? 'N/A'}"),
              Text("Vehicle Brand: ${widget.requestDetails['vehicleBrand'] ?? 'N/A'}"),
              Text("Vehicle Color: ${widget.requestDetails['vehicleColor'] ?? 'N/A'}"),
              const SizedBox(height: 10),
              Text("Description: ${widget.requestDetails['descr'] ?? 'N/A'}"),
              Text(
                "Current Status: ${widget.requestDetails['status'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 16, color: Colors.blue),
              ),

              const SizedBox(height: 20),

              // Google Map Widget
              const Text(
                "Location:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              markerPosition != null
                  ? SizedBox(
                height: 400,
                width: 500,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: markerPosition!,
                    zoom: 17,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId("requestLocation"),
                      position: markerPosition!,
                      infoWindow: const InfoWindow(
                        title: "Pick-Up Location",
                        snippet: "Customer's specified location",
                      ),
                    ),
                  },
                ),
              )
                  : const Text("Location not available"),
              const SizedBox(height: 10),

              // Editable fields
              const Text(
                "Pick-Up Time:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: pickUpTimeController,
                decoration: const InputDecoration(
                  hintText: "YYYY-MM-DD HH:MM",
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () => _selectDateTime(context, pickUpTimeController),
              ),
              const SizedBox(height: 20),
              const Text(
                "Drop-Off Time:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: dropOffTimeController,
                decoration: const InputDecoration(
                  hintText: "YYYY-MM-DD HH:MM",
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () => _selectDateTime(context, dropOffTimeController),
              ),
              const SizedBox(height: 20),

              // Status Dropdown
              const Text(
                "Update Status:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: status,
                items: <String>[
                  'pending',
                  'acknowledged',
                  'in progress',
                  'completed'
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newStatus) {
                  setState(() {
                    status = newStatus!;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Request updated successfully")),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text("Acknowledge"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Status updated successfully")),
                      );
                    },
                    child: const Text("Update Status"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
