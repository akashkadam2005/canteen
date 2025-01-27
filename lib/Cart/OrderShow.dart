import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

import '../Authantication/AuthUser.dart';
class OrderShow extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderShow({
    Key? key,
    required this.order,
  }) : super(key: key);

  String getPaymentMethod(String method) {
    switch (method) {
      case "1":
        return "Cash On Delivery";
      case "2":
        return "QR Code Payment";
      case "3":
        return "Merchant Pay";
      default:
        return "Unknown";
    }
  }

  String getPaymentStatus(String status) {
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

  // Function to create the content for printing
  Future<void> _printOrderDetails(BuildContext context) async {
    final document = await createPdfDocument();

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => document.save(),
    );
  }

  // Create a PDF document
  Future<pw.Document> createPdfDocument() async {
    final pdf = pw.Document();

    // Add your content here
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text("Order ID: ${order['order_id']}"),
              pw.Text("Customer Name: ${order['customer_name']}"),
              pw.Text("Order Date: ${order['order_date']}"),
              pw.Text("Shipping Address: ${order['shipping_address']}"),
              pw.Text("Payment Method: ${getPaymentMethod(order['payment_method'])}"),
              pw.Text("Payment Status: ${getPaymentStatus(order['payment_status'])}"),
              pw.Text("Total Price: ₹${order['total_price']}"),
            ],
          );
        },
      ),
    );

    return pdf;
  }



  Future<void> _submitRating(BuildContext context, dynamic item, double rating, String review) async {
    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a rating before submitting.")),
      );
      return;
    }

    try {
      // Prepare data payload
      final data = {
        "rating_id": "", // Auto-generated by the backend
        "order_id": order['order_id'],
        "product_id": item['product_id'],
        "customer_id": order['customer_id'],
        "rating": rating.toString(),
        "review_rating": review,
        "created_at": DateTime.now().toIso8601String(),
      };

      // Make API call
      final apiHelper = ApiHelper();
      final response = await apiHelper.httpPost('ratings/store.php', data);

      if (response.statusCode == 200) {
        Navigator.pop(context); // Close modal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Rating and review submitted successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to submit rating. Please try again.")),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $error")),
      );
    }
  }

  Future<void> _showRatingModal(BuildContext context, dynamic item) async {
    double selectedRating = 0;
    final TextEditingController reviewController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Rate ${item['product_name']}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                selectedRating = rating;
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: reviewController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Write a review",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _submitRating(context, item, selectedRating, reviewController.text);
              },
              style: ElevatedButton.styleFrom(
                // backgroundColor: Colors.,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Submit Your Experience",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final orderItems = order['order_items'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
        // backgroundColor: Colors.deepOrange,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "Items in Order",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: orderItems.length,
              itemBuilder: (context, index) {
                final item = orderItems[index];
                return GestureDetector(
                  onTap: () => _showRatingModal(context, item),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 5,
                    shadowColor: Colors.deepOrange.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(15),
                          ),
                          child: Image.network(
                            ApiHelper().getImageUrl("products/${item['product_image']}"),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['product_name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Qty: ${item['quantity']}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Price: ₹${item['price']}",
                                  style: const TextStyle(
                                    color: Colors.green,
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
                );
              },
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 10,
              shadowColor: Colors.deepOrange.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(
                    //   "Order ID: ${index+1}",
                    //   style: const TextStyle(
                    //     fontWeight: FontWeight.bold,
                    //     fontSize: 18,
                    //     color: Colors.deepOrangeAccent,
                    //   ),
                    // ),
                    const SizedBox(height: 12),
                    // Text(
                    //   "Customer Name: ${order['customer_name']}",
                    //   style: const TextStyle(fontSize: 16),
                    // ),
                    const SizedBox(height: 12),
                    Text(
                      "Order Date: ${order['order_date']}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Shipping Address: ${order['shipping_address']}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Payment Method: ${getPaymentMethod(order['payment_method'])}",
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Payment Status: ${getPaymentStatus(order['payment_status'])}",
                      style: TextStyle(
                        fontSize: 16,
                        color: order['payment_status'] == "3" ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Total Price: ₹${order['total_price']}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.deepOrangeAccent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            // Save Button Action
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrangeAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Close",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _printOrderDetails(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Save As PDF",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
