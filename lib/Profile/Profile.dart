import 'package:canteen/Cart/History.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Authantication/AuthUser.dart';
import '../Authantication/Login.dart';
import '../Product/CollectionFavroite.dart';
import 'ProfileEdit.dart';
import 'package:canteen/ContactUs/contactUs.dart';


class ProfilePage extends StatefulWidget {

  final String name;
  final String phone;
  final String address;
  final String email;
  final String image;
  final int id;
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const ProfilePage({
    Key? key,
    required this.name,
    required this.phone,
    required this.address,
    required this.email,
    required this.image, required this.id,required this.toggleTheme, required this.isDarkMode
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isVegMode = true;
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all saved data

    // Navigate to LoginPage and clear the navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage( toggleTheme: widget.toggleTheme,
        isDarkMode: widget.isDarkMode,)),
          (route) => false,
    );
  }

  bool isDarkMode = false;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,),
        ),

        // backgroundColor: Colors.orangeAccent,
        elevation: 5.0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(

          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            Padding(
              padding: const EdgeInsets.all(15.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(
                        name: widget.name,
                        mobile: widget.phone,
                        address: widget.address,
                        email: widget.email,
                        image: widget.image, customerId: widget.id,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.black54, Colors.black],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(0, 5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.amber[100],
                            child: Text(
                              widget.name.substring(0, 1),
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {
                                  // Handle "View activity" action
                                },
                                child: const Text(
                                  "View activity >",
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Divider(color: Colors.grey[700], thickness: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.catching_pokemon, color: Colors.amber, size: 22),
                              SizedBox(width: 10),
                              Text(
                                "Gold member",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.amber, Colors.amberAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.5),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Text(
                              "saved ₹0",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),


            const SizedBox(height: 20),

            Container(

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGridItem(
                    icon: Icons.bookmark_outline,
                    label: "Collections",
                    onTap: () {
                      // Navigate to the Favorite Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Favorite(customerId: widget.id,)),
                      );
                    },
                  ),
                  _buildGridItem(
                    icon: Icons.history,
                    label: "History",
                    // value: "₹0",
                    onTap: () {
                      // Navigate to the Favorite Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HistoryPage(customerId: widget.id,)),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),


            _buildProfileListItem(
              context: context,
              icon: Icons.person_outline,
              title: "Your profile",
              name: widget.name,
              mobile: widget.phone,
              address: widget.address,
              email: widget.email,
              image: widget.image,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(
                      name: widget.name,
                      mobile: widget.phone,
                      address: widget.address,
                      email: widget.email,
                      image: widget.image, customerId: widget.id,
                    ),
                  ),
                );
              },
            ),

            // _buildListItem(
            //   context: context,
            //   icon: Icons.star_border,
            //   title: "Your rating",
            //   subtitle: "4.69",
            //   subtitleColor: Colors.amber,
            // ),
            // _buildListItem(
            //   context: context,
            //   icon: Icons.face,
            //   title: "Lookback 2024",
            // ),

            _buildListItem(
              context: context,
              icon: Icons.eco_outlined,
              title: "Veg Mode",
              trailing: Switch(
                value: isVegMode,
                onChanged: (value) {
                  setState(() {
                    isVegMode = value;
                  });
                },
                activeColor: Colors.green,
              ),
            ),
            // Appearance Settings
            _buildListItem(
              context: context,
              icon: Icons.color_lens_outlined,
              title: "Appearance",
              subtitle: widget.isDarkMode ? "DARK" : "LIGHT",
            ),
            // Contact Us Navigation
            _buildListItem(
              context: context,
              icon: Icons.contact_mail,
              title: "Contact Us",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContactUsPage()),
                );
              },
            ),
            // Logout Feature
            _buildListItem(
              context: context,
              icon: Icons.logout,
              title: "Logout",
              onTap: () {
                _logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Color? subtitleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: GestureDetector(
        onTap: () {
          if (title == "Appearance") {
            // Open the popup modal for theme selection
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text(
                    "Choose Theme",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.dark_mode),
                        title: const Text("Dark"),
                        onTap: () {
                          Navigator.of(context).pop(); // Close the modal
                          if (!widget.isDarkMode) {
                            widget.toggleTheme(); // Switch to dark theme
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.light_mode, color: Colors.amber),
                        title: const Text("Light"),
                        onTap: () {
                          Navigator.of(context).pop(); // Close the modal
                          if (widget.isDarkMode) {
                            widget.toggleTheme(); // Switch to light theme
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          } else if (onTap != null) {
            onTap();
          }
        },
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            leading: CircleAvatar(
              radius: 22,
              child: Icon(icon, size: 24),
            ),
            title: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: subtitle != null
                ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: subtitleColor ?? Colors.black54,
              ),
            )
                : null,
            trailing: trailing ??
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: widget.isDarkMode ? Colors.white : Colors.black54,
                ),
          ),
        ),
      ),
    );
  }





  Widget _buildGridItem({
    required IconData icon,
    required String label,
    String? value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap, // Handle tap for navigation or other actions
      child: Column(
        children: [
          Card(
            elevation: 4, // Add subtle shadow for a modern look
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15), // Rounded corners
            ),
            child: Container(
              height: 150,
              width: 150,
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 28,
                    // backgroundColor: Colors.grey[200],
                    child: Icon(icon, size: 28, ),
                  ),
                  const SizedBox(height: 8),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),

                  if (value != null)
                    Text(
                      value,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),

                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileListItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String name,
    required String mobile,
    required String address,
    required String email,
    required String image,
    VoidCallback? onTap,
  }) {
    // Calculate completion percentage for the profile
    int totalFields = 5;
    int completedFields = 0;

    if (name.isNotEmpty) completedFields++;
    if (mobile.isNotEmpty) completedFields++;
    if (address.isNotEmpty) completedFields++;
    if (email.isNotEmpty) completedFields++;
    if (image.isNotEmpty) completedFields++;

    int percentage = ((completedFields / totalFields) * 100).round();
    Color completionColor = percentage == 100 ? Colors.green : Colors.amber;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            leading: CircleAvatar(
              radius: 28,
              backgroundImage: image.isNotEmpty ? NetworkImage(ApiHelper().getImageUrl('customers/${widget.image}')) as ImageProvider : null,
              // backgroundColor: Colors.grey[200],
              child: image.isEmpty
                  ? Icon(icon, size: 28, )
                  : null,
            ),
            title: Text(
              title,
              style: const  TextStyle(fontSize: 14, fontWeight: FontWeight.w500,),
            ),
            subtitle: Text(
              "$percentage% profile completed",
              style: TextStyle(fontSize: 15, color: completionColor),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
          ),
        ),
      ),
    );
  }


}
