import 'package:flutter/material.dart';
import 'package:rentmate/screens/home_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _ProfileDetailsCard(),
                      SizedBox(
                        height: 0,
                      ),
                      _QuickActionButtons(),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 16,
              ),
              Container(
                // decoration: BoxDecoration(color: Colors.white),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        'Personal Information',
                        style: TextStyle(fontSize: 18),
                      ),
                      onTap: () {
                        print('jjyjyyj');
                      },
                    ),
                    Divider(),
                    ListTile(
                      title: Text(
                        'orders',
                        style: TextStyle(fontSize: 18),
                      ),
                      onTap: () {},
                    ),
                    Divider(),
                    ListTile(
                      title: Text(
                        'Payment Details',
                        style: TextStyle(fontSize: 18),
                      ),
                      onTap: () {},
                    ),
                    Divider(),
                    ListTile(
                      title: Text(
                        'Location',
                        style: TextStyle(fontSize: 18),
                      ),
                      onTap: () {},
                    ),
                    Divider(),
                    ListTile(
                      title: Text(
                        'My Ads',
                        style: TextStyle(fontSize: 18),
                      ),
                      onTap: () {},
                    ),
                    Divider(),
                    ListTile(
                      title: Text(
                        'Languages',
                        style: TextStyle(fontSize: 18),
                      ),
                      onTap: () {},
                    ),
                    Divider(),
                    ListTile(
                      title: Text(
                        'privacy & Terms',
                        style: TextStyle(fontSize: 18),
                      ),
                      onTap: () {},
                    ),
                    Divider(),
                    ListTile(
                      title: Text(
                        'About',
                        style: TextStyle(fontSize: 18),
                      ),
                      onTap: () {},
                    ),
                    Divider(),
                    ListTile(
                      title: Text(
                        'Log Out',
                        style: TextStyle(fontSize: 18),
                      ),
                      onTap: () {},
                    ),
                    Divider(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButtons extends StatelessWidget {
  const _QuickActionButtons({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {},
                child: Column(
                  children: [Icon(Icons.shopping_cart), Text('orders')],
                ),
              ),
            ),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {},
                child: Column(
                  children: [Icon(Icons.favorite), Text('Favourites')],
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {},
                child: Column(
                  children: [
                    Icon(Icons.headset_mic_outlined),
                    Text('HelpCentre'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {},
                child: Column(
                  children: [
                    Icon(Icons.person),
                    Text('brokers'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  const _ProfileDetailsCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {},
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            children: [
              Stack(
                children: [
                  ClipOval(
                    child: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b2/Shri_Narendra_Modi%2C_Prime_Minister_of_India_%283x4_cropped%29.jpg/250px-Shri_Narendra_Modi%2C_Prime_Minister_of_India_%283x4_cropped%29.jpg',
                      fit: BoxFit.cover,
                      width: 100,
                      height: 100,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: Colors.grey,
                      ),
                      child: Center(
                        child: IconButton(
                          iconSize: 15,
                          color: Colors.white,
                          onPressed: () => {},
                          icon: Icon(Icons.edit),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Username',
                style: TextStyle(fontSize: 25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
