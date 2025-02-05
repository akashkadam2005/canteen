import 'dart:convert';
import 'dart:ffi';

import 'package:canteen/Pages/Demo.dart';
import 'package:canteen/Cart/GetCart.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../Authantication/AuthUser.dart';
import '../Product/Categorylist.dart';
import '../Product/CollectionFavroite.dart';
import '../Product/ProductView.dart';
import '../Profile/Profile.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
class HomeScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String image;
  final int id;
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const HomeScreen(
      {Key? key,
      required this.name,
      required this.id,
      required this.phone,
      required this.address,
      required this.email,
      required this.image,
      required this.toggleTheme,
      required this.isDarkMode})
      : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> categories = [];
  List<dynamic> products = [];
  String selectedCategory = 'All';
  bool _isDismissed = false;
  List<String> cartProducts = []; // Stores product IDs of items in the cart.

  List<dynamic> filteredProducts = [];
  int selectedItemCount = 0;
  Map<String, int> productQuantities = {};
  Map<String, bool> productAddedToCart = {};
  Map<String, bool> wishlistStatus = {};
  int cartItemCount = 0;
  bool isVeg = true; // Track the Veg/Non-Veg state
  bool isFocused = false;
  List<dynamic> wishlistItems = [];
  List<Map<String, dynamic>> favoriteProducts = [];
  bool isRecommendedSelected = false;
  List<dynamic> recommendedItems = [];
  List<String> imageUrls = [];
  bool isLoading = true;


  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _recognizedText = "";
  @override
  void initState() {
    super.initState();
    fetchData();
    fetchCartCount();
    fetchWishlistItems();
    fetchSliderImages();
    fetchSearchData();
  }



  void _startListening() async {
    var status = await Permission.microphone.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      print("Microphone permission denied");
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) => print("Status: $status"),
      onError: (error) => print("Error: $error"),
    );

    if (available) {
      setState(() {
        _isListening = true;
      });

      _speech.listen(
        onResult: (result) {
          setState(() {
            _recognizedText = result.recognizedWords;
          });
        },
      );
    } else {
      print("Speech recognition not available");
    }
  }


  Future<void> requestPermission() async {
    var status = await Permission.microphone.request();
    if (status.isDenied) {
      print("Microphone permission denied");
    }
  }
  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });

    if (_recognizedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please say something"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    var matchedProduct = products.firstWhere(
          (product) => product['product_name'].toLowerCase() == _recognizedText.toLowerCase(),
      orElse: () => null, // Return null if no match found
    );

    if (matchedProduct != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewProductPage(
            product: matchedProduct,
            id: widget.id,
            toggleTheme: widget.toggleTheme,
            isDarkMode: widget.isDarkMode,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Product Not Found"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _showVoiceModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full-screen modal if needed
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets, // Avoid keyboard overlap
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Speak Now",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Icon(Icons.mic, size: 60, color: Colors.orangeAccent),
                    SizedBox(height: 10),
                    Text(
                      _recognizedText.isEmpty ? "Listening..." : _recognizedText,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        _isListening ? _stopListening() : _startListening();
                      },
                      child: Text(_isListening ? "Stop Listening" : "Start Listening"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      _stopListening(); // Ensure listening stops when modal is closed
    });
  }




  TextEditingController searchController = TextEditingController();

  Future<void> fetchSearchData() async {
    try {
      final productResponse = await ApiHelper().httpGet('product/index.php');
      if (productResponse.statusCode == 200) {
        final fetchedProducts = json.decode(productResponse.body)['data'];

        setState(() {
          products = fetchedProducts;
          filteredProducts = products;
        });
      } else {
        print("Failed to fetch products.");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  void filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredProducts = [];
      } else {
        filteredProducts = products
            .where((product) => product['product_name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> fetchData() async {
    try {
      // Fetch Categories
      final categoryResponse = await ApiHelper().httpGet('category/index.php');
      if (categoryResponse.statusCode == 200) {
        final fetchedCategories = json.decode(categoryResponse.body)['data'];

        setState(() {
          categories = [
            {'category_id': 'All', 'category_name': 'All', 'category_image': ''}
          ];
          categories.addAll(fetchedCategories);
        });
      } else {
        print("Failed to fetch categories.");
      }

      // Fetch Products
      String productEndpoint = 'product/index.php';
      if (isVeg) {
        productEndpoint += '?product_status=1'; // Fetch only Veg products
      }
      print(productEndpoint);
      final productResponse = await ApiHelper().httpGet(productEndpoint);
      if (productResponse.statusCode == 200) {
        final fetchedProducts = json.decode(productResponse.body)['data'];

        setState(() {
          products = fetchedProducts;
        });
      } else {
        print("Failed to fetch products.");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> fetchSliderImages() async {
    final response = await ApiHelper()
        .httpGet('sliders/index.php'); // Fetch data from the API

    try {
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          setState(() {
            imageUrls = (jsonData['data'] as List)
                .map((item) => item['slider_image'] as String)
                .toList();
          });
        } else {
          print("API Error: ${jsonData['message']}");
        }
      } else {
        print("Failed to fetch data. Status code: ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching data: $error");
    }
  }

  String selectedSortOption = "Relevance";

  void openSortDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      // backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sort",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    // color: Colors.black,
                  ),
                ),
                SizedBox(height: 10),
                Column(
                  children: [
                    // List of sorting options
                    ...[
                      // "Relevance",
                      "Rating: High To Low",
                      // "Delivery Time: Low To High",
                      "Cost: Low To High",
                      "Cost: High To Low",
                    ].map(
                      (option) => RadioListTile<String>(
                        title: Text(
                          option,
                          // style: TextStyle(color: Colors.black),
                        ),
                        value: option,
                        groupValue: selectedSortOption,
                        activeColor: Colors.red,
                        onChanged: (value) {
                          setState(() {
                            selectedSortOption = value!;
                          });
                          Navigator.pop(
                              context, value); // Close modal with value
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedSortOption = "Relevance"; // Clear selection
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Close all",
                        // style: TextStyle(color: Colors.red),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        // backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Apply",
                        // style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((value) {
      if (value != null) {
        applySorting(value);
      }
    });
  }

  void applySorting(String sortOption) {
    setState(() {
      switch (sortOption) {
        case "Rating: High To Low":
          products.sort((a, b) => double.parse(b['avg_rating'])
              .compareTo(double.parse(a['avg_rating'])));
          break;
        // case "Delivery Time: Low To High":
        //   products.sort((a, b) =>
        //       double.parse(a['delivery_time']).compareTo(double.parse(b['delivery_time'])));
        //   break;
        case "Cost: Low To High":
          products.sort((a, b) => double.parse(a['product_price'])
              .compareTo(double.parse(b['product_price'])));
          break;
        case "Cost: High To Low":
          products.sort((a, b) => double.parse(b['product_price'])
              .compareTo(double.parse(a['product_price'])));
          break;
        default:
          // Default sorting logic or reset
          break;
      }
    });
  }

  Future<void> addItem(String productId, int quantity) async {
    try {
      // Step 1: Optimistic UI update (Update quantity immediately)
      setState(() {
        if (quantity == 0) {
          productQuantities[productId] = 0; // Revert to 0 if no product added
          cartItemCount -= 1;
          productAddedToCart[productId] = false;
        } else {
          cartItemCount += 1;
          productAddedToCart[productId] = true;
          productQuantities[productId] = quantity;
        }
      });

      // Step 2: Show the Lottie animation in full screen
      // Step 2: Show the Lottie animation in full screen with dark opacity background
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent closing the dialog
        builder: (BuildContext context) {
          return Stack(
            children: [
              // Background with opacity
              Container(
                color: Colors.black
                    .withOpacity(0.7), // Dark background with 70% opacity
              ),
              Center(
                child: Lottie.asset(
                  'assets/images/AnimationAddproduct.json', // Path to the Lottie file
                  fit: BoxFit.cover,
                ),
              ),
            ],
          );
        },
      );

      // Step 3: Wait for the animation duration
      await Future.delayed(Duration(seconds: 4));

      // Step 4: Close the Lottie animation dialog
      Navigator.of(context).pop();

      // Step 5: Make API call to add the item
      final response = await ApiHelper().httpPost(
        'cart/store.php',
        {
          'customer_id': widget.id,
          'product_id': int.parse(productId),
          'product_qty': 1,
        },
      );

      final data = json.decode(response.body);
      print(data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Fetch the updated cart count or other data
        await fetchCartCount(); // Update the cart count
        refreshPage(); // Refresh the page or data

        // Show success message
        showTopMessage(
            context, "Product added to cart successfully!", Colors.green);
      } else {
        // Handle failure (Revert optimistic update)
        setState(() {
          cartItemCount -= 1;
          productAddedToCart[productId] = false;
          productQuantities[productId] = 0;
        });

        // Show failure message
        showTopMessage(
            context, "Failed to add to cart. Please try again.", Colors.red);
      }
    } catch (e) {
      // Handle errors (Revert optimistic update)
      setState(() {
        cartItemCount -= 1;
        productAddedToCart[productId] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void refreshPage() {
    setState(() {
      // Add logic to fetch or refresh the page content here
      // For example, re-fetching product data or reloading the list
      fetchWishlistItems();
      fetchData();
      fetchCartCount();
    });
  }

  Future<void> fetchCartCount() async {
    try {
      // Show loading spinner while fetching
      setState(() {
        cartItemCount = 0; // Reset cart item count initially while loading
        productQuantities.clear(); // Clear previous product quantities
      });

      // Use ApiHelper to send a GET request
      final response = await ApiHelper().httpGet('cart/index.php');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          // Filter the data based on customer_id matching widget.id
          final filteredCartItems = data['data']
              .where((item) => item['customer_id'] == widget.id.toString())
              .toList();

          setState(() {
            cartItemCount = filteredCartItems.length; // Update the cart count
          });

          for (var item in filteredCartItems) {
            String productId = item['cart_product_id'].toString();
            int quantity = int.parse(item['cart_product_qty'].toString());
            // Update the productQuantities map with the quantity for each product
            productQuantities[productId] = quantity;
          }
        }
      } else {
        print('Failed to load cart items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching cart data: $e');
    }
  }

  Future<void> addToWishlist(String productId, String customer) async {
    try {
      final response = await ApiHelper().httpPost(
        'wishlist/store.php',
        {'wishlist_product_id': productId, 'customer_id': widget.id},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            wishlistStatus[productId] = true; // Update local wishlist status
          });
          showTopMessage(context, "Added to wishlist", Colors.green);

          // Refresh wishlist items
          await fetchWishlistItems();
          await removeFromWishlist(wishlistItems as String);
        } else {
          showTopMessage(context, "Failed to add to wishlist", Colors.red);
        }
      } else {
        showTopMessage(context, "Failed to add to wishlist", Colors.red);
      }
    } catch (e) {
      print("Error adding to wishlist: $e");
    }
  }

  Future<void> removeFromWishlist(String wishlistId) async {
    try {
      // Ensure wishlistId is not empty
      if (wishlistId.isEmpty) {
        print('Error: Wishlist ID must not be empty.');
        return;
      }

      // Call the ApiHelper's delete method
      final response = await ApiHelper().httpDelete(
        'wishlist/deleteWish.php', // Endpoint
        {'wishlist_id': wishlistId}, // Request body
      );

      // Print response for debugging
      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            wishlistStatus.remove(wishlistId); // Update local state
          });
          print('Wishlist item removed successfully.');
          showTopMessage(context, "Item removed from wishlist!", Colors.green);
        } else {
          print('Error: ${data['message']}');
          showTopMessage(
              context, data['message'] ?? "Failed to remove item.", Colors.red);
        }
      } else {
        print(
            'Failed to delete wishlist item. Status code: ${response.statusCode}');
        showTopMessage(context, "Failed to connect to the server.", Colors.red);
      }
    } catch (e) {
      print('Error: $e');
      showTopMessage(context, "An error occurred: $e", Colors.red);
    }
  }

  Future<void> deleteAllCartItems() async {
    try {
      // Call the ApiHelper's post method
      final response = await ApiHelper().httpPost(
        'cart/removeCart.php', // Endpoint
        {'customer_id': widget.id.toString()}, // Request body
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['status'] == 'success') {
          setState(() {
            cartItemCount = 0; // Reset cart count
            productQuantities.clear();
            _isDismissed = true; // Clear product quantities
          });
          showTopMessage(
            context,
            "All items deleted successfully!",
            Colors.green,
          );

          // Refresh cart data to ensure UI updates
          await fetchCartCount();
        } else {
          showTopMessage(
            context,
            responseData['message'] ?? "Failed to delete cart items.",
            Colors.red,
          );
        }
      } else {
        showTopMessage(
          context,
          "Failed to connect to the server.",
          Colors.red,
        );
      }
    } catch (e) {
      print("Error: $e");
      showTopMessage(context, "An error occurred: $e", Colors.red);
    }
  }

  Future<void> fetchWishlistItems() async {
    try {
      final response = await ApiHelper()
          .httpGet('wishlist/index.php'); // Use the modified httpGet method

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          // Filter the wishlist items for the logged-in user
          final filteredWishlistItems = data['data']
              .where((item) => item['customer_id'] == widget.id.toString())
              .toList();

          setState(() {
            wishlistItems = filteredWishlistItems; // Update the wishlist items
          });
        } else {
          print('Error: ${data['message']}');
        }
      } else {
        print(
            'Failed to fetch wishlist items. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Widget buildHorizontalCardList(List<dynamic> items) {
    if (items.isEmpty) {
      // Display "No Recommended Items Found" if the list is empty
      return Center(
        child: Text(
          'No Items Found',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      );
    }

    // Render horizontal list if items are available
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Horizontal scrolling
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          (items.length / 2).ceil(), // Number of columns (two items per row)
          (rowIndex) {
            // Create 2 rows per column
            final int firstIndex = rowIndex * 2;
            final int secondIndex = firstIndex + 1;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Row 1 item
                if (firstIndex < items.length) buildCard(items[firstIndex]),
                SizedBox(height: 10), // Space between rows
                // Row 2 item
                if (secondIndex < items.length) buildCard(items[secondIndex]),
                SizedBox(height: 10),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget buildCard(dynamic item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewProductPage(
              product: item,
              id: widget.id, toggleTheme: widget.toggleTheme,
              isDarkMode:
                  widget.isDarkMode, // Pass the product ID or any relevant data
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
        child: Container(
          width: 110, // Smaller card width
          padding: EdgeInsets.all(6), // Reduced padding for a compact layout
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: item['product_image']?.isNotEmpty ?? false
                        ? Image.network(
                            ApiHelper().getImageUrl(
                                'products/${item['product_image']}'),
                            // 'http://192.168.242.172/CanteenAutomation/uploads/products/${item['product_image']}',
                            height: 90, // Reduced height for the image
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            "assets/images/p1.jpg",
                            height: 90, // Same reduced height for placeholder
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  if (item['product_dis_value'] != null &&
                      double.tryParse(item['product_dis_value']) != null &&
                      double.parse(item['product_dis_value']) > 0)
                    Positioned(
                      top: 60,
                      right: 8,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${item['product_dis_value']}% OFF',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                item['product_name'],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12, // Smaller font size for a compact look
                  // color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                "₹${item['product_price']}",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    List<dynamic> filteredProducts = selectedCategory == 'All'
        ? products
        : products
            .where((product) => product['category_id'] == selectedCategory)
            .toList();
    Widget _buildCategoryItem(Map<String, dynamic> category) {
      return GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory = category['category_id'];
            // Filter products based on the selected category
            filteredProducts = products
                .where((product) => product['category_id'] == selectedCategory)
                .toList();
          });
          SizedBox(
            height: 10,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: category['category_image']?.isNotEmpty ?? false
                    ? Image.network(
                        ApiHelper().getImageUrl(
                            'categories/${category['category_image']}'),
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        "assets/images/p1.jpg",
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
              ),
              SizedBox(height: 10), // Hei
              Text(
                category['category_name'],
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      );
    }

    void showVegModeModal() {
      showDialog(
        context: context,
        barrierDismissible: true, // Dismiss modal by tapping outside
        builder: (context) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                width: 350, // Modal width
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Warning Icon
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.red[50],
                      child: Icon(
                        Icons.warning,
                        size: 50,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Modal Heading
                    Text(
                      "Switch off Veg Mode?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description
                    Text(
                      "You'll see all restaurants, including those serving non-veg dishes.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Switch Off Button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            // Logic for switching off Veg Mode
                            setState(() {
                              isVeg = false;
                            });
                            fetchData(); // Update data for Non-Veg
                            Navigator.of(context).pop(); // Close modal
                          },
                          child: const Text(
                            "Switch off",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Keep Using This Mode Button
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(); // Close modal
                          },
                          child: const Text(
                            "Keep using this mode",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
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
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Hide the back button
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.start, // Align title to the start
          children: [
            Text(
              'CANTEEN AUTOMATION',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary, // Dynamic text color
              ),
            ),
          ],
        ),
        backgroundColor:
            Theme.of(context).colorScheme.primary, // Dynamic background color
        elevation: 5.0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer ??
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          // Shopping Cart Icon with Counter
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.shopping_cart,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimary, // Dynamic icon color
                ),
                onPressed: () async {
                  final updatedCount = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(
                        onCartUpdated: (newCount) {
                          setState(() {
                            cartItemCount =
                                newCount; // Update the cart count in the home page
                          });
                        },
                        id: widget.id,
                        productQuantities: productQuantities,
                        Address: widget.address,
                        email: widget.email,
                        phone: widget.phone,
                        image: widget.image,
                        name: widget.name,
                        toggleTheme: widget.toggleTheme,
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                  );

                  if (updatedCount != null) {
                    setState(() {
                      cartItemCount =
                          updatedCount; // Update cart count when returning
                    });
                  }
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .secondary, // Dynamic badge background color
                    child: Text(
                      '$cartItemCount',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondary, // Dynamic badge text color
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Profile Icon
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfilePage(
                      id: widget.id,
                      name: widget.name,
                      email: widget.email,
                      phone: widget.phone,
                      address: widget.address,
                      image: widget.image,
                      toggleTheme: widget.toggleTheme,
                      isDarkMode: widget.isDarkMode,
                    ),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .secondaryContainer, // Dynamic profile background color
                child: Text(
                  widget.name.isNotEmpty
                      ? widget.name[0]
                          .toUpperCase() // First letter of the name, capitalized
                      : '?', // Fallback for an empty name
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context)
                        .colorScheme
                        .onSecondaryContainer, // Dynamic profile text color
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04), // Responsive padding
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Space between widgets
                children: [
                  // Search Bar
                  Container(
                    height: 50,
                    width: screenWidth *
                        0.65, // Adjust width for better responsiveness
                    decoration: BoxDecoration(
                      color: Colors.white, // Background color for the container
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withOpacity(0.1), // Subtle shadow color
                          blurRadius: 10,
                          offset: Offset(0, 5), // Slight offset for the shadow
                        ),
                      ],
                    ),

                    child:
                    Row(
                      children: [
                        Expanded(
                          child: TypeAheadField(
                            suggestionsCallback: (String query) {
                              return products
                                  .where((product) => product['product_name']
                                  .toString()
                                  .toLowerCase()
                                  .contains(query.toLowerCase()))
                                  .toList();
                            },
                            builder: (context, textEditingController, focusNode) {
                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                onChanged: (value) {
                                  filterSearch(value);
                                },
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                                  prefixIcon: Icon(Icons.search, color: Colors.orangeAccent),
                                  hintText: "Search here...",
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  border: InputBorder.none,
                                ),
                              );
                            },
                            itemBuilder: (context, dynamic suggestion) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ViewProductPage(
                                        product: suggestion, // Pass only the selected product
                                        id: widget.id,
                                        toggleTheme: widget.toggleTheme,
                                        isDarkMode: widget.isDarkMode,
                                      ),
                                    ),
                                  );
                                },
                                child: ListTile(
                                  leading: Image.network(
                                    ApiHelper().getImageUrl(
                                      'products/${suggestion['product_image']}',
                                    ),
                                    height: 40,
                                    width: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/p1.jpg', // Default image path
                                        height: 40,
                                        width: 40,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                  title: Text(suggestion['product_name']),
                                ),
                              );
                            },
                            onSelected: (dynamic value) {
                              print("Selected Product: ${value['product_name']}");
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewProductPage(
                                    product: value, // Pass the selected product
                                    id: widget.id,
                                    toggleTheme: widget.toggleTheme,
                                    isDarkMode: widget.isDarkMode,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (!isFocused)
    Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => _showVoiceModal(context),
        child: CircleAvatar(
          backgroundColor: Colors.orangeAccent.withOpacity(0.2),
          radius: 18,
          child: Icon(Icons.mic, color: Colors.orangeAccent, size: 20),
        ),
      ),
    ),
                      ],
                    )

                  ),
                  // Veg/Non-Veg Switch
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Text indicating Veg Mode status
                        Text(
                          isVeg ? 'Veg\nmode on' : 'Veg\nmode off',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isVeg ? Colors.green[800] : Colors.red[800],
                            fontSize: isVeg ? 10 : 12,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),

                        // Veg/Non-Veg toggle switch
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: isVeg,
                            onChanged: (value) {
                              if (!value) {
                                // Show modal when Veg mode is turned off
                                showVegModeModal();
                              } else {
                                // Update state for Veg mode
                                setState(() {
                                  isVeg = value;
                                });
                                fetchData(); // Fetch Veg data
                              }
                            },
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,
                            inactiveTrackColor: Colors.red[200],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.0),
              child: imageUrls.isEmpty
                  ? Center(
                      child:
                          CircularProgressIndicator()) // Show loading while images are being fetched
                  : CarouselSlider.builder(
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index, realIndex) {
                        // Ensure imageUrls[index] is valid
                        final imageUrl = ApiHelper()
                            .getImageUrl('sliders/${imageUrls[index]}');
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 250,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(child: Icon(Icons.error));
                              },
                            ),
                          ),
                        );
                      },
                      options: CarouselOptions(
                        height: 200,
                        viewportFraction: 1.0,
                        enlargeCenterPage: true,
                        enableInfiniteScroll: true,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 5),
                        autoPlayAnimationDuration:
                            const Duration(milliseconds: 1000),
                        autoPlayCurve: Curves.easeInOut,
                      ),
                    ),
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isRecommendedSelected = false;
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color:
                              isRecommendedSelected ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Favorites",
                          style: TextStyle(
                            color: !isRecommendedSelected
                                ? Colors.white
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          !isRecommendedSelected ? Colors.green : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isRecommendedSelected = true;
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          Icons.recommend,
                          color: !isRecommendedSelected
                              ? Colors.green
                              : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Recommended",
                          style: TextStyle(
                            color: isRecommendedSelected
                                ? Colors.white
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isRecommendedSelected ? Colors.green : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  isRecommendedSelected
                      ? buildHorizontalCardList(recommendedItems)
                      : buildHorizontalCardList(wishlistItems),

                ],
              ),
            ),
            SizedBox(
              height: 30,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.center, // Center the text
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 8), // Space between "Start" and main text
                    Text(
                      "WHAT'S ON YOUR MIND ?",
                      style: TextStyle(
                        fontSize:
                            18, // Slightly smaller font size for the main text
                        fontWeight: FontWeight.bold, // Bold text for emphasis
                        // color: Colors.deepPurple, // Contrasting color
                        letterSpacing: 1.2, // Refined look with letter spacing
                        shadows: [
                          Shadow(
                            blurRadius: 8.0,
                            color:
                                Colors.black.withOpacity(0.3), // Subtle shadow
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center, // Centered main text
                    ),
                    SizedBox(height: 8), // Space between main text and "End"
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 30,
            ),
            categories.isEmpty
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal, // Horizontal scrolling
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        (categories.length / 2).ceil(), // Number of columns
                        (columnIndex) {
                          // Create 2 rows per column
                          final int firstIndex = columnIndex * 2;
                          final int secondIndex = firstIndex + 1;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Row 1 item
                              if (firstIndex < categories.length)
                                _buildCategoryItem(categories[firstIndex]),
                              SizedBox(height: 10),
                              // Row 2 item
                              if (secondIndex < categories.length)
                                _buildCategoryItem(categories[secondIndex]),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(width: 10),
                Flexible(
                  flex: 2,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 3,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      items:
                          categories.map<DropdownMenuItem<String>>((category) {
                        return DropdownMenuItem<String>(
                          value: category['category_id'],
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundImage: category['category_image'] !=
                                            null &&
                                        category['category_image'].isNotEmpty
                                    ? NetworkImage(
                                        ApiHelper().getImageUrl(
                                            'categories/${category['category_image']}'),
                                      )
                                    : AssetImage('assets/images/p1.jpg')
                                        as ImageProvider,
                              ),
                              SizedBox(width: 8),
                              Text(
                                category['category_name'],
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value!;
                        });
                      },
                      isExpanded: true,
                      underline: SizedBox(),
                      icon: Icon(Icons.arrow_drop_down_circle,
                          color: Colors.blueAccent),
                      dropdownColor: Colors.white,
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => openSortDialog(context),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 20),
                                  margin: EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey[850]
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.black45
                                            : Colors.black12,
                                        blurRadius: 5,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.sort,
                                        size: 20,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        "Sort",
                                        style: TextStyle(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 21),
                              GestureDetector(
                                onTap: () => openSortDialog(context),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 20),
                                  margin: EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.grey[850]
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.black45
                                            : Colors.black12,
                                        blurRadius: 5,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                        size: 20,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        "Rating",
                                        style: TextStyle(
                                          // color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                ],
              ),
            ),
            filteredProducts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(15),
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      String productId = product['product_id'];

                      // Initialize the quantity if it's not set
                      if (!productQuantities.containsKey(productId)) {
                        productQuantities[productId] = 0;
                      }

                      // Find if the product is in the wishlist and get its wishlist_id
                      Map<String, dynamic>? getWishlistItem(String productId) {
                        return wishlistItems.firstWhere(
                          (item) => item['wishlist_product_id'] == productId,
                          orElse: () => null,
                        );
                      }

                      // Check if the product is in the wishlist
                      bool isInWishlist(String productId) {
                        return getWishlistItem(productId) != null;
                      }

                      // Get the wishlist_id for the product
                      String? getWishlistId(String productId) {
                        final wishlistItem = getWishlistItem(productId);
                        return wishlistItem?['wishlist_id'];
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewProductPage(
                                  product: product,
                                  id: widget.id,
                                  toggleTheme: widget.toggleTheme,
                                  isDarkMode: widget.isDarkMode),
                            ),
                          );
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Image
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(15)),
                                    child:
                                        product['product_image']?.isNotEmpty ??
                                                false
                                            ? Image.network(
                                                ApiHelper().getImageUrl(
                                                    'products/${product['product_image']}'),
                                                height: 160,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.asset(
                                                "assets/images/p1.jpg",
                                                height: 160,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                  ),
                                  // Wishlist Icon
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: CircleAvatar(
                                        backgroundColor: isInWishlist(productId)
                                            ? Colors.red
                                            : Colors.grey.shade300,
                                        child: Icon(
                                          isInWishlist(productId)
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isInWishlist(productId)
                                              ? Colors.white
                                              : Colors.grey,
                                        ),
                                      ),
                                      onPressed: () async {
                                        if (isInWishlist(productId)) {
                                          String? wishlistId =
                                              getWishlistId(productId);
                                          if (wishlistId != null) {
                                            setState(() {
                                              wishlistItems.removeWhere(
                                                  (item) =>
                                                      item['wishlist_id'] ==
                                                      wishlistId);
                                            });
                                            try {
                                              await removeFromWishlist(
                                                  wishlistId);
                                            } catch (e) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                content: Text(
                                                    "Failed to remove from wishlist."),
                                                backgroundColor: Colors.red,
                                              ));
                                            }
                                          }
                                        } else {
                                          await addToWishlist(
                                              productId, widget.id.toString());
                                        }
                                      },
                                    ),
                                  ),
                                  // Veg Icon (Top Right, below wishlist)
                                  Padding(
                                    padding: const EdgeInsets.all(15.0),
                                    child: Container(
                                      width: 23,
                                      height: 23,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.rectangle,
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(
                                          color:
                                              product['product_status'] == "1"
                                                  ? Colors.green
                                                  : Colors.red,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                product['product_status'] == "1"
                                                    ? Colors.green
                                                    : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            product['product_name'],
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              "₹${product['product_price']}",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                            Text(
                                              "₹${((double.tryParse(product['product_price'] ?? '0') ?? 0) - (double.tryParse(product['product_dis_value'] ?? '0') ?? 0)).toStringAsFixed(2)}",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: List.generate(5, (index) {
                                                double rating = double.tryParse(product['avg_rating'] ?? '0') ?? 0;
                                                return Icon(
                                                  Icons.star,
                                                  size: 18,
                                                  color: index < rating.round() ? Colors.orange : Colors.grey.shade400,
                                                );
                                              }),
                                            ),

                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            product['product_description'],
                                            style: TextStyle(
                                              fontSize: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.03,
                                              fontWeight: FontWeight.normal,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        // Container(
                                        //   padding: EdgeInsets.symmetric(
                                        //       horizontal: 6, vertical: 2),
                                        //   decoration: BoxDecoration(
                                        //     color: Colors.green,
                                        //     borderRadius: BorderRadius.circular(5),
                                        //   ),
                                        //   child: Text(
                                        //     "${product['product_dis']} Rating",
                                        //     style: TextStyle(
                                        //       fontSize: 12,
                                        //       color: Colors.white,
                                        //     ),
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.local_offer,
                                                size: 16, color: Colors.blue),
                                            SizedBox(width: 5),
                                            Text(
                                              "${product['product_dis_value']}% OFF "
                                              // "up to ₹${product['product_price']}"
                                              ,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Quantity or Add Button
                                            (productQuantities[productId] ??
                                                        0) ==
                                                    0
                                                ? GestureDetector(
                                                    onTap: () async {
                                                      setState(() {
                                                        productQuantities[
                                                                productId] =
                                                            1; // Set quantity to 1
                                                      });
                                                      await addItem(productId,
                                                          1); // Add the product to the backend
                                                    },
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 6,
                                                              horizontal: 12),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.orangeAccent,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.2),
                                                            blurRadius: 6,
                                                            offset:
                                                                Offset(2, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        "Add",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 6,
                                                            horizontal: 12),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.orangeAccent,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.2),
                                                          blurRadius: 6,
                                                          offset: const Offset(
                                                              2, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      "${productQuantities[productId]}", // Show the current quantity
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                            SizedBox(
                                              width: 20,
                                            ),
                                            // Increment Button
                                            GestureDetector(
                                              onTap: () async {
                                                setState(() {
                                                  productQuantities[productId] =
                                                      (productQuantities[
                                                                  productId] ??
                                                              0) +
                                                          1; // Increment quantity
                                                });
                                                await addItem(
                                                    productId,
                                                    productQuantities[
                                                        productId]!); // Update backend
                                              },
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.green
                                                          .withOpacity(0.2),
                                                      blurRadius: 6,
                                                      offset:
                                                          const Offset(2, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.add,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
      bottomNavigationBar: cartItemCount > 0 && !_isDismissed
          ? Dismissible(
              key: const Key('cart_button'),
              direction: DismissDirection
                  .endToStart, // Swipe left to show 'Delete All'
              confirmDismiss: (direction) async {
                // Update cart item count immediately before showing the dialog
                setState(() {
                  cartItemCount = 0; // Reset cart item count immediately
                });

                // Show confirmation dialog after resetting the count
                final bool? confirm = await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Clear Cart"),
                      content: const Text(
                          "Are you sure you want to delete all items in the cart?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false); // Do not dismiss
                          },
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () {
                            deleteAllCartItems(); // Call the function to delete all items
                            setState(() {
                              _isDismissed =
                                  true; // Mark the Dismissible as dismissed
                            });
                            Navigator.pop(context, true); // Confirm dismissal
                          },
                          child: Text("Delete All"),
                        ),
                      ],
                    );
                  },
                );
                return confirm ?? false; // Only dismiss if confirmed
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.delete_forever,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Delete All",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(
                        onCartUpdated: (newCount) {
                          setState(() {
                            cartItemCount =
                                newCount; // Update cart count immediately
                          });
                        },
                        id: widget.id,
                        productQuantities: productQuantities,
                        Address: widget.address,
                        email: widget.email,
                        phone: widget.phone,
                        image: widget.image,
                        name: widget.name,
                        toggleTheme: widget.toggleTheme,
                        isDarkMode: widget.isDarkMode,
                      ),
                    ),
                  );
                },
                child: Container(
                  color: Colors.green,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "$cartItemCount Cart added", // Show updated count instantly
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Free dish unlocked for you",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : SizedBox.shrink(),

      // Only show bottom bar if cartItemCount > 0
    );
  }
}
