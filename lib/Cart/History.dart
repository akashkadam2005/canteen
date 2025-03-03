import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../Authantication/AuthUser.dart';
import '../Pages/HomeScreen.dart';
import 'OrderShow.dart';
// Import your HomeScreen

class HistoryPage extends StatefulWidget {
  final int customerId;
  final String name;
  final String phone;
  final String address;
  final String email;
  final String image;
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const HistoryPage({
    Key? key,
    required this.customerId,
    required this.name,
    required this.phone,
    required this.address,
    required this.email,
    required this.image,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final response = await ApiHelper().httpGet('order/index.php?customer_id=${widget.customerId}');

      if (response.statusCode == 200) {
        setState(() {
          orders = List.from(json.decode(response.body).reversed);;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching data: $e");
    }
  }

  String getPaymentMethod(String method) {
    switch (method) {
      case "1":
        return "Paid";
      case "2":
        return "Unpaid";
      default:
        return "Unknown";
    }
  }

  String _getOrderStatusText(String? status) {
    switch (status) {
      case "1":
        return "Pending";
      case "2":
        return "Processing";
      case "3":
        return "Completed";
      default:
        return "Unknown";
    }
  }

  Color _getOrderStatusColor(String? status) {
    switch (status) {
      case "1":
        return Colors.orange; // Pending
      case "2":
        return Colors.blue; // Out For Delivery
      case "3":
        return Colors.green; // Delivered
      default:
        return Colors.grey; // Unknown Status
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to HomeScreen and clear all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              name: widget.name,
              id: widget.customerId,
              phone: widget.phone,
              address: widget.address,
              email: widget.email,
              image: widget.image,
              toggleTheme: widget.toggleTheme,
              isDarkMode: widget.isDarkMode,
            ),
          ),
              (route) => false, // Clear all routes
        );
        return false; // Prevent default back button behavior
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Order History"),
          centerTitle: true,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : orders.isEmpty
            ? const Center(child: Text("No Orders Found"))
            : ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderShow(order: order),
                  ),
                );
              },
              child: Card(
                margin: const EdgeInsets.all(12),
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Order ${order['order_id']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.deepOrange,
                            ),
                          ),
                          Text(
                            order['order_date'],
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      const Divider(),
                      const SizedBox(height: 10),
                      // Order Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total: ₹${order['total_price']}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: _getOrderStatusColor(order['order_status']),
                                size: 20,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _getOrderStatusText(order['order_status']),
                                style: TextStyle(
                                  color: _getOrderStatusColor(order['order_status']),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}