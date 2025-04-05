import 'package:flutter/material.dart';

class OtpScreen extends StatefulWidget {
  final String role;

  OtpScreen({required this.role, required String phoneNumber, required String otp});

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  TextEditingController aadhaarController = TextEditingController();
  TextEditingController userIdController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  void verifyAndProceed() {
    if (widget.role == "Voter" && aadhaarController.text.isNotEmpty) {
      // Simulate sending OTP
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EnterOtpScreen()),
      );
    } else if ((widget.role == "Candidate" || widget.role == "EC Employee") &&
        userIdController.text.isNotEmpty &&
        passwordController.text.isNotEmpty) {
      // Simulate sending OTP
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EnterOtpScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Enter Details")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.role == "Voter") ...[
              TextField(
                controller: aadhaarController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Enter Aadhaar Number"),
              ),
            ] else ...[
              TextField(
                controller: userIdController,
                decoration: InputDecoration(labelText: "Enter User ID"),
              ),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Enter Password"),
              ),
            ],
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: verifyAndProceed,
              child: Text("Verify & Proceed"),
            ),
          ],
        ),
      ),
    );
  }
}

class EnterOtpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Enter OTP")),
      body: Center(child: Text("OTP Screen Placeholder")),
    );
  }
}
