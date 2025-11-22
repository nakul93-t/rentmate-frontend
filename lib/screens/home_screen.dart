import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rent Mate'),
        actions: [
          TextButton(onPressed: () {}, child: Text('azhikode')),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Search bar + notifications
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        suffixIcon: Icon(Icons.search),
                        hintText: "Search karo",
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          // Category list
          SliverToBoxAdapter(
            child: SizedBox(
              height: 120,
              child: CaategoryList(),
            ),
          ),

          // Title text
          SliverPadding(
            padding: EdgeInsets.all(11),
            sliver: SliverToBoxAdapter(
              child: Text(
                "Recommendation",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Infinite Scrollable Grid
          SliverPadding(
            padding: EdgeInsets.all(15),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3 / 4,
              children: List.generate(20, (index) {
                return ItemWidget();
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class ItemWidget extends StatelessWidget {
  const ItemWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: FavoriteButton(),
          ),

          Center(
            child: Image.asset(
              'assets/images/dodge.png',
              width: 100,
            ),
          ),

          SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Text(
              "₹80000",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Text(
              "name",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            child: Text(
              "Description",
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    super.key,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.favorite),
      color: isFavorite ? Colors.red : Colors.grey,
      iconSize: 16,
      // padding: EdgeInsets.zero,
      constraints: BoxConstraints(),
      onPressed: () {
        setState(() {
          isFavorite = !isFavorite;
        });
      },
    );
  }
}

class CaategoryList extends StatelessWidget {
  const CaategoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(left: 15, right: 15),
      itemBuilder: (context, index) => SizedBox(
        child: Column(
          spacing: 4,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.blue,
              ),
              width: 80,
              height: 80,
            ),
            Text(
              'Cars',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
      ),
      itemCount: 20,
      separatorBuilder: (context, index) => SizedBox(
        width: 10,
      ),
      scrollDirection: Axis.horizontal,
    );
  }
}
