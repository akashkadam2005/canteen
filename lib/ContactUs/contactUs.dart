import 'dart:convert';
import 'package:canteen/Authantication/AuthUser.dart'; // Ensure this import is correct
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart'; // For Lottie animations

class ContactUsPage extends StatefulWidget {
  @override
  _ContactUsPageState createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  // Controllers for form fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  // State variables
  bool isLoading = false;
  bool showSuccessAnimation = false;

  // Audio player for feedback sounds
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Form validation logic
  bool validateForm() {
    // Check if all fields are filled
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        messageController.text.isEmpty) {
      return false;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(emailController.text)) {
      return false;
    }

    // Validate phone number format (simple check for digits)
    final phoneRegex = RegExp(r'^\d+$');
    if (!phoneRegex.hasMatch(phoneController.text)) {
      return false;
    }

    return true;
  }

  // Function to send data to the PHP backend
  Future<void> sendData() async {
    // Play a sound for user feedback
    await _audioPlayer.play(AssetSource('images/notification1.mp3'));

    // Validate the form
    if (!validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields correctly!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Set loading state
    setState(() {
      isLoading = true;
    });

    // Prepare data to send
    final Map<String, dynamic> data = {
      'contact_name': nameController.text,
      'contact_email': emailController.text,
      'contact_phone': phoneController.text,
      'contact_message': messageController.text,
    };

    try {
      // Send POST request to the backend
      final response = await ApiHelper().httpPost('contactus/store.php', data);

      // Check response status
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        // Check if the backend returned a success status
        if (responseBody['status'] == 'success') {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Message Sent Successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Show success animation
          setState(() {
            showSuccessAnimation = true;
          });

          // Navigate back after 4 seconds
          Future.delayed(Duration(seconds: 4), () {
            Navigator.pop(context);
          });
        } else {
          // Show error message from backend
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send message: ${responseBody['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Handle server errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Handle exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Reset loading state
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Us'),
        backgroundColor: Colors.orange,
      ),
      body: Stack(
        children: [
          // Main form content
          Padding(
            padding: EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo at the top
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png', // Add your logo image here
                      height: 300,
                      width: 400,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Name field
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Email field
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Phone field
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  SizedBox(height: 16),
                  // Message field
                  TextField(
                    controller: messageController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                    ),
                  ),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
          // Success animation overlay
          if (showSuccessAnimation)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Lottie animation
                      Lottie.network(
                        'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/example/assets/Mobilo/A.json',
                        width: 200,
                        height: 200,
                      ),
                      SizedBox(height: 20),
                      // Success message
                      Text(
                        'Message Sent Successfully!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      // Send button at the bottom
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ElevatedButton(
          onPressed: isLoading ? null : sendData, // Disable button when loading
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: Size(double.infinity, 50),
          ),
          child: isLoading
              ? CircularProgressIndicator(color: Colors.white) // Show loader when loading
              : Text(
            'Send Message',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}