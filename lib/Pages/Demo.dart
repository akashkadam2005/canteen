import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WishlistPage extends StatefulWidget {
  const WishlistPage({Key? key}) : super(key: key);

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  List<dynamic> wishlistItems = [];
  List<dynamic> recommendedItems = [
    {
      'product_id': '101',
      'product_name': 'Veg Burger',
      'product_price': '49',
      'product_image': 'assets/images/veg_burger.jpg',
    },
    {
      'product_id': '102',
      'product_name': 'Cheese Pizza',
      'product_price': '129',
      'product_image': 'assets/images/cheese_pizza.jpg',
    },
  ];

  bool isRecommendedSelected = true; // Track which view is selected

  Future<void> fetchWishlistItems() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.242.172/CanteenAutomation/api/wishlist/index.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            wishlistItems = data['data'];
          });
        } else {
          print('Error: ${data['message']}');
        }
      } else {
        print('Failed to fetch wishlist items. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Widget buildHorizontalCardList(List<dynamic> items) {
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
              ],
            );
          },
        ),
      ),
    );
  }


  Widget buildCard(dynamic item) {
    return Card(
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
                    'http://192.168.242.172/CanteenAutomation/uploads/products/${item['product_image']}',
                    height: 90, // Reduced height for the image
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                      : Image.asset(
                    "assets/images/default.jpg",
                    height: 90, // Same reduced height for placeholder
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Discount Badge (positioned at the top-right corner)
                if (item['product_dis_value'] != null && double.tryParse(item['product_dis_value']) != null && double.parse(item['product_dis_value']) > 0)
                  Positioned(
                    top: 60,
                    right: 8,
                    // bottom: 30,
                    child:  Text(
                        '${item['product_dis_value']}% OFF',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,

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
                color: Colors.black,
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
    );
  }


  @override
  void initState() {
    super.initState();
    fetchWishlistItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Buttons for switching views
          SizedBox(height: 100),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isRecommendedSelected = true;
                  });
                },
                child: Text(
                  "Recommended",
                  style: TextStyle(
                    color: isRecommendedSelected ? Colors.white : Colors.green,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRecommendedSelected ? Colors.green : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(width: 16),
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
                      color: isRecommendedSelected ? Colors.green : Colors.red,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Favorites",
                      style: TextStyle(
                        color: !isRecommendedSelected ? Colors.white : Colors.green,
                      ),
                    ),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: !isRecommendedSelected ? Colors.green : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: SingleChildScrollView(
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
          ),
        ],
      ),
    );
  }
}
