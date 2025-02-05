import 'dart:convert';
import 'package:canteen/Authantication/AuthUser.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart'; // Import Lottie package

class ContactUsPage extends StatefulWidget {
  @override
  _ContactUsPageState createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  bool isLoading = false;
  bool showSuccessAnimation = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Form validation logic
  bool validateForm() {
    return nameController.text.isNotEmpty &&
        emailController.text.isNotEmpty &&
        phoneController.text.isNotEmpty &&
        messageController.text.isNotEmpty;
  }

// Function to send data to the PHP backend
  Future<void> sendData() async {
    await _audioPlayer.play(AssetSource('images/notification1.mp3'));

    if (!validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('All fields are required!'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      isLoading = true;
    });

    final Map<String, dynamic> data = {
      'contact_name': nameController.text,
      'contact_email': emailController.text,
      'contact_phone': phoneController.text,
      'contact_message': messageController.text,
    };

    try {
      // Use the helper function for HTTP POST request
      final response = await ApiHelper().httpPost('contactus/store.php', data);

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        // Check if the response status is 'success'
        if (responseBody['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Message Sent Successfully!'),
            backgroundColor: Colors.green,
          ));

          setState(() {
            showSuccessAnimation = true;
          });

          // Navigate back after the animation finishes
          Future.delayed(Duration(seconds: 4), () {
            Navigator.pop(context);
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to communicate with the server.'),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to communicate with the server.'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.red,
      ));
    }

    setState(() {
      isLoading = false;
    });
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
                      // fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  SizedBox(height: 16),
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
                  // isLoading
                  //     ? Center(child: CircularProgressIndicator())
                  //     : ElevatedButton(
                  //   onPressed: sendData,
                  //   style: ElevatedButton.styleFrom(
                  //     padding: EdgeInsets.symmetric(vertical: 16),
                  //     backgroundColor: Colors.orange,
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(12),
                  //     ),
                  //     minimumSize: Size(double.infinity, 50),
                  //   ),
                  //   child: Text(
                  //     'Send Message',
                  //     style: TextStyle(fontSize: 18, color: Colors.white),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
          // Full-Screen Success Animation from Network
          if (showSuccessAnimation)
            Positioned.fill(
              child: Container(
                color: Colors.white.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.network(
                        'https://raw.githubusercontent.com/xvrh/lottie-flutter/master/example/assets/Mobilo/A.json', // URL of the Lottie animation
                        width: 200,
                        height: 200,
                      ),
                      SizedBox(height: 20),
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child:  ElevatedButton(
          onPressed: sendData,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: Size(double.infinity, 50),
          ),
          child: Text(
            'Send Message',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
