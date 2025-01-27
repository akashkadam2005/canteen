import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CategoryListPage extends StatefulWidget {
  @override
  _CategoryListPageState createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  late Future<List<Map<String, dynamic>>> categories;

  @override
  void initState() {
    super.initState();
    categories = fetchCategories();
  }

  // Fetch category data from the API
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final response = await http.get(Uri.parse('http://192.168.24.172/CanteenAutomation/api/category/index.php'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception('Failed to load categories');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Category List', style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),),
        backgroundColor: Colors.orangeAccent,
        elevation: 5.0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Implement back button functionality
            Navigator.pop(context);
          },
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orangeAccent, Colors.deepOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No categories available.'));
          }

          final categoryList = snapshot.data!;

          return GridView.builder(
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.1, // Aspect ratio to adjust the height and width of each item
            ),
            itemCount: categoryList.length,
            itemBuilder: (context, index) {
              final category = categoryList[index];
              return GestureDetector(
                onTap: () {
                  // Handle tap action, navigate to category details or another page
                },
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: category['category_image'] != null && category['category_image'].isNotEmpty
                            ? Image.network(
                          'http://192.168.24.172/CanteenAutomation/uploads/categories/${category['category_image']}',
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                            return Image.asset(
                              'assets/images/p1.jpg', // Default image asset path
                              height: 100,
                              fit: BoxFit.contain,
                            );
                          },
                        )
                            : Image.asset(
                          'assets/images/p1.jpg', // Default image path if the URL is empty or null
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                      ),



                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          category['category_name'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
