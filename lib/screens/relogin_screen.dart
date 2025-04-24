// Combined Relogin Page with OTP Screen

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import 'package:lottie/lottie.dart';

class ReLoginWithOtpScreen extends StatefulWidget {
  final String userType;
  const ReLoginWithOtpScreen({required this.userType});

  @override
  _ReLoginWithOtpScreenState createState() => _ReLoginWithOtpScreenState();
}

class _ReLoginWithOtpScreenState extends State<ReLoginWithOtpScreen> {
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool isLoading = false;
  String generatedCaptcha = "";
  String generatedOtp = "";
  String? phoneNumber;

  late TwilioFlutter twilioFlutter;
  final ValueNotifier<int> _resendTimeoutNotifier = ValueNotifier<int>(60);
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
    twilioFlutter = TwilioFlutter(
      accountSid: 'ACdc1f549d4efbe1b9ce5827e5ac3994da',
      authToken: 'd43412cb4ff5d3cb16c358d7bd899fb3',
      twilioNumber: '+13203825474',
    );
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<Map<String, dynamic>?> _getVoterDetails(String aadhaar) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('voters')
          .doc(aadhaar)
          .get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      return null;
    }
  }

  bool _is18OrOlder(String dob) {
    try {
      DateTime birthDate = DateTime.parse(dob);
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
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

    Map<String, dynamic>? voterData = await _getVoterDetails(_aadhaarController.text);
    if (voterData != null) {
      String? dob = voterData['dob'];
      phoneNumber = voterData['phone'] != null ? "+91${voterData['phone']}" : null;

      if (phoneNumber != null && dob != null && _is18OrOlder(dob)) {
        _sendOtp();
      } else {
        _showMessage("Invalid or underage voter. Contact EC.");
      }
    } else {
      _showMessage("Voter not found!");
    }
    setState(() => isLoading = false);
  }

  void _sendOtp() {
    generatedOtp = (100000 + Random().nextInt(900000)).toString();
    twilioFlutter.sendSMS(toNumber: phoneNumber!, messageBody: "Your OTP is $generatedOtp");
    _startResendCountdown();
  }

  void _startResendCountdown() {
    _canResend = false;
    _resendTimeoutNotifier.value = 60;
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (_resendTimeoutNotifier.value == 0) {
        timer.cancel();
        _canResend = true;
      } else {
        _resendTimeoutNotifier.value--;
      }
    });
  }

  void _verifyOtp() {
    String enteredOtp = _otpControllers.map((c) => c.text).join();
    if (enteredOtp == generatedOtp) {
      _showMessage("OTP Verified! Proceeding...");
      if (widget.userType == "voting") {
        Navigator.pop(context, true);}
        // Proceed to dashboard or password reset
    } else {
      _showMessage("Incorrect OTP. Try Again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xFF11395E),
      appBar: AppBar(
        title: Text("Relogin with OTP", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF072743),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: 20),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF79C5DD),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              children: [
                Lottie.asset('assets/animations/login_animation.json', height: screenHeight * 0.28),
                SizedBox(height: 20),
                buildTextField("Aadhaar Number", _aadhaarController, maxLength: 12, keyboardType: TextInputType.number),
                SizedBox(height: 10),
                buildCaptchaRow(),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: verifyInputs,
                  child: Text("Send OTP"),
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF072743)),
                ),
                SizedBox(height: 30),
                buildOtpInputs(),
                SizedBox(height: 10),
                ValueListenableBuilder<int>(
                  valueListenable: _resendTimeoutNotifier,
                  builder: (context, time, child) {
                    return TextButton(
                      onPressed: _canResend ? _sendOtp : null,
                      child: Text(_canResend ? "Resend OTP" : "Resend in $time s"),
                    );
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _verifyOtp,
                  child: Text("Verify OTP"),
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF072743)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String hint, TextEditingController controller, {int? maxLength, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      ),
    );
  }

  Widget buildCaptchaRow() {
    return Row(
      children: [
        Expanded(
          child: buildTextField("CAPTCHA", _captchaController),
        ),
        SizedBox(width: 10),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Text(generatedCaptcha, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        IconButton(onPressed: _generateCaptcha, icon: Icon(Icons.refresh))
      ],
    );
  }

  Widget buildOtpInputs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) =>
          SizedBox(
            width: 40,
            child: TextField(
              controller: _otpControllers[index],
              focusNode: _otpFocusNodes[index],
              keyboardType: TextInputType.number,
              maxLength: 1,
              textAlign: TextAlign.center,
              decoration: InputDecoration(counterText: '', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
              onChanged: (value) {
                if (value.isNotEmpty && index < 5) {
                  FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
                }
              },
            ),
          )
      ),
    );
  }
}
