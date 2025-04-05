import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final double textSize;
  final double width;
  final double height;

  CustomButton({
    required this.text,
    required this.icon,
    required this.onPressed,
    this.color = Colors.blueAccent, // Default color
    this.textSize = 16, // Default text size
    this.width = 150, // Default width
    this.height = 50, // Default height
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: TextStyle(fontSize: textSize, color: Colors.white),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
