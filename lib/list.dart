import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'reqBody.dart'; // Import the detailed page

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<dynamic> userRequests = [];
  bool isLoading = true;

  // Fetch user data from API
  Future<void> fetchUserRequests() async {
    // const apiUrl =
    //     "http://localhost:3000/garage/reqList"; // Replace with your API URL
    final apiUrl = "http://10.0.2.2:3000/garage/reqList";

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        setState(() {
          userRequests = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception(
            "Failed to load data. Status code: ${response.statusCode}");
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching user requests: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserRequests(); // Fetch data on screen load
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Garage User Requests"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: userRequests.length,
              itemBuilder: (context, index) {
                final user = userRequests[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.blue),
                    title: Text(
                      user["userName"] ?? "Unknown",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Phone: ${user["phone"]}"),
                    trailing: _buildStatusChip(user["status"] ?? "Unknown"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RequestBodyPage(requestDetails: user),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  // Helper widget to display request status as a colored chip
  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case "pending":
        chipColor = Colors.orange;
        break;
      case "in progress":
        chipColor = Colors.blue;
        break;
      case "completed":
        chipColor = Colors.green;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: chipColor,
    );
  }
}
