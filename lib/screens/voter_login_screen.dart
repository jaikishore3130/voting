import 'dart:math';
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'otp_screen.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';


class VoterLoginScreen extends StatefulWidget {
  @override
  _VoterLoginState createState() => _VoterLoginState();
}

class _VoterLoginState extends State<VoterLoginScreen> {
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();


  bool isLoading = false;

  String generatedCaptcha = "";



  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }



// Resend OTP function





  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _generateCaptcha() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    final random = Random();
    generatedCaptcha = String.fromCharCodes(
      List.generate(6, (index) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
    _captchaController.clear();
    setState(() {});
  }


  Future<Map<String, dynamic>?> _getVoterDetails(String aadhaar) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('voters')
          .doc(aadhaar)
          .get();

      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      print("Firestore Error: $e");
      return null;
    }
  }

  bool _is18OrOlder(String dob) {
    try {
      DateTime birthDate = DateTime.parse(dob);
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age >= 18;
    } catch (e) {
      return false;
    }
  }

  void verifyInputs() async {
    if (_aadhaarController.text.length != 12) {
      _showMessage("Enter a valid 12-digit Aadhaar number");
      _generateCaptcha();
      return;
    }

    if (_captchaController.text != generatedCaptcha) {
      _showMessage("Incorrect CAPTCHA! Try Again");
      _generateCaptcha();
      return;
    }

    setState(() => isLoading = true);

    Map<String, dynamic>? voterData =
    await _getVoterDetails(_aadhaarController.text);
    if (voterData != null) {
      String? phoneNumber =
      voterData['phone'] != null ? "+91${voterData['phone']}" : null;
      String? dob = voterData['dob'];

      if (phoneNumber != null && dob != null) {
        if (!_is18OrOlder(dob)) {
          _showMessage("You must be 18+ to vote!");
          setState(() => isLoading = false);
          return;
        }




          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                phoneNumber: phoneNumber,
                aadhaarNumber: _aadhaarController.text,  // Pass the Aadhaar number
                userType: 'voter',  // Adjust this based on the user type (voter, candidate, ec_employee)
              ),
            ),
          );



      } else {
        _showMessage("Invalid Aadhaar details! Contact EC.");
      }
    } else {
      _showMessage("Aadhaar not linked to any valid phone number! Contact EC.");
    }

    setState(() => isLoading = false);
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Voter Login")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _buildAadhaarScreen(context),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAadhaarScreen(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/login_animation.json',
              height: screenWidth * 0.5, // responsive
            ),
            const SizedBox(height: 30),

            // Aadhaar Field
            buildStyledTextField(
              "Aadhaar Number",
              _aadhaarController,
              maxLength: 12,
              keyboardType: TextInputType.number,
              icon: Icons.credit_card,
            ),
            const SizedBox(height: 20),

            // CAPTCHA Section
            Row(
              children: [
                // CAPTCHA Input (60%)
                Expanded(
                  flex: 6,
                  child: buildStyledTextField(
                    "CAPTCHA",
                    _captchaController,
                    icon: Icons.security,
                  ),
                ),
                const SizedBox(width: 10),

                // CAPTCHA Display (30%)
                // CAPTCHA Display (30%)
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,// White background
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black26, width: 0.5), // Border color and width
                    ),
                    child: CustomPaint(
                      painter: CaptchaPainter(generatedCaptcha),
                      child: Container(),
                    ),
                  ),
                ),


                // Refresh Button (10%)
                Expanded(
                  flex: 1,
                  child: IconButton(
                    onPressed: _generateCaptcha,
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Verify Button
            Center(
              child: ElevatedButton.icon(
                onPressed: verifyInputs,
                icon: const Icon(Icons.verified, color: Colors.white),
                label: const Text("Verify"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[400],
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStyledTextField(
      String hint,
      TextEditingController controller, {
        bool obscureText = false,
        int? maxLength,
        TextInputType? keyboardType,
        IconData? icon,
      }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon, color: Colors.blueGrey) : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        hintText: hint,
        counterText: '',
        hintStyle: const TextStyle(color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
class CaptchaPainter extends CustomPainter {
  final String captcha;

  CaptchaPainter(this.captcha);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random();
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < captcha.length; i++) {
      textPainter.text = TextSpan(
        text: captcha[i],
        style: textStyle.copyWith(
          fontSize: 24 + random.nextInt(4).toDouble(),
          color: Colors.primaries[random.nextInt(Colors.primaries.length)],
        ),
      );

      textPainter.layout();
      final x = i * size.width / captcha.length + random.nextDouble() * 2;
      final y = random.nextDouble() * 10;
      textPainter.paint(canvas, Offset(x, y));
    }

    // Optional: Add some noise lines
    for (int i = 0; i < 5; i++) {
      final linePaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
