import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:lottie/lottie.dart';
import 'package:voting/screens/voting_screen.dart';


class FaceAuthScreen extends StatefulWidget {
  final String aadhaar;
  final Map<String, dynamic> election;  // Changed static to instance variable

  const FaceAuthScreen({Key? key, required this.aadhaar, required this.election}) : super(key: key);

  @override
  _FaceAuthScreenState createState() => _FaceAuthScreenState();
}

class _FaceAuthScreenState extends State<FaceAuthScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  String? _decryptedFaceImageBase64;
  bool _showCamera = true; // 👈 Manage camera visibility

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _fetchAndDecryptFace();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    final frontCamera = _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    _controller = CameraController(frontCamera, ResolutionPreset.medium);
    await _controller?.initialize();
    setState(() {
      _isCameraInitialized = true;
      _showCamera = true;
    });
  }

  Future<void> _disposeCamera() async {
    await _controller?.dispose();
    _controller = null;
    setState(() {
      _isCameraInitialized = false;
      _showCamera = false;
    });
  }

  Future<void> _fetchAndDecryptFace() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('voters').doc(widget.aadhaar).get();
      final faceUrl = snapshot['face'];

      if (faceUrl != null) {
        final response = await http.get(Uri.parse(faceUrl));
        if (response.statusCode == 200) {
          final encryptedBytes = response.bodyBytes;
          final decryptedBytes = await AESHelper.decrypt(encryptedBytes);

          setState(() {
            _decryptedFaceImageBase64 = base64Encode(decryptedBytes);
            _isLoading = false; // 👈 Set loading false after fetching
          });
        } else {
          print('Failed to download encrypted face image');
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Error fetching and decrypting face: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _captureImage() async {
    if (!_isCameraInitialized) return;
    try {
      XFile imageFile = await _controller!.takePicture();
      String imagePath = imageFile.path;
      _startVerification(imagePath);
    } catch (e) {
      print("❌ Error capturing image: $e");
    }
  }

  Future<void> _startVerification(String liveImagePath) async {
    if (_decryptedFaceImageBase64 == null) {
      print("❌ Decrypted face image not available yet!");
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    final result = await FaceAuthService.verifyFace(
      widget.aadhaar,
      _decryptedFaceImageBase64!,
      liveImagePath,
    );

    setState(() {
      _isLoading = false;
      _statusMessage = result ? '✅ Face Verified' : '❌ Invalid Face';
    });

    if (result) {
      await _disposeCamera(); // 👈 Close camera on success
    } else {
      await _disposeCamera(); // 👈 Also close camera on failure
    }
  }

  Future<void> _retryCapture() async {
    await _initializeCamera(); // 👈 Reopen the camera
    setState(() {
      _statusMessage = '';
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text("Face Authentication")),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 1500), // transition time
                    transitionBuilder: (child, animation) {
                      // spiral + shrink + fade
                      return FadeTransition(
                        opacity: animation,
                        child: RotationTransition(
                          turns: Tween<double>(begin: 0, end: 5).animate(animation),
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: Column(
                      key: const ValueKey('loadingAnimation'), // important for switch
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Lottie.asset(
                          'assets/animations/face.json',
                          width: screenWidth * 0.6,
                          height: screenWidth * 0.6,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Verifying face...",
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  )


                else if (!_isLoading && _showCamera && _isCameraInitialized)
                  Column(
                    children: [
                      SizedBox(
                        width: screenWidth * 0.9,
                        height: screenHeight * 0.6,
                        child: CameraPreview(_controller!),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      SizedBox(
                        width: screenWidth * 0.6,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _captureImage,
                          child: const Text("Capture Face"),
                        ),
                      ),
                    ],
                  ),

                SizedBox(height: screenHeight * 0.04),

                if (_statusMessage.isNotEmpty)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _statusMessage,
                      key: ValueKey<String>(_statusMessage),
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        color: _statusMessage.contains('✅') ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                if (_statusMessage.contains('✅'))
                  Column(
                    children: [
                      const Icon(Icons.verified_user, color: Colors.green, size: 100),
                      SizedBox(height: screenHeight * 0.02),
                      SizedBox(
                        width: screenWidth * 0.6,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VotingScreen(aadhaar: widget.aadhaar, election:widget.election),
                              ),
                            );
                          },
                          child: const Text("Cast Your Vote", style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ],
                  )
                else if (_statusMessage.contains('❌'))
                  Column(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 100),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        "Face Not Matched!",
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      SizedBox(
                        width: screenWidth * 0.6,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _retryCapture,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text("Retry", style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class FaceAuthService {
  static const String _serverUrl = 'https://jaikishore0130-buzz.hf.space/verify-face';

  /// Sends Aadhaar, decrypted saved face and live captured face to server
  static Future<bool> verifyFace(String aadhaar, String savedFaceBase64, String liveImagePath) async {
    try {
      final liveImageBytes = await File(liveImagePath).readAsBytes();
      final liveFaceBase64 = base64Encode(liveImageBytes);

      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({

          'saved_face': savedFaceBase64,
          'live_face': liveFaceBase64,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print('${response.body}');
        return result['status'] == 'Face Verified';

      } else {
        print('❌ Server Error: ${response.body}');
        return false;
      }
    } catch (e) {
      print("❌ Exception during face verification: $e");
      return false;
    }
  }
}

// AES Helper class for decryption
class AESHelper {
  static final key = encrypt.Key.fromUtf8('28212821282128212821282128212821'); // 32 bytes
  static final iv = encrypt.IV.fromUtf8('3031303130313031'); // 16 bytes

  // Decrypt the encrypted image bytes
  static Future<List<int>> decrypt(List<int> encryptedBytes) async {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final decrypted = encrypter.decryptBytes(encrypt.Encrypted(Uint8List.fromList(encryptedBytes)), iv: iv);
      return decrypted;
    } catch (e) {
      print("Decryption failed: $e");
      return [];
    }
  }
}
