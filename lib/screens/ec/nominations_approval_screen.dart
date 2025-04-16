import 'package:flutter/material.dart';

class NominationsApprovalScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Nominations Approval/Reject", style: TextStyle(fontSize: 24)),
          SizedBox(height: 20),
          // Here you can display a list of nominations with approve/reject functionality
        ],
      ),
    );
  }
}
