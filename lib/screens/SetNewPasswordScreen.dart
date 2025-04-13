import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:voting/screens/candidate_login_screen.dart';

class SetNewPasswordScreen extends StatefulWidget {
  final String aadhaarNumber;
  final String userType;

  const SetNewPasswordScreen({
    required this.aadhaarNumber,
    required this.userType,
  });

  @override
  _SetNewPasswordScreenState createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _animationController;
  late Animation<double> _animation;

  bool _isLoading = false;
  String _generatedCaptcha = '';

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(_animationController);
    _animationController.repeat(reverse: true);
  }

  void _generateCaptcha() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    _generatedCaptcha = List.generate(5, (index) => chars[rand.nextInt(chars.length)]).join();
    setState(() {});
  }

  bool _isStrongPassword(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  }

  Future<void> _updatePassword() async {
    String newPassword = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();
    String captchaInput = _captchaController.text.trim();

    if (newPassword != confirmPassword) {
      _showSnackBar("Passwords do not match");
      _generateCaptcha();
      return;
    }

    if (!_isStrongPassword(newPassword)) {
      _showSnackBar("Password not strong enough");
      _generateCaptcha();
      return;
    }

    if (captchaInput != _generatedCaptcha) {
      _showSnackBar("CAPTCHA incorrect");
      _generateCaptcha();
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.userType == "candidate") {
        final partiesSnapshot = await _firestore.collection('LOK_SABHA').get();
        for (final party in partiesSnapshot.docs) {
          final candidateDoc = await party.reference
              .collection('candidates')
              .doc(widget.aadhaarNumber)
              .get();
          if (candidateDoc.exists) {
            await candidateDoc.reference.update({'password': newPassword});
            _showSnackBar("Password updated successfully!");
            _navigateToLogin();
            return;
          }
        }
        _showSnackBar("Candidate not found.");
      } else if (widget.userType == "ec_employee") {
        final docRef = _firestore.collection('EC_EMPLOYEES').doc(widget.aadhaarNumber);
        final doc = await docRef.get();
        if (doc.exists) {
          await docRef.update({'password': newPassword});
          _showSnackBar("Password updated successfully!");
          _navigateToLogin();
        } else {
          _showSnackBar("EC Employee not found.");
        }
      }
    } catch (e) {
      _showSnackBar("Failed to update password");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => CandidateLoginScreen()),
          (route) => false,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Reset Password")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Lottie.asset('assets/animations/lock.json', height: 160),
            SizedBox(height: 20),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [

                       TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "New Password",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),

                    SizedBox(height: 15),

                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_reset_outlined),
                      ),
                    ),
                    SizedBox(height: 20),

                    Row(
                      children: [
                        // CAPTCHA Input - 60%
                        Flexible(
                          flex: 6,
                          child: TextField(
                            controller: _captchaController,
                            decoration: InputDecoration(
                              labelText: "Enter CAPTCHA",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(Icons.verified_user),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // CAPTCHA Image - 30%
                        Flexible(
                          flex: 3,
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: CustomPaint(
                              painter: CaptchaPainter(_generatedCaptcha),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Refresh Icon - 10%
                        Flexible(
                          flex: 1,
                          child: IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: "Refresh CAPTCHA",
                            onPressed: _generateCaptcha,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),


                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton.icon(
                      icon: Icon(Icons.update),
                      label: Text("Update Password"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _updatePassword,
                    ),
                  ],
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
