import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class NominationScreen extends StatefulWidget {
  final String aadhaarNumber;

  const NominationScreen({required this.aadhaarNumber, Key? key}) : super(key: key);

  @override
  _NominationScreenState createState() => _NominationScreenState();
}

class _NominationScreenState extends State<NominationScreen> {
  final _formKey = GlobalKey<FormState>();

  final picker = ImagePicker();

  File? _photo;
  File? _symbol;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _educationController = TextEditingController();
  final TextEditingController _generalVotesController = TextEditingController();
  final TextEditingController _postalVotesController = TextEditingController();
  final TextEditingController _totalElectorsController = TextEditingController();
  final TextEditingController _totalVotesController = TextEditingController();
  final TextEditingController _criminalCasesController = TextEditingController();
  final TextEditingController _assetsController = TextEditingController();
  final TextEditingController _liabilitiesController = TextEditingController();
  final TextEditingController _overElectorsController = TextEditingController();
  final TextEditingController _overVotesPolledController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _customGenderController = TextEditingController();

  String? _selectedGender = 'MALE';
  String? _selectedState;
  String? _selectedParty;
  bool _isWinner = false;
  bool _isSubmitting = false;

  final List<String> states = ['Bihar', 'Maharashtra', 'Tamil Nadu', 'Karnataka'];
  final List<String> parties = ['BJP', 'INC', 'AAP', 'CPI', 'Independent'];

  Future<void> _pickImage(ImageSource source, bool isPhoto) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        if (isPhoto) {
          _photo = File(pickedFile.path);
        } else {
          _symbol = File(pickedFile.path);
        }
      });
    }
  }

  bool _isValidAadhaar(String input) => RegExp(r'^[2-9]{1}[0-9]{11}\$').hasMatch(input);
  bool _isValidPhone(String input) => RegExp(r'^[6-9]{1}[0-9]{9}\$').hasMatch(input);
  bool _isValidPassword(String input) => input.length >= 6;

  Future<void> _submitNomination() async {
    if (_formKey.currentState!.validate() && _photo != null && _symbol != null) {
      setState(() => _isSubmitting = true);

      final nominationData = {
        'aadhaar_number': widget.aadhaarNumber,
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'education': _educationController.text.trim(),
        'gender': _selectedGender == 'OTHERS' ? _customGenderController.text.trim() : _selectedGender,
        'general_votes': int.parse(_generalVotesController.text.trim()),
        'postal_votes': int.parse(_postalVotesController.text.trim()),
        'total_electors': int.parse(_totalElectorsController.text.trim()),
        'total_votes': int.parse(_totalVotesController.text.trim()),
        'criminal_cases': _criminalCasesController.text.trim(),
        'assets': _assetsController.text.trim(),
        'liabilities': _liabilitiesController.text.trim(),
        'over_total_electors': double.parse(_overElectorsController.text.trim()),
        'over_total_votes_polled': double.parse(_overVotesPolledController.text.trim()),
        'address': _addressController.text.trim(),
        'password': _passwordController.text.trim(),
        'phone_number': int.parse(_phoneController.text.trim()),
        'party': _selectedParty,
        'state': _selectedState,
        'winner': _isWinner ? 1 : 0,
        'submitted_at': Timestamp.now(),
        'status': 'pending',
      };

      try {
        await FirebaseFirestore.instance
            .collection('nominations')
            .doc(widget.aadhaarNumber)
            .set(nominationData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Nomination submitted successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Failed to submit: $e')),
        );
      }

      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text,
        bool isPassword = false,
        String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: validator ?? (value) => value == null || value.trim().isEmpty ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ECI Nomination Form')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_nameController, 'Full Name'),
              _buildTextField(_ageController, 'Age', keyboardType: TextInputType.number),
              _buildTextField(_educationController, 'Education'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gender', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: ['MALE', 'FEMALE', 'OTHERS'].map((gender) {
                      return Row(
                        children: [
                          Radio<String>(
                            value: gender,
                            groupValue: _selectedGender,
                            onChanged: (val) => setState(() => _selectedGender = val),
                          ),
                          Text(gender),
                        ],
                      );
                    }).toList(),
                  ),
                  if (_selectedGender == 'OTHERS')
                    _buildTextField(_customGenderController, 'Please specify'),
                ],
              ),
              DropdownButtonFormField<String>(
                value: _selectedState,
                items: states.map((state) => DropdownMenuItem(value: state, child: Text(state))).toList(),
                onChanged: (val) => setState(() => _selectedState = val),
                decoration: InputDecoration(labelText: 'State'),
                validator: (val) => val == null ? 'Please select state' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedParty,
                items: parties.map((party) => DropdownMenuItem(value: party, child: Text(party))).toList(),
                onChanged: (val) => setState(() => _selectedParty = val),
                decoration: InputDecoration(labelText: 'Political Party'),
                validator: (val) => val == null ? 'Please select party' : null,
              ),
              _buildTextField(_generalVotesController, 'General Votes', keyboardType: TextInputType.number),
              _buildTextField(_postalVotesController, 'Postal Votes', keyboardType: TextInputType.number),
              _buildTextField(_totalElectorsController, 'Total Electors', keyboardType: TextInputType.number),
              _buildTextField(_totalVotesController, 'Total Votes', keyboardType: TextInputType.number),
              _buildTextField(_criminalCasesController, 'Criminal Cases'),
              _buildTextField(_assetsController, 'Assets (e.g. Rs 15,00,000)'),
              _buildTextField(_liabilitiesController, 'Liabilities'),
              _buildTextField(_overElectorsController, 'Votes over Electors %', keyboardType: TextInputType.number),
              _buildTextField(_overVotesPolledController, 'Votes over Votes Polled %', keyboardType: TextInputType.number),
              _buildTextField(_addressController, 'Address'),
              _buildTextField(_passwordController, 'Password', isPassword: true, validator: (value) => !_isValidPassword(value!) ? 'Min 6 chars' : null),
              _buildTextField(_phoneController, 'Phone Number', keyboardType: TextInputType.phone, validator: (value) => !_isValidPhone(value!) ? 'Invalid phone' : null),
              SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(value: _isWinner, onChanged: (val) => setState(() => _isWinner = val!)),
                  Text('Winner')
                ],
              ),
              SizedBox(height: 12),
              Text('Upload Candidate Photo'),
              _photo != null ? Image.file(_photo!, height: 100) : Container(),
              ElevatedButton.icon(
                icon: Icon(Icons.image),
                label: Text("Upload Photo"),
                onPressed: () => _pickImage(ImageSource.gallery, true),
              ),
              SizedBox(height: 12),
              Text('Upload Party Symbol'),
              _symbol != null ? Image.file(_symbol!, height: 100) : Container(),
              ElevatedButton.icon(
                icon: Icon(Icons.image),
                label: Text("Upload Symbol"),
                onPressed: () => _pickImage(ImageSource.gallery, false),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.how_to_vote),
                label: Text(_isSubmitting ? 'Submitting...' : 'Submit Nomination'),
                onPressed: _isSubmitting ? null : _submitNomination,
              )
            ],
          ),
        ),
      ),
    );
  }
}