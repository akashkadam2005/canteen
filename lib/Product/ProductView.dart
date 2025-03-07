import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../Authantication/AuthUser.dart';

class ViewProductPage extends StatefulWidget {
  final dynamic product;
  final int id;
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  ViewProductPage({Key? key, required this.product, required this.id, required this.toggleTheme, required this.isDarkMode,}) : super(key: key);

  @override
  _ViewProductPageState createState() => _ViewProductPageState();
}

class _ViewProductPageState extends State<ViewProductPage> {

  List<dynamic> reviews = [];
  int quantity = 1;
  int cartItemCount = 0;
  Map<String, int> productQuantities = {};


  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> addToCart() async {
    double price = double.tryParse(widget.product['product_price']?.toString() ?? '0') ?? 0.0;
    double discountValue = double.tryParse(widget.product['product_dis_value']?.toString() ?? '0') ?? 0.0;
    double discountedPrice = price - discountValue;
    double totalPrice = discountedPrice * quantity; // Calculate total price

    try {
      final response = await ApiHelper().httpPost(
        'cart/store.php',
        {
          'customer_id': widget.id, // Replace with the actual customer ID
          'product_id': widget.product['product_id'],
          'product_qty': quantity.toString(), // Quantity of the product
          'product_price': totalPrice.toStringAsFixed(2),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success') {
          // Trigger homepage refresh

          // Show success message
          showTopMessage(context, "Product added to cart successfully!", Colors.green);

          // Optionally close the current page or dialog
          Navigator.pop(context);
        } else {
          showTopMessage(context, "Failed to add product to cart.", Colors.red);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Future<void> fetchReviews() async {
        try {
          final response = await ApiHelper().httpGet('ratings/index.php');
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            print("API Response: $data"); // Debugging line

            if (data['status'] == 'success') {
              setState(() {
                reviews = data['data']
                    .where((review) => review['product_id'].toString() == widget.product['product_id'].toString())
                    .toList();
                print("Updated Reviews in State: $reviews");
              });

              print("Current Product ID: ${widget.product['product_id']}");

              print("Filtered Reviews: $reviews"); // Debugging line
            }
          }
        } catch (e) {
          print("Error fetching reviews: $e");
        }
      }

  @override
  Widget build(BuildContext context) {
    double price = double.tryParse(widget.product['product_price']?.toString() ?? '0') ?? 0.0;
    double discountValue = double.tryParse(widget.product['product_dis_value']?.toString() ?? '0') ?? 0.0;
    double discountedPrice = price - discountValue;
    double totalPrice = discountedPrice * quantity;

    return Scaffold(
      body: Stack(
        children: [
          // Hero Product Image
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              child: widget.product['product_image']?.isNotEmpty ?? false
                  ? Image.network(
                ApiHelper().getImageUrl('products/${widget.product['product_image']}'),
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : Image.asset(
                "assets/images/cantain.jpg",
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: 40,
            left: 15,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          SizedBox(height: 30,),
          // Product Details Section
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(  // Added here
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.product['product_name'] ?? 'Unknown Product',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis, // Prevent text overflow
                            ),
                          ),
                          Row(
                            children: List.generate(5, (index) {
                              double rating = double.tryParse(widget.product['avg_rating'] ?? '0') ?? 0;
                              return Icon(
                                Icons.star,
                                size: 18,
                                color: index < rating.round() ? Colors.orange : Colors.grey.shade400,
                              );
                            }),
                          ),
                        ],
                      ),

                      SizedBox(height: 10),
                      // Price Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "₹${price.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            "₹${discountedPrice.toStringAsFixed(2)}",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      // Quantity Selector and Total Price
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.grey[200],
                            ),
                            width: 130,
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: quantity > 1
                                      ? () {
                                    setState(() {
                                      quantity--;
                                    });
                                  }
                                      : null,
                                  icon: Icon(Icons.remove, color: Colors.redAccent),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    '$quantity',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      quantity++;
                                    });
                                  },
                                  icon: Icon(Icons.add, color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 30),
                          Text(
                            "Total: ₹${totalPrice.toStringAsFixed(2)}",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                          ),
                        ],
                      ),
                      Divider(thickness: 1, height: 30),

                      // Product Description
                      Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        widget.product['product_description'] ?? 'No description available.',
                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                      ),

                      SizedBox(height: 10),
                      Text("Customer Reviews", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      // SizedBox(height: 10),

                      reviews.isEmpty
                          ? Center(child: Text("No reviews yet.", style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                        shrinkWrap: true,  // Added here
                        physics: NeverScrollableScrollPhysics(),  // Prevent nested scroll issues
                        itemCount: reviews.length,
                        itemBuilder: (context, index) {
                          final review = reviews[index];

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 10),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: review['customer_image'] != null && review['customer_image'].isNotEmpty
                                    ? NetworkImage(ApiHelper().getImageUrl('customers/${review['customer_image']}'))
                                    : null, // If no image, show icon instead
                                child: review['customer_image'] == null || review['customer_image'].isEmpty
                                    ? Icon(Icons.person, color: Colors.white) // Show icon if no image
                                    : null, // No child if image is present
                                backgroundColor: Colors.grey[300], // Background color when icon is shown
                              ),

                              title: Text(
                                review['customer_name'], // Show customer name
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: List.generate(
                                      5,
                                          (starIndex) => Icon(
                                        starIndex < int.parse(review['rating'])
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "Review: ${review['review_rating']} | Date: ${review['created_at']}",
                                    style: TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          );

                        },
                      ),

                      SizedBox(height: 20),

                      // Add to Cart Button in BottomNavigationBar
                    ],
                  ),
                ),
              ),
            ),
          ),

        ],
      ),

// Bottom Navigation Bar with Add to Cart Button
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, blurRadius: 10, spreadRadius: 3),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: addToCart,
          icon: Icon(Icons.shopping_cart),
          label: Text("Add to Cart", style: TextStyle(fontSize: 18)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orangeAccent,
            padding: EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),


    );
  }
}

void showTopMessage(BuildContext context, String message, Color backgroundColor) {
  final overlay = Overlay.of(context);

  // Declare overlayEntry as a local variable
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 40, // Adjust for status bar
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                offset: const Offset(0, 4),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  overlayEntry.remove(); // Use the declared overlayEntry
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // Show the overlay entry
  overlay.insert(overlayEntry);

  // Automatically remove the message after 3 seconds
  Future.delayed(const Duration(seconds: 3), () => overlayEntry.remove());
}