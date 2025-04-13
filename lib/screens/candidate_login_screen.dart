import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import 'package:voting/screens/candidate_dashboard.dart';
import 'package:lottie/lottie.dart';

class CandidateLoginScreen extends StatefulWidget {
  @override
  _CandidateLoginScreenState createState() => _CandidateLoginScreenState();
}

class _CandidateLoginScreenState extends State<CandidateLoginScreen> {
  final TextEditingController aadhaarController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController captchaController = TextEditingController();

  final List<TextEditingController> otpControllers =
  List.generate(6, (_) => TextEditingController());
  final List<FocusNode> otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool isLoading = false;
  bool otpSent = false;
  String generatedCaptcha = "";
  String generatedOtp = "";
  String? maskedPhone = "+91 XXXXX X1234";

  final TwilioFlutter twilioFlutter = TwilioFlutter(
    accountSid: 'ACe7434c012ed32996526101fdc5e2f1ff',
    authToken: '338343628ebc83d5617e65284990900c',
    twilioNumber: '+15178588142',
  );
  int otpResendAttempts = 0;
  int resendCooldown = 0; // 0 means no cooldown, 1 means 1 minute, 2 means 1 hour

  @override
  void initState() {
    super.initState();
    generateCaptcha();
    startOtpCooldown();
  }

  void startOtpCooldown() {
    if (otpResendAttempts >= 5) {
      resendCooldown = 2; // 1 hour cooldown
    } else if (otpResendAttempts > 0) {
      resendCooldown = 1; // 1 minute cooldown
    }
  }


  void generateCaptcha() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final codeUnits = List.generate(6, (index) => chars[random.nextInt(chars.length)]);
    setState(() {
      generatedCaptcha = codeUnits.join();
      captchaController.clear();
    });
  }


  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<Map<String, dynamic>?> fetchCandidateData(String aadhaar) async {
    try {
      final partySnapshots = await FirebaseFirestore.instance.collection('LOK_SABHA').get();
      for (final party in partySnapshots.docs) {
        final doc = await FirebaseFirestore.instance
            .collection('LOK_SABHA')
            .doc(party.id)
            .collection('candidates')
            .doc(aadhaar)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          data['party'] = party.id;
          return data;
        }
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

    if (aadhaar.length != 12) return showMessage("Enter a valid 12-digit Aadhaar number");
    if (password.isEmpty) return showMessage("Password cannot be empty");
    if (captcha != generatedCaptcha) {
      showMessage("Incorrect CAPTCHA! Try Again");
      generateCaptcha();
      return;
    }

    setState(() => isLoading = true);
    final data = await fetchCandidateData(aadhaar);

    if (data == null) {
      showMessage("No record found for this Aadhaar!");
      return setState(() => isLoading = false);
    }

    if (data['password'] != password) {
      showMessage("Incorrect password!");
      return setState(() => isLoading = false);
    }

    final phone = data['phone'];
    int? age = int.tryParse(data['age'].toString());
    showMessage('$age');

    if (phone == null || age == null) {
      showMessage("Incomplete candidate record.");
      return setState(() => isLoading = false);
    }


    if (age == null || age < 18) {
      showMessage("You must be 18+ to login.");
      return setState(() => isLoading = false);
    }


    maskedPhone = "+91 XXXXX X${phone.toString().substring(phone.length - 4)}";
    sendOTP("+91$phone");
  }

  void sendOTP(String phone) {
    generatedOtp = (100000 + Random().nextInt(900000)).toString();
    twilioFlutter.sendSMS(
      toNumber: phone,
      messageBody: "Your OTP for candidate login is: $generatedOtp",
    ).then((_) {
      setState(() {
        isLoading = false;
        otpSent = true;
      });
    }).catchError((e) {
      print("Twilio Error: $e");
      showMessage("Failed to send OTP. Try again.");
      setState(() => isLoading = false);
    });
  }

  void verifyOTP() {
    final inputOtp = otpControllers.map((c) => c.text).join();
    if (inputOtp == generatedOtp) {
      showMessage("Login Successful! Redirecting...");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CandidateDashboard(aadhaarNumber: aadhaarController.text.trim()),
        ),
      );
    } else {
      showMessage("Invalid OTP! Try again.");
    }
  }

  Widget buildLoginForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
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
                height: 250,
              ),
              const SizedBox(height: 30),
              buildStyledTextField("Aadhaar Number", aadhaarController,
                  maxLength: 12, keyboardType: TextInputType.number, icon: Icons.credit_card),
              const SizedBox(height: 10),
              buildStyledTextField("Password", passwordController,
                  obscureText: true, icon: Icons.lock),
              const SizedBox(height: 10),
              Row(
                children: [
                  // CAPTCHA Input (60%)
                  Expanded(
                    flex: 6,
                    child: buildStyledTextField("CAPTCHA", captchaController, icon: Icons.security),
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
              ),

              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: validateInputs,
                icon: const Icon(Icons.verified, color: Colors.white),
                label: const Text("Verify"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
              ),
            ],
          ),
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
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget buildOtpForm(BuildContext context, List<TextEditingController> otpControllers, List<FocusNode> otpFocusNodes, String? maskedPhone, VoidCallback verifyOTP) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            Lottie.asset(
              "assets/animations/otp_animation.json",
              height: 180,
              repeat: true,
            ),
            SizedBox(height: 20),
            Text(
              "OTP sent to",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 5),
            Text(
              maskedPhone ?? '',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(height: 30),

            // OTP fields using Wrap to avoid overflow
            Wrap(
              spacing: 5,
              runSpacing: 5,
              alignment: WrapAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  width: MediaQuery.of(context).size.width * 0.12, // Responsive width
                  constraints: BoxConstraints(minWidth: 45, maxWidth: 60),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54.withOpacity(0.5),
                        blurRadius: 4,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: otpControllers[index],
                    focusNode: otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        FocusScope.of(context).requestFocus(otpFocusNodes[index + 1]);
                      }
                    },
                    decoration: InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                );
              }),
            ),

            SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: verifyOTP,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  "Submit OTP",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 30),

            // Resend OTP button
            buildResendOtpButton(),
          ],
        ),
      ),
    );
  }
  Widget buildResendOtpButton() {
    String buttonText = "Resend OTP";
    bool canResend = resendCooldown == 0 || (resendCooldown == 1 && otpResendAttempts < 5);
    if (resendCooldown == 1) {
      buttonText = "Wait for 1 minute";
    } else if (resendCooldown == 2) {
      buttonText = "Wait for 1 hour";
    }

    return GestureDetector(
      onTap: canResend ? resendOtp : null,
      child: Text(
        buttonText,
        style: TextStyle(
          fontSize: 16,
          color: canResend ? Colors.blue : Colors.grey,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  void resendOtp() {
    if (otpResendAttempts >= 5) {
      showMessage("You have exceeded the maximum resend attempts. Please wait 1 hour.");
      return;
    }

    setState(() {
      otpResendAttempts++;
      resendCooldown = otpResendAttempts >= 5 ? 2 : 1;
    });

    // Reset the timer based on the cooldown
    if (resendCooldown == 1) {
      Future.delayed(Duration(minutes: 1), () {
        setState(() {
          resendCooldown = 0;
        });
      });
    } else if (resendCooldown == 2) {
      Future.delayed(Duration(hours: 1), () {
        setState(() {
          resendCooldown = 0;
        });
      });
    }

    // Call OTP sending function again
    resendOtp();
  }

  Widget buildTextField(String label, TextEditingController controller,
      {bool obscureText = false, int? maxLength, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: InputDecoration(border: OutlineInputBorder(), labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Candidate Login")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: isLoading
              ? CircularProgressIndicator()
              : otpSent
              ? buildOtpForm(context, otpControllers, otpFocusNodes, maskedPhone, verifyOTP)
              : buildLoginForm(),
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
    for (int i = 0; i < 7; i++) {
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
