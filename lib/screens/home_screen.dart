import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello bro'),
      ),
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(hintText: 'Searc karo'),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  color: Colors.amber,
                ),
                SizedBox(
                  width: 8,
                ),
                Container(
                  width: 30,
                  height: 30,
                  color: Colors.amber,
                ),
                SizedBox(
                  width: 8,
                ),
                Container(
                  width: 30,
                  height: 30,
                  color: Colors.amber,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
