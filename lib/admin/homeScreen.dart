import 'package:flutter/material.dart';
import 'package:garage/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:garage/requestDetails.dart';
import 'package:garage/admin/demon.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

// Modern color scheme
const Color primaryColor = Color(0xFF00C897);
const Color secondaryColor = Color(0xFFF6830F);
const Color darkColor = Color(0xFF0A2647);
const Color lightColor = Color(0xFFF5F5F5);
const Color backgroundColor = Color(0xFFF9FAFC);

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  List<dynamic> activeRequests = [];
  bool isLoading = true;
  String errorMessage = '';
  late AnimationController _refreshIconController;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _refreshIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Delay the call to _fetchActiveRequests until after the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchActiveRequests();
    });
  }

  @override
  void dispose() {
    _refreshIconController.dispose();
    super.dispose();
  }

  // Fetch active requests from the API
  Future<void> _fetchActiveRequests() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    _refreshIconController.repeat();

    try {
      String? token = await storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/garage/requests/ongoing'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> requests = json.decode(response.body);

        setState(() {
          activeRequests = requests;
          isLoading = false;
        });
      } else {
        setState(() {
          print(json.decode(response.body));
          errorMessage =
              'Failed to fetch active requests. Please check your internet connection or try again later.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage =
            'An error occurred while fetching requests. Please check your internet connection or try again later.';
        isLoading = false;
      });
    } finally {
      _refreshIconController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set system overlay style for status bar
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        color: primaryColor,
        onRefresh: _fetchActiveRequests, // Pull-to-refresh functionality
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'homeScreenFab', // Assign a unique heroTag
        onPressed: () {
          // Add new request functionality
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Create new request feature coming soon!'),
              backgroundColor: primaryColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
        backgroundColor: primaryColor,
        child: Icon(Icons.add, color: Colors.white),
        elevation: 4,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Active Requests',
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
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(15),
        child: Container(
          height: 15,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor.withOpacity(0.2),
                backgroundColor.withOpacity(0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final Color themeColor = const Color.fromRGBO(0, 200, 151, 1);

    return Drawer(
      elevation: 2,
      child: SafeArea(
        // Added SafeArea to handle system UI padding
        child: Column(
          children: [
            // Drawer Header
            FutureBuilder(
              future: Future.wait([
                storage.read(key: 'ownerName'),
                storage.read(key: 'phone'),
              ]),
              builder: (context, AsyncSnapshot<List<String?>> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ownerName = snapshot.data![0] ?? 'Owner Name';
                final phone = snapshot.data![1] ?? 'Phone Number';

                return Container(
                  height: 180, // Reduced height from 200 to 180
                  color: themeColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            radius: 35, // Reduced radius from 40 to 35
                            backgroundImage: NetworkImage(
                              'https://th.bing.com/th/id/OIP._sK_wxA0RSxfCqfWbGd9iQHaE8?w=291&h=194&c=7&r=0&o=5&dpr=1.5&pid=1.7',
                            ),
                          ),
                        ),
                        const SizedBox(
                            height: 12), // Reduced spacing from 16 to 12
                        Text(
                          ownerName,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18, // Reduced font size from 20 to 18
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                            height: 2), // Reduced spacing from 4 to 2
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.phone_outlined,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              phone,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // Drawer Menu Items
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap:
                      true, // Added shrinkWrap to avoid unnecessary scrolling
                  physics:
                      const AlwaysScrollableScrollPhysics(), // Ensure scrollability
                  children: [
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.dashboard_rounded,
                      title: 'Dashboard',
                      isActive: true,
                      themeColor: themeColor,
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.history_rounded,
                      title: 'Request History',
                      themeColor: themeColor,
                      onTap: () {
                        // Navigate to history page
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.notifications_rounded,
                      title: 'Notifications',
                      badge: '3',
                      themeColor: themeColor,
                      onTap: () {
                        // Navigate to notifications
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.map_rounded,
                      title: 'Garage Map',
                      themeColor: themeColor,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => GarageMapPage(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.edit_rounded,
                      title: 'Edit Profile',
                      themeColor: themeColor,
                      onTap: () {
                        // Navigate to edit profile
                        Navigator.pop(context);
                      },
                    ),
                    const Divider(
                        height: 1, thickness: 1, indent: 16, endIndent: 16),
                    const SizedBox(height: 8),
                    _buildDrawerItem(
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      themeColor: themeColor,
                      onTap: () {
                        // Navigate to settings
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      themeColor: themeColor,
                      onTap: () {
                        // Navigate to help
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      textColor: Colors.red.shade700,
                      iconColor: Colors.red.shade700,
                      themeColor: themeColor,
                      onTap: () {
                        // Show logout confirmation
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(
                              'Logout',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold),
                            ),
                            content: Text(
                              'Are you sure you want to logout?',
                              style: GoogleFonts.poppins(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(
                                      color: Colors.grey[700]),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final storage = FlutterSecureStorage();
                                  await storage
                                      .deleteAll(); // Delete all data from secure storage

                                  // Navigate back to the login screen or initial screen
                                  Navigator.pop(context); // Close the dialog
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            LandingPage()), // Redirect to login
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Logout',
                                  style: GoogleFonts.poppins(),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // App version info - now part of the ListView to ensure it scrolls if needed
            Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16), // Reduced vertical padding from 12 to 8
              color: Colors.grey[100],
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16,
                      color:
                          Colors.grey[600]), // Reduced icon size from 18 to 16
                  const SizedBox(width: 8),
                  Text(
                    'App Version 1.0.2',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color themeColor,
    String? badge,
    bool isActive = false,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? themeColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? (isActive ? themeColor : Colors.grey[700]),
          size: 24,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: textColor ?? (isActive ? themeColor : Colors.grey[800]),
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: onTap,
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
              "Loading requests...",
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
      return SingleChildScrollView(
        // Wrap in SingleChildScrollView
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: GoogleFonts.poppins(
                  color: Colors.red,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchActiveRequests,
                icon: Icon(Icons.refresh),
                label: Text(
                  "Try Again",
                  style: GoogleFonts.poppins(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (activeRequests.isEmpty) {
      return SingleChildScrollView(
        // Wrap in SingleChildScrollView
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                "No Active Requests",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "All caught up! Check back later for new requests",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _fetchActiveRequests,
                icon: Icon(Icons.refresh_rounded),
                label: Text(
                  "Refresh",
                  style: GoogleFonts.poppins(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeRequests.length,
      itemBuilder: (context, index) {
        final request = activeRequests[index];

        // Format date
        final requestDate =
            DateTime.parse(request['timestamps']['requestGeneration']);
        final formattedDate = DateFormat('MMM d, y').format(requestDate);
        final formattedTime = DateFormat('h:mm a').format(requestDate);

        return Card(
          elevation: 30,
          shadowColor: Colors.black.withOpacity(0.1),
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
                    requestId: request['_id'],
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
                      _buildStatusIndicator(request['status']),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    (request['customerId'] is Map &&
                                            request['customerId']['username'] !=
                                                null)
                                        ? request['customerId']['username']
                                        : 'Unknown Customer',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: darkColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(request['status'])
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _formatStatus(request['status']),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                      color: _getStatusColor(request['status']),
                                    ),
                                  ),
                                ),
                              ],
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
                          request['address'] ?? 'No location provided',
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Call Customer',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RequestDetailsPage(
                                requestId: request['_id'],
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'View Details',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
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

    switch (status) {
      case 'pending':
        iconData = Icons.hourglass_empty_rounded;
        break;
      case 'acknowledged':
        iconData = Icons.thumb_up_alt_rounded;
        break;
      case 'picked':
        iconData = Icons.directions_car_rounded;
        break;
      case 'inprogress':
        iconData = Icons.build_rounded;
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

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'acknowledged':
        return Colors.blue;
      case 'picked':
        return Colors.purple;
      case 'inprogress':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Helper method to format status text
  String _formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'acknowledged':
        return 'Acknowledged';
      case 'picked':
        return 'Picked Up';
      case 'inprogress':
        return 'In Progress';
      default:
        return status.substring(0, 1).toUpperCase() + status.substring(1);
    }
  }
}
