import 'package:flutter/material.dart';

class EcEmployeeDashboard extends StatelessWidget {
  final String aadhaarNumber;

  const EcEmployeeDashboard({required this.aadhaarNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("EC Employee Dashboard"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the Aadhaar number
            Text(
              "Aadhaar Number: $aadhaarNumber",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Dashboard Features
            Text(
              "Dashboard Features:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ListTile(
              title: Text("Approve/Reject Nominations"),
              leading: Icon(Icons.check_circle),
              onTap: () {
                // Navigate to Nomination Management Screen (you can add this screen later)
              },
            ),
            ListTile(
              title: Text("View Election Details"),
              leading: Icon(Icons.assignment),
              onTap: () {
                // Navigate to Election Details Screen (you can add this screen later)
              },
            ),
            ListTile(
              title: Text("View Candidate History"),
              leading: Icon(Icons.history),
              onTap: () {
                // Navigate to Candidate History Screen (you can add this screen later)
              },
            ),
            ListTile(
              title: Text("View Voter Feedback"),
              leading: Icon(Icons.feedback),
              onTap: () {
                // Navigate to Feedback Screen (you can add this screen later)
              },
            ),
            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Perform logout or other actions here
                },
                child: Text("Logout", style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
