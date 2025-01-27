//
// import 'package:flutter/material.dart';
// import 'dart:async';
//
// import '../Authantication/Login.dart';
//
// class SplashScreen extends StatefulWidget {
//   final VoidCallback toggleTheme;
//
//   const SplashScreen({Key? key, required this.toggleTheme}) : super(key: key);
//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     Timer(Duration(seconds: 10), () {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => LoginPage()),
//       );
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // Background gradient
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.orangeAccent, Colors.deepOrange],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),
//           // Decorative shapes
//           Positioned(
//             top: -80,
//             left: -60,
//             child: Container(
//               height: 250,
//               width: 250,
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.3),
//                 shape: BoxShape.circle,
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: -100,
//             right: -80,
//             child: Container(
//               height: 350,
//               width: 350,
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.2),
//                 shape: BoxShape.circle,
//               ),
//             ),
//           ),
//           // Center content
//           Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 // Large high-quality icon
//                 Container(
//                   padding: EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.white,
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.2),
//                         blurRadius: 20,
//                         spreadRadius: 5,
//                       ),
//                     ],
//                   ),
//                   child: Image.asset(
//                     'assets/images/cantain.jpg', // Replace with your icon
//                     height: 180,
//                     width: 180,
//                   ),
//                 ),
//                 SizedBox(height: 30),
//                 // Stylish app name
//                 Text.rich(
//                   TextSpan(
//                     text: 'Canteen\n', // First line
//                     style: TextStyle(
//                       fontSize: 38,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                       shadows: [
//                         Shadow(
//                           offset: Offset(3, 3),
//                           blurRadius: 5,
//                           color: Colors.black.withOpacity(0.5),
//                         ),
//                       ],
//                     ),
//                     children: [
//                       TextSpan(
//                         text: 'Automation', // Second line
//                         style: TextStyle(
//                           fontSize: 38,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                           shadows: [
//                             Shadow(
//                               offset: Offset(3, 3),
//                               blurRadius: 5,
//                               color: Colors.black.withOpacity(0.5),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//
//                 SizedBox(height: 30),
//                 // Enhanced loading indicator
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     SizedBox(
//                       height: 25,
//                       width: 25,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 3,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                       ),
//                     ),
//                     SizedBox(width: 10),
//                     Text(
//                       'Loading...',
//                       style: TextStyle(
//                         fontSize: 18,
//                         color: Colors.white,
//                         fontStyle: FontStyle.italic,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
//


import 'package:flutter/material.dart';
import 'dart:math';

import '../Authantication/Login.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  SplashScreen({required this.toggleTheme, required this.isDarkMode});
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 9),
      vsync: this,
    )..repeat();

    // Navigate to the next screen after a delay
    Future.delayed(const Duration(seconds: 10), () {
      Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(
        toggleTheme: widget.toggleTheme,
        isDarkMode: widget.isDarkMode,
      ))); // Replace with your route
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set the background image
      body: Stack(
        children: [
          // Full Screen Image Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/canteen[1].png', // Make sure the image is in the correct folder
              fit: BoxFit.cover,
            ),
          ),
          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rotating Icon with Glow Effect
                // AnimatedBuilder(
                //   animation: _controller,
                //   builder: (context, child) {
                //     return Transform.rotate(
                //       angle: _controller.value * 2 * pi,
                //       child: Container(
                //         padding: const EdgeInsets.all(30),
                //         decoration: BoxDecoration(
                //           shape: BoxShape.circle,
                //           boxShadow: [
                //             BoxShadow(
                //               color: Colors.redAccent.withOpacity(0.5),
                //               blurRadius: 40,
                //               spreadRadius: 10,
                //             ),
                //           ],
                //           gradient: LinearGradient(
                //             colors: [Colors.orange, Colors.deepOrangeAccent],
                //             begin: Alignment.topLeft,
                //             end: Alignment.bottomRight,
                //           ),
                //         ),
                //         child: const Icon(
                //           Icons.fastfood_rounded,
                //           size: 150,
                //           color: Colors.white,
                //         ),
                //       ),
                //     );
                //   },
                // ),
                const SizedBox(height: 200),
                // Application Name
                // Text(
                //   "Canteen Automation",
                //   style: TextStyle(
                //     fontSize: 28,
                //     fontWeight: FontWeight.bold,
                //     color: Colors.white,
                //     shadows: [
                //       Shadow(
                //         color: Colors.black26,
                //         blurRadius: 10,
                //         offset: Offset(3, 3),
                //       ),
                //     ],
                //   ),
                // ),
                const SizedBox(height: 100),
                // Animated Loading Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    4,
                        (index) => AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: (sin(_controller.value * 2 * pi + (index * pi / 2)) + 1.5) / 2,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
