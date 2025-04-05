import 'package:flutter/material.dart';
import 'package:voting/widgets/custom_textfield.dart';
import 'package:voting/widgets/custom_button.dart';

class ECLoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("EC Employee Login")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomTextField(hintText: "User ID"),
            CustomTextField(hintText: "Password", obscureText: true),
            CustomButton(
              text: "Login & Get OTP",
              icon: Icons.admin_panel_settings,
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
