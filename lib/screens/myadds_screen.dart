import 'package:flutter/material.dart';

class MyAddsListPage extends StatelessWidget {
  MyAddsListPage({super.key});

  // -------- Demo Data --------
  final List<Map<String, dynamic>> demoAdds = [
    {
      "title": "Gaming Laptop",
      "price": "\$1200",
      "imageUrl":
          "https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=600",
      "views": 540,
      "likes": 120,
      "isExpired": true,
    },

    {
      "title": "Gaming Laptop",
      "price": "\$1200",
      "imageUrl":
          "https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=600",
      "views": 540,
      "likes": 120,
      "isExpired": true,
    },
    {
      "title": "Gaming Laptop",
      "price": "\$1200",
      "imageUrl":
          "https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=600",
      "views": 540,
      "likes": 120,
      "isExpired": true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Adds")),
      body: ListView.builder(
        itemCount: demoAdds.length,
        itemBuilder: (context, index) {
          final item = demoAdds[index];
          return _buildAddCard(item);
        },
      ),
    );
  }

  // -------- Card Widget --------
  Widget _buildAddCard(Map<String, dynamic> ad) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              ad["imageUrl"],
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ad["title"],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  ad["price"],
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),

                const SizedBox(height: 10),

                // Views & Likes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.visibility, size: 18),
                        const SizedBox(width: 4),
                        Text("${ad["views"]}"),

                        const SizedBox(width: 20),

                        const Icon(Icons.favorite_border, size: 18),
                        const SizedBox(width: 4),
                        Text("${ad["likes"]}"),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "EXPIRED",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ------ Expired section ------
                if (ad["isExpired"]) ...[
                  Align(
                    alignment: AlignmentGeometry.centerRight,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "This ad was expired. If you sold it, please mark it as sold",
                    style: TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Text("Mark as sold"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Text("Republish"),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
