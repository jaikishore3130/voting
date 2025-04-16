import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ElectionControlScreen extends StatefulWidget {
  final String role;
  final String uid;
  final String? state; // Only needed for State EC Heads

  const ElectionControlScreen({
    required this.role,
    required this.uid,
    this.state,
    Key? key,
  }) : super(key: key);

  @override
  State<ElectionControlScreen> createState() => _ElectionControlScreenState();
}

class _ElectionControlScreenState extends State<ElectionControlScreen> {
  String _electionType = 'lok_sabha';
  DateTime? nominationStart;
  DateTime? nominationEnd;
  DateTime? pollingStart;
  DateTime? pollingEnd;

  final _formKey = GlobalKey<FormState>();

  bool get isAuthorized {
    if (_electionType == 'vidhan_sabha') {
      return widget.role == 'ec_head' ||
          widget.role == 'ec_deputy' ||
          widget.role == 'state_ec_1' ||
          widget.role == 'state_ec_2';
    } else {
      return widget.role == 'EC_HEAD' || widget.role == 'EC_DEPUTY';
    }
  }

  Future<void> _pickDate(String label, Function(DateTime) onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _submitActivationRequest() async {
    if (!isAuthorized) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⛔ Not authorized to activate this election.'),
      ));
      return;
    }

    if (nominationStart == null ||
        nominationEnd == null ||
        pollingStart == null ||
        pollingEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⚠️ Please select all dates.'),
      ));
      return;
    }

    final data = {
      'election_type': _electionType,
      'state': _electionType == 'vidhan_sabha' ? widget.state : null,
      'status': 'pending',
      'nominations_start': nominationStart,
      'nominations_end': nominationEnd,
      'polling_start': pollingStart,
      'polling_end': pollingEnd,
      'requested_by': widget.uid,
      'timestamp': Timestamp.now(),
    };

    await FirebaseFirestore.instance.collection('election_status').add(data);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ Activation request sent successfully.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text("🗳️ Election Control Panel", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _electionType,
              onChanged: (value) => setState(() => _electionType = value!),
              items: [
                DropdownMenuItem(value: 'lok_sabha', child: Text('Lok Sabha')),
                DropdownMenuItem(value: 'rajya_sabha', child: Text('Rajya Sabha')),
                DropdownMenuItem(value: 'vidhan_sabha', child: Text('Vidhan Sabha')),
              ],
              decoration: InputDecoration(labelText: 'Select Election Type'),
            ),

            SizedBox(height: 10),
            _buildDateTile("Nomination Start Date", nominationStart, (date) => setState(() => nominationStart = date)),
            _buildDateTile("Nomination End Date", nominationEnd, (date) => setState(() => nominationEnd = date)),
            _buildDateTile("Polling Start Date", pollingStart, (date) => setState(() => pollingStart = date)),
            _buildDateTile("Polling End Date", pollingEnd, (date) => setState(() => pollingEnd = date)),

            if (_electionType == 'vidhan_sabha')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text("📍 State: ${widget.state ?? 'Not Set'}"),
              ),

            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _submitActivationRequest,
              icon: Icon(Icons.how_to_vote),
              label: Text('Send Activation Request'),
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime? value, Function(DateTime) onPick) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value == null ? 'Tap to select' : value.toLocal().toString().split(' ')[0]),
      trailing: Icon(Icons.calendar_today),
      onTap: () => _pickDate(label, onPick),
    );
  }
}
