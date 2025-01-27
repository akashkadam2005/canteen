import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../Authantication/AuthUser.dart';

class EditProfilePage extends StatefulWidget {
  final int customerId;
  final String name;
  final String mobile;
  final String address;
  final String email;
  final String image;

  const EditProfilePage({
    Key? key,
    required this.customerId,
    required this.name,
    required this.mobile,
    required this.address,
    required this.email,
    required this.image,
  }) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController mobileController;
  late TextEditingController addressController;
  late TextEditingController emailController;

  final _imageController = TextEditingController();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with the provided data
    nameController = TextEditingController(text: widget.name);
    mobileController = TextEditingController(text: widget.mobile);
    addressController = TextEditingController(text: widget.address);
    emailController = TextEditingController(text: widget.email);
    _imageController.text = widget.image;
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    nameController.dispose();
    mobileController.dispose();
    addressController.dispose();
    emailController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  // Method to pick an image from the gallery
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageController.text = pickedFile.name; // Store the image name or path
      });
    }
  }

  Future<void> updateCustomerProfile() async {
    final url = Uri.parse('http://192.168.1.38/CanteenAutomation/api/customer/update.php');

    final request = http.MultipartRequest('POST', url);

    // Add form data
    request.fields['customer_id'] = widget.customerId.toString();
    request.fields['customer_name'] = nameController.text;
    request.fields['customer_email'] = emailController.text;
    request.fields['customer_phone'] = mobileController.text;
    request.fields['customer_address'] = addressController.text;
    request.fields['customer_status'] = '1'; // Assuming 'active' as the status

    // If an image is selected, add it to the request
    if (_imageFile != null) {
      // Attach the image file to the request
      request.files.add(
        await http.MultipartFile.fromPath('customer_image', _imageFile!.path),
      );
    }

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);

        if (jsonResponse['success'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonResponse['success'])),
          );
        } else if (jsonResponse['error'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonResponse['error'])),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update profile")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("An error occurred!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!) // Display the selected image
                        : widget.image.isNotEmpty
                        ? NetworkImage(ApiHelper().getImageUrl('customers/${widget.image}')) as ImageProvider
                        : null,
                    child: _imageFile == null && widget.image.isEmpty
                        ? Text(
                      widget.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 40),
                    )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              buildTextField(controller: nameController, label: "Name", hint: "Enter your name"),
              const SizedBox(height: 20),
              buildTextField(
                controller: mobileController,
                label: "Mobile",
                hint: "Enter your mobile number",
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              buildTextField(controller: addressController, label: "Address", hint: "Enter your address"),
              const SizedBox(height: 20),
              buildTextField(controller: emailController, label: "Email", hint: "Enter your email"),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ElevatedButton(
          onPressed: updateCustomerProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: const Text("Save Changes", style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
