import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../Pages/HomeScreen.dart';
import 'AuthUser.dart';
import 'SingUp.dart';

class LoginPage extends StatefulWidget {

  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final ApiHelper apiHelper = ApiHelper();

  LoginPage({required this.toggleTheme, required this.isDarkMode});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;



  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email and password.';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await widget.apiHelper.httpPost(
        'customer/login.php',
        {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == "Login successful!") {
          String? token = data['token'];
          String? name = data['customer']?['customer_name'];
          int id = int.tryParse(data['customer']?['customer_id']?.toString() ?? '0') ?? 0;

          if (token != null && id > 0) {
            // Save token to SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('authToken', token);
            await prefs.setInt('userId', id);

            // Navigate to HomeScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  name: name ?? '',
                  id: id,
                  email: email ?? '',
                  phone: data['customer']?['customer_phone'] ?? '',
                  address: data['customer']?['customer_address'] ?? '',
                  image: data['customer']?['customer_image'] ?? '',
                  toggleTheme: widget.toggleTheme,
                  isDarkMode: widget.isDarkMode,
                ),
              ),
            );
          } else {
            setState(() {
              _errorMessage = 'Invalid token or customer ID received from the server.';
            });
          }
        } else {
          setState(() {
            _errorMessage = data['error'] ?? 'Invalid email or password.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}.';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'An error occurred: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [


                SizedBox(height: 20,),
                // App Logo or Icon
                Image.asset(
                  'assets/images/logo.png', // Replace with your actual image filename
                  height: 150,
                  width: 250,

                  fit: BoxFit.cover,
                ),

                SizedBox(height: 30),
                // Form
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.email, color: Colors.lightBlueAccent),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.lock, color: Colors.lightBlueAccent),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlueAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpPage(toggleTheme: widget.toggleTheme,
                          isDarkMode: widget.isDarkMode)),
                    );
                  },
                  child: const Text(
                    'Don’t have an account? Sign up',
                    style: TextStyle(
                      color: Colors.lightBlueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
