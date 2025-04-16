import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final double textSize;
  final double width;
  final double height;
  final VoidCallback onPressed;

  const CustomButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.textSize,
    required this.width,
    required this.height,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: Size(width, height),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 6,
        shadowColor: color.withOpacity(0.5),
      ),
      icon: Icon(icon, size: 24),
      label: Text(
        text,
        style: TextStyle(fontSize: textSize, fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
    );
  }
}
