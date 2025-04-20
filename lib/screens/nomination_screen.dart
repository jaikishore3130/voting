import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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

  Future<void> _pickPhoto() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _photo = File(pickedFile.path));
    }
  }

  Future<void> _captureVideo() async {
    final pickedVideo = await picker.pickVideo(source: ImageSource.camera);
    if (pickedVideo != null) {
      setState(() => _video = File(pickedVideo.path));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('🎥 Video captured')));
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
                  label: Text(
                    _dobController.text.isEmpty ? 'Select DOB' : _dobController.text,
                  ),
                ),
              ),
              SizedBox(width: 12),
              if (_calculatedAge != null)
                Text('Age: $_calculatedAge', style: TextStyle(fontSize: 16)),
            ],
          ),
          _buildTextField(_educationController, 'Education'),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gender', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              Row(
                children: ['MALE', 'FEMALE', 'OTHERS'].map((gender) {
                  return Row(
                    children: [
                      Radio<String>(
                        value: gender,
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() => _selectedGender = value);
                        },
                      ),
                      Text(gender),
                      SizedBox(width: 10),
                    ],
                  );
                }).toList(),
              ),
              if (_selectedGender == 'OTHERS')
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _buildTextField(TextEditingController(), 'Please specify', validatorText: 'Required'),
                ),
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
                      aadhaarNumber: widget.aadhaarNumber, // ensure you have this controller
                      userType: 'nomination',
                    ),
                  ),
                );

                if (result == true) {
                  setState(() {
                    _isPhoneVerified = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Phone number verified!")));
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
          _photo != null
              ? Image.file(_photo!, height: 120)
              : Text('No photo selected'),
          ElevatedButton.icon(
            onPressed: _pickPhoto,
            icon: Icon(Icons.upload_file),
            label: Text('Upload Photo'),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _captureVideo,
            icon: Icon(Icons.videocam),
            label: Text(_video != null ? 'Video Captured ✅' : 'Capture Face Video'),
          ),
        ],
      ),
    ),
  ];

  Future<void> _submitNomination() async {
    if (_formKey.currentState!.validate()) {
      // Store the data in Firestore
      await FirebaseFirestore.instance.collection('nominations').add({
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
        'photo': _photo?.path,  // Store photo path or URL here
        'video': _video?.path,  // Store video path or URL here
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Nomination Submitted')));
      // Optionally navigate to the next screen or show a confirmation.
    }
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
        return _phoneController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty &&
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
      appBar: AppBar(title: Text('Nomination Form')),
      body: Form(
      key: _formKey,
      child:
    Stepper(
        currentStep: _currentStep,
      onStepContinue: () {
        if (_validateCurrentStep()) {
          if (_currentStep < _buildSteps().length - 1) {
            setState(() => _currentStep++);
          } else {
            _submitNomination();
          }
        }
      },


      onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        steps: _buildSteps(),
        type: StepperType.vertical,
      ),
    ),);
  }
}
