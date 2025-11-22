import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: TextStyle(fontSize: 29, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
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
            SizedBox(
              height: 10,
            ),
            Text(
              'All Chats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.separated(
                // physics: NeverScrollableScrollPhysics(),
                itemCount: 15,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    trailing: Column(
                      children: [
                        Text('12.13'),
                        SizedBox(
                          height: 5,
                        ),
                        CircleAvatar(
                          radius: 10,
                          child: Text(
                            '3',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    leading: CircleAvatar(child: Icon(Icons.abc)),
                    title: Text(
                      'Username',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Hi bro'),
                  );
                },
                separatorBuilder: (context, index) {
                  return Divider();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
