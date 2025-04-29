import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import 'package:voting/screens/SetNewPasswordScreen.dart';
import 'package:voting/screens/nomination_screen.dart';
import 'package:voting/screens/voter/voter_dashboard.dart';
import 'candidate_dashboard.dart';
import 'ec_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voting/screens/voter/vote_now_screen.dart';
import 'package:voting/config/routes.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String aadhaarNumber;
  final String userType; // 'voter', 'candidate', 'ec_employee'

  const OtpScreen({
    required this.phoneNumber,
    required this.aadhaarNumber,
    required this.userType,
  });

  @override
  _OtpScreenState createState() => _OtpScreenState();
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
class _OtpScreenState extends State<OtpScreen> {
  List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());
  List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  late TwilioFlutter twilioFlutter;
  String generatedOtp = "";
  bool _canResend = false;
  final ValueNotifier<int> _resendTimeoutNotifier = ValueNotifier<int>(60);
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    twilioFlutter = TwilioFlutter(
      accountSid: 'YOUR_ACCOUNT_SID',
      authToken: 'YOUR_AUTHTOKEN',
      twilioNumber: 'YOUR_TWILIONUMBER',

    );
    _generateNewOtp();
    _sendOtp();
    _startResendTimer();
  }

  void _generateNewOtp() {
    generatedOtp = (100000 + Random().nextInt(900000)).toString();
    print("Generated OTP: $generatedOtp");
  }

  void _sendOtp() {
    twilioFlutter.sendSMS(
      toNumber: widget.phoneNumber,
      messageBody: "Your OTP is: $generatedOtp",
    ).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP sent to ${widget.phoneNumber}")),
      );
    }).catchError((error) {
      print("Error sending OTP: $error");
      _showMessage("Error sending OTP! Please try again.");
    });
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTimeoutNotifier.value = 60;

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_resendTimeoutNotifier.value == 0) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        _resendTimeoutNotifier.value--;
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _verifyOtp() {
    String enteredOtp = _otpControllers.map((c) => c.text).join();
    if (enteredOtp == generatedOtp) {
      if (widget.userType == "nomination") {
        Navigator.pop(context, true); // return to nomination screen stepper
      }else {
        _navigateToDashboard();
      }
    } else {
      _showMessage("Invalid OTP! Please try again.");
    }
  }

  Future<void> _navigateToDashboard() async {
    if (widget.userType == "voter") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => VoterDashboard(aadhaarNumber: widget.aadhaarNumber),
        ),
      );
    } else if (widget.userType == "candidate") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CandidateDashboard(aadhaarNumber: widget.aadhaarNumber),
        ),
      );
    }else if (widget.userType == "candidate_reset") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SetNewPasswordScreen(aadhaarNumber: widget.aadhaarNumber, userType: 'candidate',),
        ),
      );
    } else if (widget.userType == "ec_reset") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SetNewPasswordScreen(aadhaarNumber: widget.aadhaarNumber, userType: 'ec_employees',),
        ),
      );
    } else if (widget.userType == "ec_employee") {
      final data = await fetchECData(widget.aadhaarNumber);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EcEmployeeDashboard(aadhaarNumber: widget.aadhaarNumber, role: '${data?['role']}', state: '${data?['state']}',),
        ),
      );
    } else {
      _showMessage("Invalid user type!");
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _resendTimeoutNotifier.dispose();
    _otpControllers.forEach((c) => c.dispose());
    _otpFocusNodes.forEach((f) => f.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final maskedPhone = widget.phoneNumber.replaceRange(3, 9, 'XXXXXX');

    return Scaffold(
      appBar: AppBar(title: Text("OTP Verification")),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 20),
          child: Column(
            children: [
              SizedBox(
                height: screenHeight * 0.3,
                child: Lottie.asset('assets/animations/otp_animation.json'),
              ),
              Text("OTP sent to", style: TextStyle(fontSize: 18)),
              Text(maskedPhone, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
              SizedBox(height: 25),

              RawKeyboardListener(
                focusNode: FocusNode(),
                onKey: (event) {
                  if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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

              ElevatedButton.icon(
                onPressed: _verifyOtp,
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

              ValueListenableBuilder<int>(
                valueListenable: _resendTimeoutNotifier,
                builder: (context, value, _) {
                  int minutes = value ~/ 60;
                  int seconds = value % 60;
                  return TextButton(
                    onPressed: _canResend
                        ? () {
                      _generateNewOtp();
                      _sendOtp();
                      _startResendTimer();  // Start the timer after OTP is resent
                    }
                        : null,
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
      ),
    );
  }
}
