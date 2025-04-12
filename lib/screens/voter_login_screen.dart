import 'dart:math';
import 'dart:async';
import 'package:lottie/lottie.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import 'package:voting/screens/voter/voter_dashboard.dart';

class VoterLoginScreen extends StatefulWidget {
  @override
  _VoterLoginState createState() => _VoterLoginState();
}

class _VoterLoginState extends State<VoterLoginScreen> {
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();
  int _resendCounter = 0;
  int _resendTimeout = 60;


  bool isLoading = false;
  bool otpSent = false;
  String generatedCaptcha = "";

  String generatedOtp = "";
  String? maskedPhoneNumber = "+91 XXXXX X1234";
  List<TextEditingController> _otpControllers =
  List.generate(6, (index) => TextEditingController());
  List<FocusNode> _otpFocusNodes =
  List.generate(6, (index) => FocusNode());

  TwilioFlutter twilioFlutter = TwilioFlutter(
    accountSid: 'ACe7434c012ed32996526101fdc5e2f1ff',
    authToken: '338343628ebc83d5617e65284990900c',
    twilioNumber: '+15178588142',
  );
  ValueNotifier<int> _resendTimeoutNotifier = ValueNotifier<int>(60);
  bool _canResend = true;
  Timer? _resendTimer;

  void startResendTimer() {
    setState(() {
      _canResend = false; // Disable the resend button
      _resendTimeoutNotifier.value = 60; // Start countdown from 60
    });

    _resendTimer?.cancel(); // Cancel existing timer (if any)
    _resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_resendTimeoutNotifier.value == 0) {
        setState(() {
          _canResend = true; // Enable the resend button when timer ends
          timer.cancel(); // Stop the timer
        });
      } else {
        _resendTimeoutNotifier.value--; // Decrement countdown every second
      }
    });
  }


  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }



// Resend OTP function
  void resendOTP() {
    if (_resendCounter >= 5) {
      _showMessage("Too many attempts! Try again after 1 hour.");
      _resendTimeout = 3600; // Lock for 1 hour
      startResendTimer();
      return;
    }

    _resendCounter++;



    verifyInputs(); // 🔹 Send OTP using sendOTP()
    startResendTimer(); // Restart the countdown

  }




  void generateNewOtp() {
    generatedOtp = (100000 + Random().nextInt(900000)).toString();
    print("New OTP: $generatedOtp");
  }

  void verifyOTP() {
    String enteredOTP =
    _otpControllers.map((controller) => controller.text).join();
    if (enteredOTP == generatedOtp) {
      _showMessage("Login Successful! Redirecting...");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VoterDashboard(
            aadhaarNumber: _aadhaarController.text.trim(),
          ),
        ),
      );



    } else {
      _showMessage("Invalid OTP! Try again.");
    }
  }

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

        maskedPhoneNumber =
        "+91 XXXXX X${phoneNumber.substring(phoneNumber.length - 4)}";
        sendOTP(phoneNumber);
      } else {
        _showMessage("Invalid Aadhaar details! Contact EC.");
        setState(() => isLoading = false);
      }
    } else {
      _showMessage("Aadhaar not linked to any valid phone number! Contact EC.");
      setState(() => isLoading = false);
    }
  }

  void sendOTP(String phoneNumber) {
    generatedOtp = (100000 + Random().nextInt(900000)).toString();

    twilioFlutter
        .sendSMS(
      toNumber: phoneNumber,
      messageBody: "Your OTP for voter login is: $generatedOtp",
    )
        .then((_) {
      setState(() {
        otpSent = true;
        isLoading = false;
      });
    }).catchError((error) {
      print("Twilio Error: $error");
      _showMessage("Error sending OTP! Try again.");
      setState(() => isLoading = false);
    });
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
              child: otpSent ? _buildOtpScreen(context) : _buildAadhaarScreen(context),
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
  Widget _buildOtpScreen(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Lottie Animation (Responsive)
            SizedBox(
              height: screenHeight * 0.3,
              child: Lottie.asset('assets/animations/otp_animation.json', fit: BoxFit.contain),
            ),

            SizedBox(height: 20),

            // OTP Info Texts
            Text(
              "OTP sent to",
              style: TextStyle(fontSize: 18, color: Colors.black54),
            ),
            Text(
              maskedPhoneNumber ?? "+91 XXXXX X1234",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
            ),

            SizedBox(height: 25),

            // OTP Fields
            RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (event) {
                if (event is RawKeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.backspace) {
                  for (int i = 0; i <= 5; i++) {
                    if (_otpControllers[i].text.isEmpty && i > 0) {
                      _otpControllers[i - 1].clear();
                      FocusScope.of(context).requestFocus(_otpFocusNodes[i - 1]);
                      break;
                    }
                  }
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: screenWidth * 0.1,
                    height: screenHeight * 0.065,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _otpFocusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: "",
                        filled: true,
                        fillColor: Colors.purple[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
                        } else if (value.isEmpty && index > 0) {
                          FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
                        }
                      },
                    ),
                  );
                }),
              ),
            ),

            SizedBox(height: 30),

            // Verify OTP Button
            ElevatedButton.icon(
              onPressed: verifyOTP,
              icon: Icon(Icons.verified, color: Colors.white),
              label: Text("Verify OTP", style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 5,
              ),
            ),

            SizedBox(height: 15),

            // Resend OTP
            ValueListenableBuilder<int>(
              valueListenable: _resendTimeoutNotifier,
              builder: (context, value, _) {
                int minutes = value ~/ 60;
                int seconds = value % 60;
                return TextButton(
                  onPressed: _canResend ? () {
                    resendOTP();
                    startResendTimer();
                  } : null,
                  child: Text(
                    _canResend
                        ? "Resend OTP"
                        : "Resend OTP in $minutes:${seconds.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      fontSize: 16,
                      color: _canResend ? Colors.blue : Colors.grey,
                      decoration: _canResend ? TextDecoration.underline : null,
                    ),
                  ),
                );
              },
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
