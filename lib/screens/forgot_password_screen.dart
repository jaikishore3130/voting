import 'package:lottie/lottie.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voting/screens/otp_screen.dart';

class ResetPasswordRequestScreen extends StatefulWidget {
  final String userType;

  const ResetPasswordRequestScreen({super.key, required this.userType});

  @override
  State<ResetPasswordRequestScreen> createState() => _ResetPasswordRequestScreenState();
}

class _ResetPasswordRequestScreenState extends State<ResetPasswordRequestScreen> {
  final TextEditingController aadhaarController = TextEditingController();
  final TextEditingController captchaController = TextEditingController();

  String? phone;
  String generatedCaptcha = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    generateCaptcha();
  }

  void generateCaptcha() {
    final rand = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    generatedCaptcha = List.generate(5, (_) => chars[rand.nextInt(chars.length)]).join();
    setState(() {});
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String?> fetchPhone(String aadhaar) async {
    if (widget.userType == 'candidate') {
      final partySnapshots = await FirebaseFirestore.instance.collection('LOK_SABHA').get();
      for (final party in partySnapshots.docs) {
        final doc = await FirebaseFirestore.instance
            .collection('LOK_SABHA')
            .doc(party.id)
            .collection('candidates')
            .doc(aadhaar)
            .get();
        if (doc.exists) {
          final data = doc.data();
          return data?['phone'] != null ? "+91${data?['phone']}" : null;
        }
      }
    } else if (widget.userType == 'ec') {
      final doc = await FirebaseFirestore.instance.collection('EC_EMPLOYEES').doc(aadhaar).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['phone'] != null ? "+91${data?['phone']}" : null;
      }
    }
    return null;
  }

  void handleSendOtp() async {
    final aadhaar = aadhaarController.text.trim();
    final enteredCaptcha = captchaController.text.trim();

    if (aadhaar.length != 12) {
      generateCaptcha();
      return _showMessage("Enter valid 12-digit Aadhaar");
    }
    if (enteredCaptcha != generatedCaptcha) {
      generateCaptcha();
      return _showMessage("Incorrect CAPTCHA");
    }
    setState(() => isLoading = true);
    final fetchedPhone = await fetchPhone(aadhaar);

    if (fetchedPhone == null) {
      _showMessage("User not found");
      generateCaptcha();
      return setState(() => isLoading = false);
    }

    setState(() => isLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          phoneNumber: fetchedPhone,
          aadhaarNumber: aadhaar,
          userType: '${widget.userType}_reset',
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lottie Animation
            Center(
              child: Lottie.asset('assets/animations/forgot.json', // replace with your chosen one
                height: 180,
                repeat: true,
                animate: true,
              ),
            ),
            const SizedBox(height: 10),

            // Title & Subtitle with animation
            AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Forgot your password?",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Enter Aadhaar and complete CAPTCHA to get OTP for reset.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Aadhaar Input
            TextField(
              controller: aadhaarController,
              maxLength: 12,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Aadhaar Number",
                prefixIcon: const Icon(Icons.credit_card),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 25),

            // CAPTCHA row
            Row(
              children: [
                Expanded(
                  child: TextField(

                    controller: captchaController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.security),
                      labelText: "Enter CAPTCHA",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                // CAPTCHA image
                const SizedBox(width: 10),
                Container(
                  height: 50,
                  width: 120,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 0.5),
                  ),
                  child: CustomPaint(
                    painter: CaptchaPainter(generatedCaptcha),
                    child: const SizedBox.expand(),
                  ),
                ),


                // CAPTCHA input


                // Refresh icon
                IconButton(
                  onPressed: generateCaptcha,
                  icon: const Icon(Icons.refresh),
                  tooltip: "Refresh CAPTCHA",
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Send OTP Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : handleSendOtp,
                icon: const Icon(Icons.send, color: Colors.white),
                label: isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  "Send OTP",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white, // Ensures white text/icon by default
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

          ],
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

    final textStyle = const TextStyle(
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
          fontSize: 24 + random.nextInt(5).toDouble(),
          color: Colors.primaries[random.nextInt(Colors.primaries.length)],
        ),
      );

      textPainter.layout();
      final x = i * size.width / captcha.length + random.nextDouble() * 4;
      final y = random.nextDouble() * 15;
      textPainter.paint(canvas, Offset(x, y));
    }

    for (int i = 0; i < 15; i++) {
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
