import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:voting/screens/forgot_password_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:voting/screens/otp_screen.dart';
class ECLoginScreen extends StatefulWidget {
  @override
  _ECLoginScreenState createState() => _ECLoginScreenState();
}

class _ECLoginScreenState extends State<ECLoginScreen> {
  // Move all your current variables and functions from ECLoginScreen here


  final TextEditingController aadhaarController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController captchaController = TextEditingController();

  final List<TextEditingController> otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> otpFocusNodes = List.generate(6, (_) => FocusNode());

  String? maskedPhone = "+91 XXXXX X1234";
  String generatedOtp = "";
  bool isLoading = false;
  bool otpSent = false;
  String generatedCaptcha = "";

  @override
  void initState() {
    super.initState();
    generateCaptcha();
  }

  void generateCaptcha() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final codeUnits = List.generate(
        6, (index) => chars[random.nextInt(chars.length)]);
    setState(() {
      generatedCaptcha = codeUnits.join();
      captchaController.clear();
    });
  }

  bool isValidAge(String dob) {
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)));
  }



  Future<Map<String, dynamic>?> fetchECData(String aadhaar) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('EC_EMPLOYEES')
          .doc(aadhaar)
          .get();


      if (doc.exists) {
        return doc.data();
      } else {
        print("No record found for this Aadhaar!");
      }
    } catch (e) {
      print("Firestore Error: $e");
    }
    return null;
  }


  void validateInputs() async {
    final aadhaar = aadhaarController.text.trim();
    final password = passwordController.text.trim();
    final captcha = captchaController.text.trim();

    if (aadhaar.length != 12)
      return _showMessage("Enter a valid 12-digit Aadhaar number");
    if (password.isEmpty) return _showMessage("Password cannot be empty");
    if (captcha != generatedCaptcha) {
      _showMessage("Incorrect CAPTCHA! Try Again");
      generateCaptcha();
      return;
    }

    setState(() => isLoading = true);
    final data = await fetchECData(aadhaar);

    if (data == null) {
      _showMessage("No record found for this Aadhaar!");
      generateCaptcha();
      return setState(() => isLoading = false);
    }

    if (data['password'] != password) {
      _showMessage("Incorrect password!");
      generateCaptcha();
      return setState(() => isLoading = false);
    }

    String? phone =
    data['phone']!= null ?"+91${data['phone']}":null;
    int? age = int.tryParse(data['age'].toString());

    if (phone == null || age == null) {
      _showMessage("Incomplete candidate record.");
      return setState(() => isLoading = false);
    }

    if (age < 18) {
      _showMessage("You must be 18+ to login.");
      return setState(() => isLoading = false);
    }

    // If validation is successful, navigate to OTP screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OtpScreen(
              phoneNumber: phone,
              aadhaarNumber: aadhaar,
              userType: 'ec_employee', // Assuming the user is a candidate
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    return Scaffold(
      appBar: AppBar(
        title: Text("Election Commission Login",textAlign: TextAlign.center,),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: buildLoginForm(screenHeight, screenWidth),
      backgroundColor: Colors.indigo,
    );
  }

  Widget buildLoginForm(double screenHeight, double screenWidth) {
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.06, vertical: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade200,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              Lottie.asset(
                'assets/animations/login_animation.json',
                height: screenHeight * 0.3,
              ),
              const SizedBox(height: 20),

              buildStyledTextField("Aadhaar Number", aadhaarController,
                  maxLength: 12,
                  keyboardType: TextInputType.number,
                  icon: Icons.credit_card),
              const SizedBox(height: 10),
              buildStyledTextField("Password", passwordController,
                  obscureText: true, icon: Icons.lock),
              const SizedBox(height: 10),
              buildCaptchaRow(),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: validateInputs,
                icon: const Icon(Icons.verified, color: Colors.white),
                label: isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Verify",style: const TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
              ),

              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ResetPasswordRequestScreen(userType: 'ec',)
                        ));
                  },
                  child: Text(
                    "Forgot Password?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget buildStyledTextField(String hint,
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
        prefixIcon: icon != null ? Icon(icon, color: Colors.indigo.shade300) : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        hintText: hint,
        counterText: '',
        hintStyle: const TextStyle(color: Colors.black54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget buildCaptchaRow() {
    return Row(
      children: [
        // CAPTCHA Input (60%)
        Expanded(
          flex: 6,
          child: buildStyledTextField(
              "CAPTCHA", captchaController, icon: Icons.security),
        ),
        const SizedBox(width: 10),

        // CAPTCHA Image (30%)
        Expanded(
          flex: 4,
          child: Container(
            height: 50,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12, width: 0.5),
            ),
            child: CustomPaint(
              painter: CaptchaPainter(generatedCaptcha),
              child: Container(),
            ),
          ),
        ),

        // Refresh Icon (10%)
        Expanded(
          flex: 1,
          child: IconButton(
            onPressed: generateCaptcha,
            icon: const Icon(Icons.refresh, color: Colors.blue),
          ),
        ),
      ],
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
    List<String> fontFamilies = ['Roboto', 'Courier', 'Times New Roman', 'Arial', 'Georgia'];

    for (int i = 0; i < captcha.length; i++) {
      textPainter.text = TextSpan(
        text: captcha[i],
        style: textStyle.copyWith(
          fontSize: 24 + random.nextInt(4).toDouble(),
          color: Colors.primaries[random.nextInt(Colors.primaries.length)],
          fontFamily: fontFamilies[random.nextInt(fontFamilies.length)], // Random font
          fontWeight: FontWeight.values[random.nextInt(FontWeight.values.length)], // Random weight
          fontStyle: random.nextBool() ? FontStyle.italic : FontStyle.normal, // Random style
        ),
      );
      textPainter.layout();
      final x = i * size.width / captcha.length + random.nextDouble() * 2;
      final y = random.nextDouble() * 10;
      textPainter.paint(canvas, Offset(x, y));
    }

    // Optional: Add some noise lines
    for (int i = 0; i < 17; i++) {
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
