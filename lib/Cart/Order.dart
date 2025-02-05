import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:canteen/Pages/HomeScreen.dart';
import 'package:canteen/Profile/Profile.dart';
import 'package:canteen/Profile/ProfileEdit.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../Authantication/AuthUser.dart';
import 'package:http/http.dart' as http;

import '../Product/ProductView.dart';
class OrderPage extends StatelessWidget {
  final List<dynamic> cartItems;
  final String name;
  final int customerId;
  final String email;
  final String phone;
  final String Address;
  final String image;
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  OrderPage({required this.cartItems, required this.customerId,
    required this.Address, required this.email, required this.phone,
    required this.image, required this.name, required this.toggleTheme, required this.isDarkMode});




  double _calculateSubtotal(List<dynamic> cartItems) {
    return cartItems.fold(0.0, (sum, item) {
      final double productPrice = double.tryParse(item['product_price'].toString()) ?? 0.0;
      final double discount = double.tryParse(item['product_dis_value'].toString()) ?? 0.0;
      final double discountedPrice = productPrice - discount;
      return sum + discountedPrice;
    });
  }

  Future<void> placeOrder(BuildContext context, List<dynamic> cartItems, int customerId, String Address) async {
    // API Endpoint
    const String apiUrl = "order/store.php"; // Endpoint for placing the order
    const String clearCartApi = "cart/removeCart.php"; // Endpoint for clearing the cart

    // Payment and Order Details
    int paymentMethod = 1; // Example: Cash on Delivery
    int paymentStatus = 1; // Example: Pending
    String shippingAddress = Address;

    // Calculate total price
    double totalPrice = _calculateSubtotal(cartItems);

    // Prepare Items List
    List<Map<String, dynamic>> items = cartItems.map((item) {
      final double productPrice = double.tryParse(item['product_price'].toString()) ?? 0.0;
      final double discount = double.tryParse(item['product_dis_value'].toString()) ?? 0.0;
      final double discountedPrice = productPrice - discount;
      final int quantity = int.tryParse(item['cart_product_qty'].toString()) ?? 1;

      return {
        "product_id": item['product_id'],
        "quantity": quantity,
        "price": discountedPrice, // Price per item after discount
      };
    }).toList();

    // Request Body for Order
    Map<String, dynamic> orderData = {
      "customer_id": customerId,
      "total_price": totalPrice,
      "order_date": DateTime.now().toIso8601String(),
      "order_status": 1, // Total price for all items
      "shipping_address": shippingAddress,
      "payment_method": paymentMethod,
      "payment_status": paymentStatus,
      "items": items,
    };
print(orderData);
    try {
      // Instantiate ApiHelper
      ApiHelper apiHelper = ApiHelper();

      // Place the order
      final response = await apiHelper.httpPost(apiUrl, orderData);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);

        if (responseData['status'] == "success") {
          // Show success message

          showTopMessage(
              context, "Order placed successfully!", Colors.green);
          // Clear the cart
          final clearCartResponse = await apiHelper.httpPost(clearCartApi, {
            "customer_id": customerId,
          });

          if (clearCartResponse.statusCode == 200) {
            var clearCartData = json.decode(clearCartResponse.body);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConfirmationPage(    name: name, phone: phone, address: Address,
                  email: email, image: image,  toggleTheme: toggleTheme,
                  isDarkMode: isDarkMode, customerId: customerId,),
              ),
            );
            if (clearCartData['status'] == "success") {
              // Show cart cleared message
              // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              //   content: Text("Cart cleared successfully!"),
              //   backgroundColor: Colors.blue,
              // ));
            } else {
              throw Exception("Failed to clear cart: ${clearCartData['message']}");
            }
          } else {
            throw Exception("Server Error: ${clearCartResponse.statusCode} while clearing cart.");
          }

          // Navigate to confirmation page

        } else {
          throw Exception("Failed to place order: ${responseData['message']}");
        }
      } else {
        throw Exception("Server Error: ${response.statusCode} while placing order.");
      }
    } catch (error) {
      // Handle Errors
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: $error"),
        backgroundColor: Colors.red,
      ));
    }
  }




  @override
  Widget build(BuildContext context) {

    double _calculateSubtotal(List<dynamic> cartItems) {
      return cartItems.fold(0.0, (sum, item) {
        final double productPrice = double.tryParse(item['product_price'].toString()) ?? 0.0;
        final double discount = double.tryParse(item['product_dis_value'].toString()) ?? 0.0;
        final double discountedPrice = productPrice - discount;
        return sum + discountedPrice;
      });
    }


    double totalDiscount = cartItems.fold(0.0, (sum, item) {
      final double discount = double.tryParse(item['product_dis_value'].toString()) ?? 0.0;
      return sum + discount;
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Order Summary',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orangeAccent, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 5,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.all(20),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent, Colors.orangeAccent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Icon
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(
                        Icons.celebration_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    // Texts
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "You saved ₹${totalDiscount.toStringAsFixed(2)}, ",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text: "including additional benefits.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Address Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Address',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        Address,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          // Add logic to change address
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>EditProfilePage(name: name,
                              address: Address, email: email, image: image, customerId: customerId, mobile: phone,
                            )));
                        },
                        child: Text(
                          'Change Address',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Cart Items Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Order Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                final double discount = double.tryParse(item['product_dis_value'].toString()) ?? 0.0; // Discount (ensure it's a double)
                final double productPrice = double.tryParse(item['product_price'].toString()) ?? 0.0; // Product price (ensure it's a double)
                final double discountedPrice = productPrice - discount; // Calculate discounted price
                return
                  Card(
                    margin: EdgeInsets.only(bottom: 12),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: item['product_image'] != ""
                                ? Image.network(
                              ApiHelper().getImageUrl('products/${item['product_image']}'),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          // Product Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Name
                           Row(
                             children: [
                               Text(
                                 item['product_name'],
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                                 style: TextStyle(
                                   fontSize: 14,
                                   fontWeight: FontWeight.bold,
                                 ),
                               ),
                               SizedBox(height: 4, width: 40,),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (discount > 0)
                                    Text(
                                      'Saved ₹${item['product_dis_value']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              )
                             ],
                           ),
                                // Quantity
                                Text(
                                  'Qty: ${item['cart_product_qty']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 6),
                                // Price Details
                                Row(
                                  children: [
                                    if (discount > 0) ...[
                                      Text(
                                        '₹${item['product_price']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                    ],
                                    Text(
                                      '₹${discountedPrice.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                // Discount Value

                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );

              },
            ),

            Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bill Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),

                      // Subtotal Calculation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal'),
                          Text('₹${_calculateSubtotal(cartItems).toStringAsFixed(2)}'),
                        ],
                      ),
                      SizedBox(height: 8),

                      // Taxes Calculation
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     Text('Taxes (18%)'),
                      //     Text('₹${(_calculateSubtotal(cartItems) * 0.18).toStringAsFixed(2)}'),
                      //   ],
                      // ),

                      Divider(),

                      // Total Amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₹${(_calculateSubtotal(cartItems)).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Place Order Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orangeAccent, Colors.deepOrange],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton(
                  onPressed: () => placeOrder(context, cartItems, customerId, Address),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Place Order',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class ConfirmationPage extends StatefulWidget {
  final String name;
  final int customerId;
  final String email;
  final String phone;
  final String address; // Changed to follow camelCase convention
  final String image;
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  // Constructor
  const ConfirmationPage({
    Key? key,
    required this.name,
    required this.customerId,
    required this.email,
    required this.phone,
    required this.address,
    required this.image, required this.toggleTheme, required this.isDarkMode,
  }) : super(key: key);
  @override
  _ConfirmationPageState createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // Play success sound
    _playSuccessSound();

    // Navigate to HomeScreen after 4 seconds
    Future.delayed(Duration(seconds: 4), () {
Navigator.push(context, MaterialPageRoute(builder: (context)=>HomeScreen(
    name: widget.name, id: widget.customerId, phone: widget.phone, address: widget.address,
    email: widget.email, image: widget.image,  toggleTheme: widget.toggleTheme,
  isDarkMode: widget.isDarkMode,)));
    });
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(
        AssetSource('images/notification1.mp3'), // Play the uploaded file
      );
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset(
          'assets/images/Animationorder.json',
          width: double.infinity, // Full width
          height: double.infinity, // Full height
          fit: BoxFit.contain, // Cover the entire screen
          repeat: false, // Play once
        ),
      ),
    );
  }
}

