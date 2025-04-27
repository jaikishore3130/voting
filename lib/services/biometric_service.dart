import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:local_auth/local_auth.dart';
import 'package:voting/screens/FaceVerificationPage.dart';

class BiometricAuthScreen extends StatefulWidget {
  final String aadhaar;
  final Map<String, dynamic> election;  // Changed static to instance variable

  const BiometricAuthScreen({
    required this.aadhaar,
    required this.election,
  });

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}


class _BiometricAuthScreenState extends State<BiometricAuthScreen> with SingleTickerProviderStateMixin {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isProcessing = false;
  String _status = "Click below to start fingerprint verification.";
  bool _fingerprintAuthDone = false;

  late AnimationController _lottieController;
  bool _playedInitial = false;

  Future<void> _authenticateFingerprint() async {
    try {
      setState(() {
        _isProcessing = true;
        _status = "Authenticating fingerprint...";
      });

      final authenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint to continue',
        options: const AuthenticationOptions(stickyAuth: true),
      );

      if (authenticated) {
        setState(() {
          _fingerprintAuthDone = true;
          _status = "Fingerprint authentication successful!";
        });

        // Play full animation after authentication success
        _lottieController.reset();
        _lottieController.animateTo(1.0, duration: const Duration(seconds: 2));

        // After animation completes, move to Face Verification
        await Future.delayed(const Duration(seconds: 2));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FaceAuthScreen(aadhaar: widget.aadhaar, election:widget.election,),
          ),
        );
      } else {
        setState(() {
          _status = "Fingerprint authentication failed!";
        });
      }
    } catch (e) {
      setState(() {
        _status = "Error during fingerprint authentication: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Biometric Authentication"),
        centerTitle: true,
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/finger.json',
                controller: _lottieController,
                onLoaded: (composition) {
                  if (!_playedInitial) {
                    final firstHalf = 85 / composition.durationFrames;
                    _lottieController.animateTo(
                      firstHalf,
                      duration: const Duration(seconds: 2),
                    );
                    _playedInitial = true;
                  }
                },
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 30),

              // 🔵 Show fingerprint verification button if not done
              if (!_fingerprintAuthDone)
                ElevatedButton(
                  onPressed: _authenticateFingerprint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Start Fingerprint Verification",
                    style: TextStyle(fontSize: 16),
                  ),
                ),

              // 🟢 After fingerprint is done, show Face Verification button
              if (_fingerprintAuthDone)
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FaceAuthScreen(aadhaar: widget.aadhaar,election:widget.election),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Proceed to Face Verification",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

}
