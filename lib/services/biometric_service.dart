import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:voting/screens/FaceVerificationPage.dart';

class BiometricAuthScreen extends StatefulWidget {

  final String aadhaar;
  const BiometricAuthScreen({required this.aadhaar});
  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isProcessing = false;
  String _status = "Click below to start biometric verification.";
  bool _fingerprintAuthDone = false;
  bool _faceAuthDone = false;

  // Authenticate using fingerprint
  Future<void> _authenticateFingerprint() async {
    try {
      setState(() {
        _isProcessing = true;
        _status = "Authenticating with fingerprint...";
      });

      // Start fingerprint authentication
      final authenticated = await auth.authenticate(
        localizedReason: 'Scan your fingerprint to continue',
        options: const AuthenticationOptions(
          stickyAuth: true, // Keep the authentication until successful or canceled
        ),
      );

      if (authenticated) {
        setState(() {
          _fingerprintAuthDone = true;
          _status = "Fingerprint authentication successful!";
        });

        // If fingerprint is done, check for face authentication
        if (_faceAuthDone) {
          Navigator.pop(context, true); // Return true if both are done
        }
      } else {
        setState(() {
          _status = "Fingerprint authentication failed!";
        });
      }
    } catch (e) {
      setState(() {
        _status = "Error occurred during fingerprint authentication: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Authenticate using face recognition
  Future<void> _authenticateFace() async {
    try {
      setState(() {
        _isProcessing = true;
        _status = "Authenticating with face recognition...";
      });

      // Start face authentication
      final authenticated = await auth.authenticate(
        localizedReason: 'Scan your face to continue',
        options: const AuthenticationOptions(
          stickyAuth: true, // Keep the authentication until successful or canceled
        ),
      );

      if (authenticated) {
        setState(() {
          _faceAuthDone = true;
          _status = "Face authentication successful!";
        });

        // If face is done, check for fingerprint authentication
        if (_fingerprintAuthDone) {
          Navigator.pop(context, true); // Return true if both are done
        }
      } else {
        setState(() {
          _status = "Face authentication failed!";
        });
      }
    } catch (e) {
      setState(() {
        _status = "Error occurred during face authentication: $e";
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Check for available biometrics (fingerprint and face)
  Future<void> _checkBiometrics() async {
    try {
      final availableBiometrics = await auth.getAvailableBiometrics();
      print("Available biometrics: $availableBiometrics");

      if (availableBiometrics.isEmpty) {
        setState(() {
          _status = "No biometric methods available.";
        });
        return;
      }

      if (availableBiometrics.contains(BiometricType.fingerprint)) {
        await _authenticateFingerprint();
      }

      if (availableBiometrics.contains(BiometricType.face)) {
        await _authenticateFace();
        setState(() {
          _status = _fingerprintAuthDone
              ? "Fingerprint done! Now authenticate with face."
              : "Fingerprint available. Please authenticate.";
        });
      } else {
        setState(() {
          _status += "\nNote: Face recognition not available.";
        });
      }
    } catch (e) {
      setState(() {
        _status = "Error checking biometrics: $e";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkBiometrics(); // Check biometrics availability on screen load
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Biometric Authentication")),
      body: Center(
        child: _isProcessing
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(_status, textAlign: TextAlign.center),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 20),

            // 🔘 Show fingerprint button if not yet done
            if (!_fingerprintAuthDone && !_faceAuthDone)
              ElevatedButton(
                onPressed: _authenticateFingerprint,
                child: const Text("Authenticate with Fingerprint"),
              ),

            // 🔘 Show face button if fingerprint is done but face is not
            if (_fingerprintAuthDone && !_faceAuthDone)
              ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FaceAuthScreen(aadhaar: widget.aadhaar),
                    ),
                  );

                  // Optional: check result from FaceAuthScreen


                },
                child: Text("Proceed to Face Verification"),
              ),
          ],
        ),
      ),
    );
  }
}
