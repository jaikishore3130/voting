import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:twilio_flutter/twilio_flutter.dart';
import 'package:voting/screens/Voter_dashboard.dart'; // Import Voter Dashboard screen

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
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => VoterDashboard()));
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
      List.generate(6,
              (index) => chars.codeUnitAt(random.nextInt(chars.length))),
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
      appBar: AppBar(title: Text("Voter login")),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: otpSent ? _buildOtpScreen() : _buildAadhaarScreen(),
        ),
      ),
    );
  }

  Widget _buildAadhaarScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo at the top
        Image.asset("assets/images/aalogo.png", height: 100),
        SizedBox(height: 20),

        // Aadhaar Number Input
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Enter Aadhaar Number",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 5),
        TextField(
          controller: _aadhaarController,
          keyboardType: TextInputType.number,
          maxLength: 12,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Aadhaar Number",
          ),
        ),
        SizedBox(height: 20),

        // CAPTCHA Section
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Enter CAPTCHA",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 5),

        Row(
          children: [
            // CAPTCHA Input Field
            Expanded(
              flex: 2,
              child: TextField(
                controller: _captchaController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Enter CAPTCHA",
                ),
              ),
            ),
            SizedBox(width: 10),

            // CAPTCHA Image
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                generatedCaptcha,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 10),

            // Refresh CAPTCHA Button
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.blue),
              onPressed: _generateCaptcha,
            ),
          ],
        ),

        SizedBox(height: 20),

        // Verify Button
        ElevatedButton.icon(
          onPressed: verifyInputs,
          icon: Icon(Icons.verified, color: Colors.white),
          label: Text("Verify"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ],
    );
  }


  // OTP Screen UI
  Widget _buildOtpScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo
        Image.asset("assets/images/otplogo.jpg", height: 200),
        SizedBox(height: 20),

        // OTP sent text
        Text(
          "OTP sent to",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black54),
        ),
        Text(
          maskedPhoneNumber ?? "+91 XXXXX X1234",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        SizedBox(height: 20),
        // OTP input boxes with backspace handling
        RawKeyboardListener(
          focusNode: FocusNode(), // Required for capturing key events
          onKey: (event) {
            if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
              for (int i = 0; i <= 5; i++) {
                if (_otpControllers[i].text.isEmpty && _otpControllers[i-1].text.isNotEmpty) {
                  _otpControllers[i - 1].clear();
                  FocusScope.of(context).requestFocus(_otpFocusNodes[i - 1]);
                  break;
                }
              }
            }
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              return Container(
                width: 45,
                height: 55,
                margin: EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: _otpFocusNodes[index].hasFocus ? Colors.blue:Colors.black,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _otpControllers[index],
                  focusNode: _otpFocusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: "",
                    border: InputBorder.none,
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


        // OTP input boxes

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
        SizedBox(height: 10),

        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 5),

            TextButton(
              onPressed: _canResend ? () {
                resendOTP(); // Send a new OTP
                startResendTimer(); // Start countdown timer
              } : null, // Disable button during countdown
              child: AnimatedBuilder(
                animation: _resendTimeoutNotifier,
                builder: (context, child) {
                  int minutes = _resendTimeoutNotifier.value ~/ 60;
                  int seconds = _resendTimeoutNotifier.value % 60;
                  String formattedTime = "$minutes:${seconds.toString().padLeft(2, '0')}"; // Format as MM:SS

                  return Text(
                    _canResend ? "Resend OTP" : "Resend OTP In $formattedTime",
                    style: TextStyle(
                      fontSize: 16,
                      color: _canResend ? Colors.blue : Colors.grey, // Grey when disabled
                      decoration: _canResend ? TextDecoration.underline : null,
                    ),
                  );
                },
              ),
            ),

          ],
        ),

      ],
    );
  }

}


