import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

// Modern color scheme
const Color primaryColor = Color(0xFF00C897);
const Color secondaryColor = Color(0xFFF6830F);
const Color darkColor = Color(0xFF0A2647);
const Color lightColor = Color(0xFFF5F5F5);

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({Key? key}) : super(key: key);

  @override
  _RecordsScreenState createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  List<dynamic> completedRequests = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCompletedRequests();
  }

  // Fetch completed requests from the API
  Future<void> _fetchCompletedRequests() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      String? token = await storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/garage/requests/completed'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          completedRequests = data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Failed to fetch completed requests. Please try again later.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred while fetching completed requests.';
        isLoading = false;
      });
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "completed":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          errorMessage,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    if (completedRequests.isEmpty) {
      return const Center(
        child: Text(
          "No completed requests found",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      itemCount: completedRequests.length,
      itemBuilder: (context, index) {
        final request = completedRequests[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        (request['customerId'] is Map &&
                                request['customerId']['username'] != null)
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
                          vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color:
                            getStatusColor(request['status']).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        request['status'].toUpperCase(),
                        style: TextStyle(
                          color: getStatusColor(request['status']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Address: ${request['address'] ?? 'N/A'}",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Date: ${request['timestamps']?['requestGeneration'] ?? 'N/A'}",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Requests'),
        centerTitle: true,
        backgroundColor: primaryColor,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCompletedRequests, // Trigger refresh on pull-down
        color: primaryColor,
        child: _buildBody(),
      ),
    );
  }
}
