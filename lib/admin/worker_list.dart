import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({Key? key}) : super(key: key);

  @override
  _WorkersScreenState createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  List<Map<String, dynamic>> workers = [];
  bool isLoading = true;
  String errorMessage = '';

  // Define the theme color
  final Color themeColor = const Color.fromRGBO(0, 200, 151, 1);

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
  }

  // Fetch workers from the API
  Future<void> _fetchWorkers() async {
    final url = Uri.parse('http://10.0.2.2:3000/garage/workers');
    try {
      String? token =
          await storage.read(key: 'jwt_token'); // Retrieve JWT token
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> workersData = json.decode(response.body);
        setState(() {
          workers = workersData.map((worker) {
            return {
              'profilePhoto':
                  worker['picture'] ?? '', // Use picture field from backend
              'username': worker['workerName'] ??
                  '', // Use workerName field from backend
              'phoneNumber': worker['phone'] ?? '',
              'aadhaarNumber': worker['aadharNumber'] ?? '',
              'currentLocation': worker['currentLocation'] ?? 'Not Available',
              'id': worker['_id'] ?? '', // Store worker ID for CRUD operations
            };
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch workers. Please try again.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred while fetching workers.';
        isLoading = false;
      });
    }
  }

  // Add worker to the API
  Future<void> _addWorker(Map<String, dynamic> workerData) async {
    final url = Uri.parse('http://10.0.2.2:3000/garage/worker');
    try {
      String? token =
          await storage.read(key: 'jwt_token'); // Retrieve JWT token

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode(workerData),
      );

      if (response.statusCode == 201) {
        // Successfully added worker
        _fetchWorkers(); // Refresh the worker list
        return;
      } else {
        // Handle error
        print("this is else : $response.body");
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to add worker');
      }
    } catch (e) {
      print("This is catch block : $e");
      throw Exception('An error occurred: $e');
    }
  }

  // Update worker details
  Future<void> _updateWorker(
      String workerId, Map<String, dynamic> workerData) async {
    final url = Uri.parse('http://10.0.2.2:3000/garage/worker/$workerId');
    try {
      String? token = await storage.read(key: 'jwt_token');

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: json.encode(workerData),
      );

      if (response.statusCode == 200) {
        // Successfully updated worker
        _fetchWorkers(); // Refresh the worker list
        return;
      } else {
        // Handle error
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update worker');
      }
    } catch (e) {
      print("Update worker error: $e");
      throw Exception('An error occurred: $e');
    }
  }

  // Show add/edit worker form
  void _showWorkerForm({Map<String, dynamic>? workerData}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WorkerForm(
        themeColor: themeColor,
        workerData: workerData,
        onSubmit: (Map<String, dynamic> data) async {
          try {
            if (workerData != null) {
              // Update existing worker
              await _updateWorker(workerData['id'], data);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Worker updated successfully!'),
                  backgroundColor: themeColor,
                ),
              );
            } else {
              // Add new worker
              await _addWorker(data);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Worker added successfully!'),
                  backgroundColor: themeColor,
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  // Delete worker
  Future<void> _deleteWorker(String workerId) async {
    final url = Uri.parse('http://10.0.2.2:3000/garage/worker/$workerId');
    try {
      String? token = await storage.read(key: 'jwt_token');
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          workers.removeWhere((worker) => worker['id'] == workerId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Worker deleted successfully'),
            backgroundColor: themeColor,
          ),
        );
      } else {
        throw Exception('Failed to delete worker');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error deleting worker'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Workers',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: themeColor,
        elevation: 0,
        centerTitle: true,
        // Removed add icon from AppBar as requested
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addWorker',
        onPressed: () => _showWorkerForm(),
        backgroundColor: themeColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(240, 181, 255, 224),
              Colors.white,
            ],
          ),
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: themeColor))
            : errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                              errorMessage = '';
                            });
                            _fetchWorkers();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : workers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: themeColor.withOpacity(0.7),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No workers added yet",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Worker'),
                              onPressed: () => _showWorkerForm(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: themeColor,
                        onRefresh: _fetchWorkers,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: workers.length,
                          itemBuilder: (context, index) {
                            final worker = workers[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                shadowColor: Colors.black12,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    // No Worker details page as requested
                                    // Instead open the edit form directly
                                    _showWorkerForm(workerData: worker);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        // Profile Photo
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color:
                                                  themeColor.withOpacity(0.5),
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    themeColor.withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(50),
                                            child: Image.network(
                                              worker['profilePhoto'],
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return CircleAvatar(
                                                  radius: 35,
                                                  backgroundColor: themeColor
                                                      .withOpacity(0.1),
                                                  child: Icon(
                                                    Icons.person,
                                                    size: 40,
                                                    color: themeColor,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Worker Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                worker['username'],
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.phone,
                                                    size: 16,
                                                    color: themeColor,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    worker['phoneNumber'],
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.credit_card,
                                                    size: 16,
                                                    color: themeColor,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    worker['aadhaarNumber'],
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.location_on,
                                                    size: 16,
                                                    color: themeColor,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      worker['currentLocation'] ??
                                                          'Not Available',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black54,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Actions
                                        Column(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                color: themeColor,
                                              ),
                                              onPressed: () {
                                                // Open edit form directly as requested
                                                _showWorkerForm(
                                                    workerData: worker);
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                _showDeleteConfirmation(
                                                    context, worker['id']);
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }

  // Show delete confirmation dialog
  void _showDeleteConfirmation(BuildContext context, String workerId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this worker?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteWorker(workerId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

// Worker Form Widget (for both Add and Edit)
class WorkerForm extends StatefulWidget {
  final Color themeColor;
  final Map<String, dynamic>?
      workerData; // Null for new worker, populated for edit
  final Function(Map<String, dynamic>) onSubmit;

  const WorkerForm({
    Key? key,
    required this.themeColor,
    required this.onSubmit,
    this.workerData,
  }) : super(key: key);

  @override
  _WorkerFormState createState() => _WorkerFormState();
}

class _WorkerFormState extends State<WorkerForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _aadharController;

  String? _profileImageUrl;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  bool get isEditMode => widget.workerData != null;

  @override
  void initState() {
    super.initState();

    // Initialize with existing data if in edit mode
    _nameController = TextEditingController(
      text: widget.workerData?['username'] ?? '',
    );

    _phoneController = TextEditingController(
      text: widget.workerData?['phoneNumber'] ?? '',
    );

    _aadharController = TextEditingController(
      text: widget.workerData?['aadhaarNumber'] ?? '',
    );

    _profileImageUrl = widget.workerData?['profilePhoto'];
  }

  // Validate phone number
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length < 10 || value.length > 13) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  // Validate Aadhar number
  String? _validateAadhar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Aadhar number is required';
    }
    if (value.length != 12) {
      return 'Aadhar number must be 12 digits';
    }
    return null;
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Here you would typically upload the image to your server
        // and get back a URL. For this example, we'll just simulate it.
        setState(() {
          // In a real app, this would be the URL returned from your server
          _profileImageUrl = 'https://example.com/placeholder_image.jpg';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  // Submit the form
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Prepare worker data according to your backend schema
        final workerData = {
          'workerName': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'aadharNumber': _aadharController.text.trim(),
          // Only include picture if it's available
          if (_profileImageUrl != null) 'picture': _profileImageUrl,
        };

        // Call the callback function to add/update worker
        await widget.onSubmit(workerData);

        // Close the form
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _aadharController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate bottom padding to account for keyboard
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        bottom: keyboardHeight + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Form Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditMode ? 'Update Worker' : 'Add New Worker',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.themeColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Profile Photo
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: widget.themeColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.themeColor,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.themeColor.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: _profileImageUrl != null
                              ? Image.network(
                                  _profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                    Icons.person,
                                    size: 50,
                                    color: widget.themeColor,
                                  ),
                                )
                              : Icon(
                                  Icons.add_a_photo,
                                  size: 50,
                                  color: widget.themeColor,
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEditMode ? 'Change Photo' : 'Add Photo',
                        style: TextStyle(
                          color: widget.themeColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Worker Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Worker Name',
                  hintText: 'Enter worker name',
                  prefixIcon: Icon(Icons.person, color: widget.themeColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.themeColor, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone Number
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                  prefixIcon: Icon(Icons.phone, color: widget.themeColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.themeColor, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),
              const SizedBox(height: 16),

              // Aadhar Number
              TextFormField(
                controller: _aadharController,
                decoration: InputDecoration(
                  labelText: 'Aadhar Number',
                  hintText: 'Enter 12-digit Aadhar number',
                  prefixIcon: Icon(Icons.credit_card, color: widget.themeColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.themeColor, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.number,
                validator: _validateAadhar,
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isEditMode ? 'Update Worker' : 'Add Worker',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
