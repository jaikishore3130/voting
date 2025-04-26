import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';


class FaceAuthScreen extends StatefulWidget {
  final String aadhaar;

  const FaceAuthScreen({Key? key, required this.aadhaar}) : super(key: key);

  @override
  _FaceAuthScreenState createState() => _FaceAuthScreenState();
}

class _FaceAuthScreenState extends State<FaceAuthScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  bool _isCameraInitialized = false;
  String? _decryptedFaceImageBase64; // Saved decrypted face (Base64)

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _fetchAndDecryptFace(); // 👈 Fetch encrypted face URL from Firestore and decrypt
  }

  // Initialize camera
  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    final CameraDescription frontCamera = _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    _controller = CameraController(frontCamera, ResolutionPreset.medium);
    await _controller?.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  // Fetch encrypted face from Firestore, download, decrypt
  Future<void> _fetchAndDecryptFace() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('voters').doc(widget.aadhaar).get();
      final faceUrl = snapshot['face']; // Assuming face field stores GitHub or Firebase Storage URL

      if (faceUrl != null) {
        // Download encrypted image
        final response = await http.get(Uri.parse(faceUrl));
        if (response.statusCode == 200) {
          final encryptedBytes = response.bodyBytes;

          // Decrypt the image (Assuming AES decryption method available)
          final decryptedBytes = await AESHelper.decrypt(encryptedBytes);

          // Convert to Base64
          setState(() {
            _decryptedFaceImageBase64 = base64Encode(decryptedBytes);
          });
        } else {
          print('Failed to download encrypted face image');
        }
      }
    } catch (e) {
      print('❌ Error fetching and decrypting face: $e');
    }
  }

  // Capture image from the camera
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

  // Start face verification
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
      _statusMessage =
      result ? '✅ Face Verified' : '❌ Face Not Verified';
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
                if (_isLoading) const CircularProgressIndicator(),

                if (!_isLoading && _isCameraInitialized)
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
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      color: _statusMessage.contains('✅')
                          ? Colors.green
                          : Colors.red,
                    ),
                    textAlign: TextAlign.center,
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
