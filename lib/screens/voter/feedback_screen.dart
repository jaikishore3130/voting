import 'package:flutter/material.dart';

class FeedbackScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: "Raise an issue or give feedback to candidates",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              String feedback = _controller.text;
              if (feedback.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Feedback submitted!")));
                _controller.clear();
              }
            },
            child: Text("Submit"),
          ),
        ],
      ),
    );
  }
}
