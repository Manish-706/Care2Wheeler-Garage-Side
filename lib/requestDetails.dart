import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}

class RequestDetailsPage extends StatefulWidget {
  final String requestId;
  final String userType;

  const RequestDetailsPage({
    Key? key,
    required this.requestId,
    this.userType = "garage", // Default to "garage"
  }) : super(key: key);

  @override
  _RequestDetailsPageState createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final Color themeColor = const Color.fromRGBO(0, 200, 151, 1);

  final TextEditingController pickupTimeController = TextEditingController();
  final TextEditingController dropOffTimeController = TextEditingController();
  String? workerName;
  String? selectedWorker;
  String? selectedStatus;
  Map<String, dynamic>? requestDetails;
  List<Map<String, dynamic>> workerList = [];
  List<String> statusOptions = [
    'pending',
    'acknowledged',
    'picked',
    'inprogress',
    'completed',
    'rejected'
  ];
  bool isLoading = true;
  String errorMessage = '';

  // Define status colors for visual representation
  late final Map<String, Color> statusColors = {
    'pending': Colors.orange,
    'acknowledged': Colors.blue,
    'picked': Colors.purple,
    'inprogress': Colors.amber,
    'completed': themeColor,
    'rejected': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _fetchRequestDetails();
    _fetchWorkers();
  }

  // Fetch request details from API
  Future<void> _fetchRequestDetails() async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:3000/${widget.userType}/request/${widget.requestId}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          requestDetails = json.decode(response.body);
          selectedStatus = requestDetails?['status'];
          // Parse pickupTime and dropOffTime as DateTime before formatting
          if (requestDetails?['pickupTime'] != null) {
            final DateTime pickupTime =
                DateTime.parse(requestDetails!['pickupTime']);
            pickupTimeController.text =
                DateFormat('MMM dd, yyyy - hh:mm a').format(pickupTime);
          }

          if (requestDetails?['dropOffTime'] != null) {
            final DateTime dropOffTime =
                DateTime.parse(requestDetails!['dropOffTime']);
            dropOffTimeController.text =
                DateFormat('MMM dd, yyyy - hh:mm a').format(dropOffTime);
          }
          if (requestDetails?['workerId'] != null &&
              requestDetails?['workerId'] is Map) {
            workerName = requestDetails?['workerId']['workerName'];
          } else {
            workerName = "Select Worker";
          }
          isLoading = false;
        });
      } else {
        print("else block 404 : ${response.body}");
        setState(() {
          errorMessage = 'Failed to fetch request details. Please try again.';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Catch Error: $e');
      setState(() {
        errorMessage = 'An error occurred while fetching request details.';
        isLoading = false;
      });
    }
  }

  // Update request (status, pickup time, drop-off time)
  Future<void> _updateRequest() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Call the assign worker API if a worker is selected
      if (selectedWorker != null) {
        await _assignWorker();
      }

      // Prepare fields for the update request API
      final Map<String, dynamic> updateFields = {};

      if (selectedStatus != null) updateFields['status'] = selectedStatus;

      if (pickupTimeController.text.isNotEmpty) {
        // Convert pickupTime to ISO 8601 format
        final DateTime? pickupTime = DateFormat('MMM dd, yyyy - hh:mm a')
            .parse(pickupTimeController.text);
        updateFields['pickupTime'] = pickupTime?.toIso8601String();
      }

      if (dropOffTimeController.text.isNotEmpty) {
        // Convert dropOffTime to ISO 8601 format
        final DateTime? dropOffTime = DateFormat('MMM dd, yyyy - hh:mm a')
            .parse(dropOffTimeController.text);
        updateFields['dropOffTime'] = dropOffTime?.toIso8601String();
      }

      if (updateFields.isNotEmpty) {
        final response = await http.patch(
          Uri.parse(
              'http://10.0.2.2:3000/${widget.userType}/request/${widget.requestId}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${await storage.read(key: 'jwt_token')}',
          },
          body: json.encode(updateFields),
        );

        if (response.statusCode == 200) {
          _showSnackBar('Request updated successfully!', themeColor);
          _fetchRequestDetails(); // Refresh request details
        } else {
          print("else block : ${response.body}");
          throw Exception('Failed to update request.');
        }
      } else {
        _showSnackBar('No changes to update.', Colors.orange);
      }
    } catch (e) {
      print("catch block : ${e.toString()}");
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _assignWorker() async {
    if (selectedWorker == null) {
      _showSnackBar('Please select a worker to assign.', Colors.orange);
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse(
            'http://10.0.2.2:3000/${widget.userType}/request/${widget.requestId}/assign'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await storage.read(key: 'jwt_token')}',
        },
        body: json.encode({'workerId': selectedWorker}),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Worker assigned successfully!', themeColor);
      } else {
        print(response.body);
        throw Exception('Failed to assign worker.');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).viewInsets.bottom + 80, // Adjusted margin
          left: 20,
          right: 20,
        ),
      ),
    );
  }

  // Fetch workers from API
  Future<void> _fetchWorkers() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/${widget.userType}/workers'),
        headers: {
          'Authorization': 'Bearer ${await storage.read(key: 'jwt_token')}'
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> workersData = json.decode(response.body);

        setState(() {
          workerList = workersData
              .map((worker) =>
                  {'id': worker['_id'], 'name': worker['workerName']})
              .toList();
        });
      } else {
        print("else block : ${response.body}");
        setState(() {
          errorMessage = 'Failed to fetch workers. Please try again.';
        });
      }
    } catch (e) {
      print('Error fetching workers: $e');
      setState(() {
        errorMessage = 'An error occurred while fetching workers.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: themeColor,
        title: const Text(
          'Request Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          if (!isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: ElevatedButton.icon(
                onPressed: _updateRequest,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: themeColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          _buildPageContent(),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  color: themeColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: themeColor));
    } else if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: TextStyle(color: Colors.red[700], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = '';
                });
                _fetchRequestDetails();
                _fetchWorkers();
              },
              child: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (requestDetails == null) {
      return const Center(
        child: Text(
          'No details available.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      );
    } else {
      return _buildDetailsContent();
    }
  }

  Widget _buildDetailsContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildStatusHeader(),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCustomerDetailsCard(),
                const SizedBox(height: 16),
                _buildTimesSection(),
                const SizedBox(height: 16),
                _buildWorkerAssignmentSection(),
                const SizedBox(height: 16),
                _buildStatusUpdateSection(),
                const SizedBox(height: 16),
                _buildQrCodeSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    final statusColor = statusColors[selectedStatus] ?? Colors.grey;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: themeColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selectedStatus == 'completed'
                          ? Icons.check_circle
                          : selectedStatus == 'rejected'
                              ? Icons.cancel
                              : Icons.pending,
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (selectedStatus ?? 'unknown').capitalize(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'ID: ${widget.requestId.substring(0, 8)}...',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (requestDetails?['customerId'] != null)
            Text(
              'Customer: ${requestDetails?['customerId'] is Map && requestDetails?['customerId']?['username'] != null ? requestDetails?['customerId']?['username'] : (requestDetails?['customerId'] ?? 'Unknown Customer')}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (requestDetails?['phone'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '${requestDetails?['phone']}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerDetailsCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: themeColor),
                const SizedBox(width: 8),
                const Text(
                  'Service Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: Colors.grey[300]),
            _buildDetailRow(
              icon: Icons.location_on_outlined,
              title: 'Pickup Location',
              value: '${requestDetails?['address'] ?? 'Not specified'}',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.build_outlined,
              title: 'Issues',
              value: '${requestDetails?['issues'] ?? 'None reported'}',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.miscellaneous_services_outlined,
              title: 'Services',
              value: '${requestDetails?['services'] ?? 'None specified'}',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              icon: Icons.miscellaneous_services_outlined,
              title: 'Description',
              value: '${requestDetails?['description'] ?? 'None specified'}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: themeColor.withOpacity(0.7), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimesSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: themeColor),
                const SizedBox(width: 8),
                const Text(
                  'Schedule',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: Colors.grey[300]),
            _buildTimeField(
              label: 'Pickup Time',
              controller: pickupTimeController,
              onTap: () => _selectDateTime(context, true),
            ),
            const SizedBox(height: 16),
            _buildTimeField(
              label: 'Drop-off Time',
              controller: dropOffTimeController,
              onTap: () => _selectDateTime(context, false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.text.isEmpty ? 'Select time' : controller.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: controller.text.isEmpty
                          ? Colors.grey
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_today, color: themeColor.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context, bool isPickup) async {
    // Step 1: Select Date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: themeColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      // Step 2: Select Time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: themeColor,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        // Combine date and time
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Format the DateTime object as a string - using a better format
        final formattedDateTime =
            DateFormat('MMM dd, yyyy - hh:mm a').format(selectedDateTime);

        // Update the appropriate controller
        if (isPickup) {
          setState(() {
            pickupTimeController.text = formattedDateTime;
          });
        } else {
          setState(() {
            dropOffTimeController.text = formattedDateTime;
          });
        }
      }
    }
  }

  Widget _buildWorkerAssignmentSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outlined, color: themeColor),
                const SizedBox(width: 8),
                const Text(
                  'Assign Worker',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: Colors.grey[300]),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: workerName ?? 'Select Worker',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: themeColor),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              icon: Icon(Icons.arrow_drop_down_circle_outlined,
                  color: themeColor),
              items: workerList.map((worker) {
                return DropdownMenuItem<String>(
                  value: worker['id'],
                  child: Text(worker['name'] ?? 'No Worker'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedWorker = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusUpdateSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.update, color: themeColor),
                const SizedBox(width: 8),
                const Text(
                  'Update Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: Colors.grey[300]),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Current Status',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: themeColor),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              icon: Icon(Icons.arrow_drop_down_circle_outlined,
                  color: themeColor),
              value: selectedStatus,
              items: statusOptions.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColors[status] ?? Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(status.capitalize()),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCodeSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.qr_code, color: themeColor),
                const SizedBox(width: 8),
                const Text(
                  'QR Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: Colors.grey[300]),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: themeColor.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: requestDetails?['qrCode'] ?? 'No Data',
                      version: QrVersions.auto,
                      size: 180.0,
                      gapless: true,
                      backgroundColor: Colors.white,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: themeColor,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Request ID: ${widget.requestId.substring(0, 10)}...',
                        style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
