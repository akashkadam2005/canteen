import 'package:canteen/Cart/Order.dart';
import 'package:canteen/Product/ProductView.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../Authantication/AuthUser.dart';
import 'History.dart';

class CartScreen extends StatefulWidget {
  final int id;
  final String Address;
  final String email;
  final String phone;
  final String image;
  final String name;
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final Function(int) onCartUpdated;
  final Map<String, int> productQuantities;

  CartScreen({ required this.id,
    required this.onCartUpdated,
    required this.productQuantities,
    required this.Address,
    required this.email, required this.phone,
    required this.image, required this.name, required this.toggleTheme, required this.isDarkMode,  });

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Map<String, int> productQuantities;
  List<dynamic> cartItems = [];


  @override
  void initState() {
    super.initState();
    productQuantities = widget.productQuantities; // Initialize from widget prop
    fetchCartData();
  }


  Future<void> fetchCartData() async {
    try {
      final response = await ApiHelper().httpGet('cart/index.php');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final filteredCartItems = data['data']
              .where((item) => item['customer_id'] == widget.id.toString())
              .toList();

          setState(() {
            cartItems = filteredCartItems;
          });
          for (var item in filteredCartItems) {
            String productId = item['cart_product_id'].toString();
            int quantity = int.parse(item['cart_product_qty'].toString());
            productQuantities[productId] = quantity;
          }

          widget.onCartUpdated(cartItems.length); // Notify parent immediately
        }
      } else {
        print('Failed to load cart items: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching cart data: $e');
    }
  }

  Future<void> removeCartItem(int cartId, int index) async {
    final removedItem = cartItems[index];
    final removedProductId = removedItem['cart_product_id'].toString();

    setState(() {
      cartItems.removeAt(index);
      productQuantities[removedProductId] = 0; // Set quantity to 0 when removed
      widget.onCartUpdated(cartItems.length); // Notify parent immediately
    });

    try {
      final response = await ApiHelper().httpDelete(
        'cart/deleteCart.php',
        {'cart_id': cartId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          showTopMessage(context, "Item removed from cart", Colors.green);
        } else {
          revertCartChanges(index, removedItem, removedProductId);
          showTopMessage(context, "Failed to remove item", Colors.red);
        }
      } else {
        revertCartChanges(index, removedItem, removedProductId);
      }
    } catch (e) {
      revertCartChanges(index, removedItem, removedProductId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing cart item')),
      );
    }

    // Navigator.pop(context, cartItems.length); // Pass updated cart count
  }

  void revertCartChanges(int index, Map<String, dynamic> removedItem, String removedProductId) {
    setState(() {
      cartItems.insert(index, removedItem); // Restore the removed item
      productQuantities[removedProductId] = 1; // Reset quantity to original value
      widget.onCartUpdated(cartItems.length); // Notify parent
    });
  }






  // Future<void> removeCartItem(int cartId, int index) async {
  //   final removedItem = cartItems[index];
  //   setState(() {
  //     cartItems.removeAt(index);
  //     productQuantities.clear();
  //   });
  //
  //   try {
  //     final response = await ApiHelper().httpDelete(
  //       'cart/deleteCart.php',
  //       {'cart_id': cartId},
  //     );
  //
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //
  //       if (data['status'] == 'success') {
  //         widget.onCartUpdated(cartItems.length); // Notify parent screen
  //         showTopMessage(context, "Cart removed successfully", Colors.green);
  //       } else {
  //         setState(() {
  //           cartItems.insert(index, removedItem);
  //           productQuantities.clear();
  //         });
  //         showTopMessage(context, "Failed to remove item", Colors.red);
  //       }
  //     } else {
  //       setState(() {
  //         cartItems.insert(index, removedItem);
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       cartItems.insert(index, removedItem);
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Error removing cart item')),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Added Cart',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 5.0,
        centerTitle: true,
        flexibleSpace: Container(
          // Uncomment the following lines to add a gradient background
          // decoration: BoxDecoration(
          //   gradient: LinearGradient(
          //     colors: [Colors.orangeAccent, Colors.deepOrange],
          //     begin: Alignment.topLeft,
          //     end: Alignment.bottomRight,
          //   ),
          // ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryPage(customerId: widget.id,
                  name: widget.name,email: widget.email,image: widget.image,address: widget.Address, phone: widget.phone, toggleTheme: widget.toggleTheme, isDarkMode: widget.isDarkMode,)),
              );
            },
          ),
        ],
      ),

      body: cartItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.orangeAccent,
            ),
            SizedBox(height: 16),
            Text(
              'Your cart is empty!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Start adding items to your cart now.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
               Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding:
                EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Shop Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];

                return Card(
                  margin:
                  EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: item['product_image'] != ""
                              ? Image.network(
                            ApiHelper().getImageUrl('products/${item['product_image']}'),
                            // 'http://192.168.242.172/CanteenAutomation/uploads/products/${item['product_image']}',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: Icon(Icons.image,
                                size: 40, color: Colors.grey),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['product_name'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  // color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Price: ₹${item['product_price']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  // color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Discount: ₹${item['product_dis_value']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              'Qty: ${item['cart_product_qty']}',
                              style: TextStyle(
                                fontSize: 14,
                                // color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => removeCartItem(
                                  int.parse(item['cart_id'].toString()),
                                  index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Remove',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Proceed to Checkout Button
        Padding(padding: EdgeInsets.all(10),
        child:   Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orangeAccent, Colors.deepOrange],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderPage(
                    cartItems: cartItems,
                    // totalPrice: 1,
                    customerId:widget.id,
                    Address: widget.Address, email: widget.email, phone: widget.phone,
                    image:widget.image, name: widget.name,
                    toggleTheme: widget.toggleTheme,
                    isDarkMode: widget.isDarkMode,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent, // Ensures gradient visibility
              shadowColor: Colors.transparent, // Removes shadow
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Proceed to Checkout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),)


        ],
      ),
    );
  }
}