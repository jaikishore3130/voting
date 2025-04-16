import 'package:flutter/material.dart';
import 'package:voting/screens/voter_login_screen.dart';
import 'package:voting/screens/candidate_login_screen.dart';
import 'package:voting/screens/ec_login_screen.dart';
import 'package:voting/widgets/custom_button.dart';

class AuthenticationScreen extends StatelessWidget {
  const AuthenticationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF75B0FA), // Light modern background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rounded Square Logo
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30), // Rounded square
                    border: Border.all(color: Color(0xFF3B82F6), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                    image: DecorationImage(
                      image: AssetImage('assets/images/logo.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Title
                Text(
                  "Select Your Role",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 40),

                // Button Section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CustomButton(
                        text: "Voter Login",
                        icon: Icons.how_to_vote,
                        color: Color(0xFF10B981), // Emerald green
                        textSize: 18,
                        width: size.width * 0.8,
                        height: 55,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => VoterLoginScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                        text: "Candidate Login",
                        icon: Icons.person_outline,
                        color: Color(0xFFF59E0B), // Amber
                        textSize: 18,
                        width: size.width * 0.8,
                        height: 55,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CandidateLoginScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                        text: "EC Employee Login",
                        icon: Icons.admin_panel_settings_outlined,
                        color: Color(0xFFEF4444), // Red modern
                        textSize: 18,
                        width: size.width * 0.8,
                        height: 55,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
