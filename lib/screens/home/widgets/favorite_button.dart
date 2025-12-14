import 'package:flutter/material.dart';
import 'package:rentmate/screens/home/home_screen.dart';

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
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        padding: EdgeInsets.all(4),
      ),
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
