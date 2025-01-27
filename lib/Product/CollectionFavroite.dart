import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../Authantication/AuthUser.dart';

class Favorite extends StatefulWidget {
  final int customerId;
  const Favorite({super.key, required this.customerId});

  @override
  State<Favorite> createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  List<dynamic> favorites = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  // Fetch Favorites from API and filter by logged-in user
  Future<void> fetchFavorites() async {
    try {
      final response = await ApiHelper().httpGet('wishlist/index.php');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          final userFavorites = data['data']
              .where((item) => item['customer_id'] == widget.customerId.toString())
              .toList();
          setState(() {
            favorites = userFavorites;
          });
        } else {
          print("Error: ${data['message']}");
        }
      } else {
        print("Failed to fetch favorites. Status code: ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching favorites: $error");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Build a high-quality, visually appealing favorite item card
  Widget buildFavoriteCard(dynamic item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      // shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item['product_image'] != null
                  ?Image.network(
                ApiHelper().getImageUrl(
                    'products/${item['product_image']}'),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              )
                  : Image.asset(
                'assets/images/p1.jpg',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['product_name'] ?? "Unknown",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // Prevents text overflow
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "₹${item['product_price'] ?? '0.00'}",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${item['product_dis_value']}% off",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.favorite, color: Colors.redAccent, size: 28),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.grey[100],
      appBar: AppBar(
        // iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          'Favorites',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        // backgroundColor: Colors.orangeAccent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            // gradient: LinearGradient(
            //   colors: [Colors.orangeAccent, Colors.deepOrange],
            //   begin: Alignment.topLeft,
            //   end: Alignment.bottomRight,
            // ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.orangeAccent,
        ),
      )
          : favorites.isEmpty
          ? const Center(
        child: Text(
          "No favorites found",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      )
          : ListView.builder(
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          return buildFavoriteCard(favorites[index]);
        },
      ),
    );
  }
}
