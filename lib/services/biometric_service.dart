import 'package:flutter/material.dart';

class BiometricAuthScreen extends StatelessWidget {
  const BiometricAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _verifyFingerprintAndFace(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          Future.microtask(() => Navigator.pop(context, true));
        } else {
          Future.microtask(() => Navigator.pop(context, false));
        }

        return const Scaffold(
          body: Center(child: Text("Authentication failed.")),
        );
      },
    );
  }

  Future<bool> _verifyFingerprintAndFace() async {
    // Replace with your actual verification logic
    final isFingerprintOk = await simulateFingerprintCheck(); // simulate or real biometric
    if (!isFingerprintOk) return false;

    final isFaceOk = await simulateFaceDetection(); // AES decrypt + match
    return isFaceOk;
  }

  Future<bool> simulateFingerprintCheck() async {
    await Future.delayed(const Duration(seconds: 2));
    return true; // simulate success
  }

  Future<bool> simulateFaceDetection() async {
    await Future.delayed(const Duration(seconds: 2));
    return true; // simulate success
  }
}
