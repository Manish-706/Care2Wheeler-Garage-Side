import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WorkerDetailsPage extends StatefulWidget {
  final String workerId;

  const WorkerDetailsPage({Key? key, required this.workerId}) : super(key: key);

  @override
  _WorkerDetailsPageState createState() => _WorkerDetailsPageState();
}

class _WorkerDetailsPageState extends State<WorkerDetailsPage> {
  Map<String, dynamic>? worker;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _aadharController = TextEditingController();

  bool _isUpdated = false; // Track if any field is updated
  bool isLoading = true; // Track loading state
  String errorMessage = ''; // Store error messages

  @override
  void initState() {
    super.initState();
    _fetchWorkerDetails();
  }

  @override
  void dispose() {
    // Dispose controllers
    _nameController.dispose();
    _phoneController.dispose();
    _aadharController.dispose();
    super.dispose();
  }

  // Fetch worker details from API
  Future<void> _fetchWorkerDetails() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/garage/worker/${widget.workerId}'),
      );

      if (response.statusCode == 200) {
        final workerData = json.decode(response.body);
        setState(() {
          worker = workerData;
          _nameController.text = workerData['name'] ?? '';
          _phoneController.text = workerData['phone'] ?? '';
          _aadharController.text = workerData['aadhaarNumber'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch worker details. Please try again.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred while fetching worker details.';
        isLoading = false;
      });
    }
  }

  // Save changes to API
  Future<void> _saveChanges() async {
    if (worker == null) return;

    final updatedDetails = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'aadhaarNumber': _aadharController.text,
    };

    try {
      final response = await http.patch(
        Uri.parse('http://10.0.2.2:3000/garage/worker/${widget.workerId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updatedDetails),
      );

      if (response.statusCode == 200) {
        setState(() {
          worker = json.decode(response.body)['updatedWorker'];
          _isUpdated = false; // Reset update flag
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Worker details updated successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to update worker details: ${json.decode(response.body)['error']}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while updating worker details.'),
        ),
      );
    }
  }

  // Check if any field is updated
  void _checkForUpdates() {
    setState(() {
      _isUpdated = _nameController.text != worker?['name'] ||
          _phoneController.text != worker?['phone'] ||
          _aadharController.text != worker?['aadhaarNumber'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Worker Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        actions: [
          if (_isUpdated)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
              : worker == null
                  ? const Center(child: Text('Worker details not available.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Worker Picture
                          Center(
                            child: CircleAvatar(
                              radius: 60,
                              backgroundImage:
                                  NetworkImage(worker?['profilePhoto'] ?? ''),
                              onBackgroundImageError: (error, stackTrace) =>
                                  const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Worker Name
                          _buildEditableSection(
                            label: 'Worker Name',
                            controller: _nameController,
                            onChanged: _checkForUpdates,
                          ),
                          const SizedBox(height: 20),
                          // Phone Number
                          _buildEditableSection(
                            label: 'Phone Number',
                            controller: _phoneController,
                            onChanged: _checkForUpdates,
                          ),
                          const SizedBox(height: 20),
                          // Aadhar Number
                          _buildEditableSection(
                            label: 'Aadhar Number',
                            controller: _aadharController,
                            onChanged: _checkForUpdates,
                          ),
                          const SizedBox(height: 20),
                          // Garage (Non-editable)
                          _buildNonEditableSection(
                            label: 'Garage',
                            value: worker?['garage'] ?? 'Not Available',
                          ),
                        ],
                      ),
                    ),
    );
  }

  // Build an editable section
  Widget _buildEditableSection({
    required String label,
    required TextEditingController controller,
    required VoidCallback onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (value) => onChanged(),
        ),
      ],
    );
  }

  // Build a non-editable section
  Widget _buildNonEditableSection({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
