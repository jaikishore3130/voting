import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NominationScreen extends StatefulWidget {
  final String aadhaarNumber;

  const NominationScreen({required this.aadhaarNumber, Key? key}) : super(key: key);

  @override
  _NominationScreenState createState() => _NominationScreenState();
}

class _NominationScreenState extends State<NominationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _fatherOrHusbandController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _constituencyController = TextEditingController();
  final TextEditingController _partyController = TextEditingController();
  final TextEditingController _symbolUrlController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _criminalCasesController = TextEditingController();
  final TextEditingController _assetsDeclarationController = TextEditingController();
  final TextEditingController _photoUrlController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submitNomination() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final nominationData = {
        'aadhaar': widget.aadhaarNumber,
        'full_name': _nameController.text.trim(),
        'father_or_husband_name': _fatherOrHusbandController.text.trim(),
        'gender': _genderController.text.trim(),
        'dob': _dobController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'email': _emailController.text.trim(),
        'state': _stateController.text.trim(),
        'constituency': _constituencyController.text.trim(),
        'party': _partyController.text.trim(),
        'symbol_url': _symbolUrlController.text.trim(),
        'address': _addressController.text.trim(),
        'criminal_cases': _criminalCasesController.text.trim(),
        'assets_declaration': _assetsDeclarationController.text.trim(),
        'photo_url': _photoUrlController.text.trim(),
        'status': 'pending',
        'submitted_at': Timestamp.now(),
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

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nomination Form (As per ECI)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_nameController, 'Full Name'),
              _buildTextField(_fatherOrHusbandController, 'Father/Husband Name'),
              _buildTextField(_genderController, 'Gender'),
              _buildTextField(_dobController, 'Date of Birth (DD-MM-YYYY)', keyboardType: TextInputType.datetime),
              _buildTextField(_mobileController, 'Mobile Number', keyboardType: TextInputType.phone),
              _buildTextField(_emailController, 'Email', keyboardType: TextInputType.emailAddress),
              _buildTextField(_stateController, 'State'),
              _buildTextField(_constituencyController, 'Constituency'),
              _buildTextField(_partyController, 'Political Party'),
              _buildTextField(_symbolUrlController, 'Party Symbol URL'),
              _buildTextField(_photoUrlController, 'Photo URL'),
              _buildTextField(_addressController, 'Permanent Address'),
              _buildTextField(_criminalCasesController, 'Criminal Cases (if any)'),
              _buildTextField(_assetsDeclarationController, 'Assets Declaration (URL or Summary)'),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.how_to_vote),
                label: Text(_isSubmitting ? "Submitting..." : "Submit Nomination"),
                onPressed: _isSubmitting ? null : _submitNomination,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
