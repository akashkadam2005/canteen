import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'AuthUser.dart';
import 'Login.dart';

class SignUpPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  SignUpPage({required this.toggleTheme, required this.isDarkMode});
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  File? _image;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final apiHelper = ApiHelper(); // Get the singleton instance
      final url = Uri.parse('${apiHelper.baseUrl}customer/store.php');

      var request = http.MultipartRequest('POST', url);

      request.fields['customer_name'] = _nameController.text;
      request.fields['customer_email'] = _emailController.text;
      request.fields['customer_password'] = _passwordController.text;
      request.fields['customer_phone'] = _phoneController.text;
      request.fields['customer_address'] = _addressController.text;

      if (_image != null) {
        var image = await http.MultipartFile.fromPath('customer_image', _image!.path);
        request.files.add(image);
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final Map<String, dynamic> responseJson = json.decode(responseData);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(
              toggleTheme: widget.toggleTheme,
              isDarkMode: widget.isDarkMode,
            ),
          ),
        );

        if (responseJson['success'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseJson['success'])),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseJson['error'])),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error with server!')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean White Background
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20,),
            // App Logo or Icon
            Image.asset(
              'assets/images/logo.png', // Replace with your actual image filename
              height: 100,
              width: 250,
              fit: BoxFit.cover,
            ),

            SizedBox(height: 30),

            // Registration Form Container
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    buildTextField('Full Name', _nameController, Icons.person),
                    buildTextField('Email Address', _emailController, Icons.email, isEmail: true),
                    buildTextField('Password', _passwordController, Icons.lock, isPassword: true),
                    buildTextField('Phone Number', _phoneController, Icons.phone),
                    buildTextField('Address', _addressController, Icons.location_on),
                    SizedBox(height: 20),

                    // Profile Image Picker
                    InkWell(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _image != null ? FileImage(_image!) : null,
                        child: _image == null
                            ? Icon(Icons.camera_alt, color: Colors.white, size: 40)
                            : null,
                      ),
                    ),

                    SizedBox(height: 20),

                    // Register Button
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Register',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Login Navigation
            GestureDetector(
              onTap: () {
                // Navigate to Login Page
                Navigator.push(context, MaterialPageRoute(builder: (context)=>LoginPage(toggleTheme: widget.toggleTheme,
                  isDarkMode: widget.isDarkMode,)));
              },
              child: Text(
                'Already have an account? Login',
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildTextField(String label, TextEditingController controller, IconData icon, {bool isEmail = false, bool isPassword = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.orangeAccent),
        labelText: label,
        labelStyle: TextStyle(color: Colors.orangeAccent),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.lightBlueAccent),
          borderRadius: BorderRadius.circular(10),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        if (isEmail && !RegExp(r"^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
          return 'Please enter a valid email';
        }
        return null;
      },
    ),
  );
}
