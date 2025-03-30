import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:garage/requestDetails.dart';

// Modern color scheme
const Color primaryColor = Color(0xFF00C897);
const Color secondaryColor = Color(0xFFF6830F);
const Color darkColor = Color(0xFF0A2647);
const Color lightColor = Color(0xFFF5F5F5);
const Color backgroundColor = Color(0xFFF9FAFC);

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({Key? key}) : super(key: key);

  @override
  _WorkerHomeScreenState createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  List<dynamic> assignedComplaints = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAssignedComplaints();
  }

  // Fetch assigned complaints from API
  Future<void> _fetchAssignedComplaints() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final token = await _secureStorage.read(key: 'jwt_token');
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/worker/requests/assigned'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          assignedComplaints = data;
          isLoading = false;
        });
      } else {
        final errorResponse = json.decode(response.body);
        setState(() {
          errorMessage =
              errorResponse['error'] ?? 'Failed to fetch assigned complaints.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred while fetching complaints: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _fetchAssignedComplaints,
        color: primaryColor,
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Assigned Complaints',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      backgroundColor: primaryColor,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
          onPressed: () => Scaffold.of(context).openDrawer(),
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: const NetworkImage(
                      'https://th.bing.com/th/id/OIP._sK_wxA0RSxfCqfWbGd9iQHaE8?w=291&h=194&c=7&r=0&o=5&dpr=1.5&pid=1.7',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder(
                    future: _secureStorage.read(key: 'workerName'),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data?.toString() ?? 'Worker Name',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder(
                    future: _secureStorage.read(key: 'workerEmail'),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data?.toString() ?? 'Worker Email',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit, color: primaryColor),
                  title: const Text('Edit Profile'),
                  onTap: () {
                    // Edit profile functionality
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: primaryColor),
                  title: const Text('Logout'),
                  onTap: () async {
                    await _secureStorage.deleteAll();
                    Navigator.pop(context);
                    // Redirect to login page
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 16),
            Text(
              "Loading complaints...",
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          errorMessage,
          style: GoogleFonts.poppins(
            color: Colors.red,
            fontSize: 16,
          ),
        ),
      );
    }

    if (assignedComplaints.isEmpty) {
      return Center(
        child: Text(
          "No complaints assigned yet.",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assignedComplaints.length,
      itemBuilder: (context, index) {
        final complaint = assignedComplaints[index];

        final requestDate =
            DateTime.parse(complaint['timestamps']['requestGeneration']);
        final formattedDate = DateFormat('MMM d, y').format(requestDate);
        final formattedTime = DateFormat('h:mm a').format(requestDate);

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RequestDetailsPage(
                    requestId: complaint['_id'],
                    userType: "worker",
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatusIndicator(complaint['status']),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              complaint['customerId']['username'],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: darkColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  formattedDate,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  formattedTime,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          complaint['address'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(String status) {
    IconData iconData;

    switch (status.toLowerCase()) {
      case 'pending':
        iconData = Icons.hourglass_empty_rounded;
        break;
      case 'in progress':
        iconData = Icons.build_rounded;
        break;
      case 'completed':
        iconData = Icons.check_circle_rounded;
        break;
      default:
        iconData = Icons.circle;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: _getStatusColor(status),
        size: 20,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
