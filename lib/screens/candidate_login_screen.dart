import 'package:flutter/material.dart';
import 'package:voting/widgets/custom_textfield.dart';
import 'package:voting/widgets/custom_button.dart';

class CandidateLoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Candidate Login")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomTextField(hintText: "User ID"),
            CustomTextField(hintText: "Password", obscureText: true),
            CustomButton(
              text: "Login & Get OTP",
              icon: Icons.lock_open,
              onPressed: () {
                // Navigate to OTP screen
              },
            ),
          ],
        ),
      ),
    );
  }
}
