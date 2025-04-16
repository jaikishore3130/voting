import 'package:flutter/material.dart';

class FeedbackScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Feedback", style: TextStyle(fontSize: 24)),
          SizedBox(height: 20),
          // Here you can display feedback forms or feedback list
        ],
      ),
    );
  }
}
