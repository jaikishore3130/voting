import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:voting/screens/candidate/nomination_tab.dart';

import 'package:voting/screens/otp_screen.dart';

class NominationScreen extends StatefulWidget {
  final String aadhaarNumber;
  const NominationScreen({required this.aadhaarNumber, Key? key}) : super(key: key);

  @override
  State<NominationScreen> createState() => _NominationScreenState();
}

class _NominationScreenState extends State<NominationScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  final picker = ImagePicker();
  File? _photo;
  File? _video;
  String? photoUrl;
  String? videoUrl;

  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _educationController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _constituencyController = TextEditingController();

  String? _selectedGender = 'MALE';
  String? _selectedState;
  String? _selectedParty;

  final List<String> states = ['Bihar', 'Maharashtra', 'Tamil Nadu', 'Karnataka'];
  final List<String> parties = ['BJP', 'INC', 'AAP', 'CPI', 'Independent'];

  int? _calculatedAge;
  bool _isPhoneVerified = false;

  Future<File> encryptFile(File file, String aadhaar, String fileType) async {
    final key = encrypt.Key.fromUtf8('28212821282128212821282128212821');
    final iv = encrypt.IV.fromUtf8('3031303130313031');
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final inputBytes = await file.readAsBytes();
    final encrypted = encrypter.encryptBytes(inputBytes, iv: iv);

    final encryptedFileName = '${aadhaar}_$fileType.enc';
    final dir = await getTemporaryDirectory();
    final encryptedFile = File(path.join(dir.path, encryptedFileName));
    await encryptedFile.writeAsBytes(encrypted.bytes);

    print('Encrypted file saved to: ${encryptedFile.path}');
    return encryptedFile;
  }

  Future<String?> uploadToGitHub(File file, String filename) async {
    final token = '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';
    final repoOwner = 'jaikishore3130';
    final repoName = 'encrypted-profile-images';

    final url = 'https://api.github.com/repos/$repoOwner/$repoName/contents/$filename';
    final content = base64Encode(await file.readAsBytes());

    final body = jsonEncode({
      'message': 'Upload encrypted file $filename',
      'content': content,
    });

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
      },
      body: body,
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body);
      return json['content']['download_url'];
    } else {
      print('❌ Failed to upload: ${response.statusCode} ${response.body}');
      return null;
    }
  }

  Future<void> _pickPhoto(String aadhaar) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _photo = File(pickedFile.path);
      final encryptedFile = await encryptFile(_photo!, aadhaar, 'NP');
      photoUrl = await uploadToGitHub(encryptedFile, '${aadhaar}_NP.enc');
    }
  }

  Future<void> _captureVideo(String aadhaar) async {
    final pickedVideo = await picker.pickVideo(source: ImageSource.camera);
    if (pickedVideo != null) {
      _video = File(pickedVideo.path);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🎥 Video captured')));
      final encryptedFile = await encryptFile(_video!, aadhaar, 'NV');
      videoUrl = await uploadToGitHub(encryptedFile, '${aadhaar}_NV.enc');
    }
  }

  void _selectDOB() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      _dobController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() => _calculatedAge = DateTime.now().year - pickedDate.year);
    }
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType type = TextInputType.text, bool isPassword = false, String? validatorText}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: type,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        validator: (val) => val == null || val.isEmpty ? (validatorText ?? 'Required') : null,
      ),
    );
  }

  List<Step> _buildSteps() => [
    Step(
      title: Text('Personal'),
      isActive: _currentStep >= 0,
      content: Column(
        children: [
          _buildTextField(_nameController, 'Full Name'),
          _buildTextField(_fatherNameController, 'Father\'s Name'),
          _buildTextField(_motherNameController, 'Mother\'s Name'),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDOB,
                  icon: Icon(Icons.calendar_today),
                  label: Text(_dobController.text.isEmpty ? 'Select DOB' : _dobController.text),
                ),
              ),
              if (_calculatedAge != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text('Age: $_calculatedAge'),
                ),
            ],
          ),
          _buildTextField(_educationController, 'Education'),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gender', style: TextStyle(fontSize: 16)),
              Row(
                children: ['MALE', 'FEMALE', 'OTHERS'].map((gender) {
                  return Row(
                    children: [
                      Radio<String>(
                        value: gender,
                        groupValue: _selectedGender,
                        onChanged: (value) => setState(() => _selectedGender = value),
                      ),
                      Text(gender),
                    ],
                  );
                }).toList(),
              ),
              if (_selectedGender == 'OTHERS')
                _buildTextField(TextEditingController(), 'Please specify'),
            ],
          ),
        ],
      ),
    ),
    Step(
      title: Text('Location'),
      isActive: _currentStep >= 1,
      content: Column(
        children: [
          _buildTextField(_addressController, 'Postal Address'),
          DropdownButtonFormField<String>(
            value: _selectedState,
            decoration: InputDecoration(labelText: 'State', border: OutlineInputBorder()),
            items: states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) => setState(() => _selectedState = val),
          ),
          _buildTextField(_constituencyController, 'Constituency'),
          DropdownButtonFormField<String>(
            value: _selectedParty,
            decoration: InputDecoration(labelText: 'Political Party', border: OutlineInputBorder()),
            items: parties.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (val) => setState(() => _selectedParty = val),
          ),
        ],
      ),
    ),
    Step(
      title: Text('Authentication'),
      isActive: _currentStep >= 2,
      content: Column(
        children: [
          _buildTextField(_phoneController, 'Phone Number', type: TextInputType.phone),
          if (!_isPhoneVerified)
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OtpScreen(
                      phoneNumber: "+91${_phoneController.text.trim()}",
                      aadhaarNumber: widget.aadhaarNumber,
                      userType: 'nomination',
                    ),
                  ),
                );
                if (result == true) {
                  setState(() => _isPhoneVerified = true);
                }
              },
              child: Text('Verify Phone Number'),
            ),
          if (_isPhoneVerified) ...[
            _buildTextField(_passwordController, 'Password', isPassword: true),
            _buildTextField(_confirmPasswordController, 'Confirm Password', isPassword: true),
          ],
        ],
      ),
    ),
    Step(
      title: Text('e-KYC'),
      isActive: _currentStep >= 3,
      content: Column(
        children: [
          _photo != null ? Image.file(_photo!, height: 100) : Text('No photo selected'),
          ElevatedButton.icon(
            onPressed: () => _pickPhoto(widget.aadhaarNumber),
            icon: Icon(Icons.image),
            label: Text('Upload Photo'),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _captureVideo(widget.aadhaarNumber),
            icon: Icon(Icons.videocam),
            label: Text(_video != null ? 'Video Captured ✅' : 'Capture Face Video'),
          ),
        ],
      ),
    ),
  ];

  Future<void> _submitNomination() async {
    final nominationRef = FirebaseFirestore.instance.collection('nominations');

    // Check if the nomination already exists for this Aadhaar number
    final existingNomination = await nominationRef.doc(widget.aadhaarNumber).get();

    if (existingNomination.exists) {
      // Navigate to the status screen if nomination already exists
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NominationTab()),
      );
      return;
    }

    // Save the nomination
    await nominationRef.doc(widget.aadhaarNumber).set({
      'name': _nameController.text,
      'father_name': _fatherNameController.text,
      'mother_name': _motherNameController.text,
      'dob': _dobController.text,
      'education': _educationController.text,
      'address': _addressController.text,
      'phone': _phoneController.text,
      'gender': _selectedGender,
      'state': _selectedState,
      'party': _selectedParty,
      'constituency': _constituencyController.text,
      'photo': photoUrl,
      'video': videoUrl,
    });

    // Navigate to NominationStatusScreen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NominationTab()),
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _nameController.text.isNotEmpty &&
            _fatherNameController.text.isNotEmpty &&
            _motherNameController.text.isNotEmpty &&
            _dobController.text.isNotEmpty &&
            _educationController.text.isNotEmpty;
      case 1:
        return _addressController.text.isNotEmpty &&
            _selectedState != null &&
            _constituencyController.text.isNotEmpty &&
            _selectedParty != null;
      case 2:
        if (!_isPhoneVerified) return false;
        return _passwordController.text.isNotEmpty &&
            _confirmPasswordController.text == _passwordController.text;
      case 3:
        return _photo != null && _video != null;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nomination')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_validateCurrentStep()) {
            if (_currentStep == 3) {
              _submitNomination();
            } else {
              setState(() => _currentStep++);
            }
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        steps: _buildSteps(),
      ),
    );
  }
}
