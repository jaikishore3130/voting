import 'package:flutter/material.dart';
import 'package:voting/screens/voter_login_screen.dart';
import 'package:voting/screens/candidate_login_screen.dart';
import 'package:voting/screens/ec_login_screen.dart';
import 'package:voting/widgets/custom_button.dart';

class AuthenticationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Select Your Role"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Logo (Centered)
              ClipRRect(
                borderRadius: BorderRadius.circular(20), // Rounded edges
                child: Image.asset(
                  'assets/images/logo.jpg',
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 30),

              // Voter Login Button
              CustomButton(
                text: "Voter Login",
                icon: Icons.how_to_vote,
                color: Colors.green,
                textSize: 18,
                width: 250,
                height: 60,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => VoterLoginScreen()),
                  );
                },
              ),
              SizedBox(height: 20),

              // Candidate Login Button
              CustomButton(
                text: "Candidate Login",
                icon: Icons.person_outline,
                color: Colors.orange,
                textSize: 18,
                width: 250,
                height: 60,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CandidateLoginScreen()),
                  );
                },
              ),
              SizedBox(height: 20),

              // EC Employee Login Button
              CustomButton(
                text: "EC Employee Login",
                icon: Icons.admin_panel_settings_outlined,
                color: Colors.redAccent,
                textSize: 18,
                width: 250,
                height: 60,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ECLoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
