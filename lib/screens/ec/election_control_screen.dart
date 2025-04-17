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
  List<String> indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal'
  ];

  String? _selectedState;

  final _formKey = GlobalKey<FormState>();
  late Future<List<Map<String, dynamic>>> _electionListFuture;

  @override
  void initState() {
    super.initState();
    _electionListFuture = _fetchActivatedElections();
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
    if (widget.role != 'EC_HEAD') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⛔ Only EC_HEAD can initiate elections.'),
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

    final docRef = FirebaseFirestore.instance.collection('election_status').doc();

    final data = {
      'election_id': docRef.id,
      'election_type': _electionType,
      'state': _electionType == 'vidhan_sabha' ? _selectedState : null,

      'status': 'initiated_by_ec_head',
      'approvals': {
        'ec_head': true,
        'ec_deputy': false,
        'state_approvals': {}
      },
      'nominations_open': false,
      'nominations_start': nominationStart,
      'nominations_end': nominationEnd,
      'polling_start': pollingStart,
      'polling_end': pollingEnd,
      'requested_by': widget.uid,
      'timestamp': Timestamp.now(),
    };

    final approvalsMap = data['approvals'] as Map<String, dynamic>;
    final stateApprovals = <String, bool>{};

    if (_electionType == 'vidhan_sabha' && widget.state != null) {
      final stateOfficersSnap = await FirebaseFirestore.instance
          .collection('ec_employees')
          .where('state', isEqualTo: widget.state)
          .where('role', isEqualTo: 'EC_STATE')
          .get();

      for (var doc in stateOfficersSnap.docs) {
        stateApprovals[doc.id] = false;
      }

      approvalsMap['state_approvals'] = stateApprovals;
    }

    await docRef.set(data);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ Activation initiated. Awaiting further approvals.'),
    ));

    setState(() {
      _electionListFuture = _fetchActivatedElections();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchActivatedElections() async {
    final query = FirebaseFirestore.instance
        .collection('election_status')
        .where('status', isNotEqualTo: null) // simple check
        .orderBy('timestamp', descending: true);

    final snapshot = await query.get();

    return snapshot.docs
        .where((doc) {
      final data = doc.data();
      if (widget.role == 'EC_STATE' && widget.state != null) {
        return data['state'] == widget.state;
      }
      return true;
    })
        .map((doc) => doc.data())
        .toList();
  }
  void _showElectionPopup(Map<String, dynamic> election) async {
    final approved = (election['approvals']?['ec_deputy'] ?? false) == true;
    final stateApprovals = Map<String, dynamic>.from(election['approvals']?['state_approvals'] ?? {});

    bool isECDeputy = widget.role == 'EC_DEPUTY';
    bool isECState = widget.role == 'EC_STATE' && widget.state != null;

    bool userAlreadyApproved = false;

    if (isECDeputy) {
      userAlreadyApproved = approved;
    } else if (isECState) {
      userAlreadyApproved = stateApprovals[widget.uid] == true;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Election Details"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Election Type: ${election['election_type']}"),
              if (election['state'] != null) Text("State: ${election['state']}"),
              Text("Status: ${election['status']}"),
              SizedBox(height: 20),
              if (!userAlreadyApproved) Text("Do you approve this election?"),
            ],
          ),
          actions: [
            if (!userAlreadyApproved) ...[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _approveElection(election);
                },
                child: Text("Accept ✅"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // optional: handle reject logic
                },
                child: Text("Reject ❌", style: TextStyle(color: Colors.red)),
              ),
            ] else if (isECDeputy && approved) ...[
              ElevatedButton(
                onPressed: () => _openNominations(election),
                child: Text("Open Nominations"),
              )
            ],
          ],
        );
      },
    );
  }
  Future<void> _approveElection(Map<String, dynamic> election) async {
    final docId = election['election_id'];
    final docRef = FirebaseFirestore.instance.collection('election_status').doc(docId);

    if (widget.role == 'EC_DEPUTY_HEAD') {
      // Mark EC Deputy approval
      await docRef.update({
        'approvals.ec_deputy': true,
      });

      final snapshot = await docRef.get();
      final data = snapshot.data();
      final electionType = data?['election_type']; // 'LOK SABHA' or 'VIDHAN SABHA'

      if (electionType == 'LOK SABHA') {
        // Open nominations immediately for LOK SABHA
        await _openNominations(election);
      }
      // For VIDHAN SABHA, do nothing here — wait for state approvals

    } else if (widget.role == 'EC_STATE' && widget.state != null) {
      // Mark state approval
      await docRef.update({
        'approvals.state_approvals.${widget.uid}': true,
      });

      // Fetch latest election data to check if all approvals are done
      final snapshot = await docRef.get();
      final data = snapshot.data();
      final stateApprovals = Map<String, dynamic>.from(data?['approvals']['state_approvals'] ?? {});
      final requiredStates = List<String>.from(data?['required_states'] ?? []); // Must be set during election creation

      final allStatesApproved = requiredStates.every((stateUid) => stateApprovals[stateUid] == true);
      final ecDeputyApproved = data?['approvals']['ec_deputy'] == true;

      // Open nominations if all state approvals and EC Deputy approval are done
      if (ecDeputyApproved && allStatesApproved) {
        await _openNominations(election);
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Approval Submitted')),
    );

    setState(() {
      _electionListFuture = _fetchActivatedElections();
    });
  }

  Future<void> _openNominations(Map<String, dynamic> election) async {
    final docId = election['election_id'];
    final docRef = FirebaseFirestore.instance.collection('election_status').doc(docId);

    await docRef.update({'nominations_open': true});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📢 Nominations are now open!')),
    );

    setState(() {
      _electionListFuture = _fetchActivatedElections();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text("🗳️ Election Control Panel",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            /// Only EC_HEAD sees the activation form
            if (widget.role == 'EC_HEAD') ...[
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
              if (_electionType == 'vidhan_sabha') ...[
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedState,
                  onChanged: (val) => setState(() => _selectedState = val),
                  items: indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  decoration: InputDecoration(labelText: 'Select State'),
                ),
              ],

              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submitActivationRequest,
                icon: Icon(Icons.how_to_vote),
                label: Text('Send Activation Request'),
                style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
              ),
              Divider(height: 40),
            ],

            /// For All Roles – Show Activated Elections List
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _electionListFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                final elections = snapshot.data ?? [];

                if (elections.isEmpty) {
                  return Text("📭 No activated elections found.");
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: elections.map((election) {
                    final type = election['election_type'];
                    final status = election['status'];
                    final approved = (election['approvals']?['ec_deputy'] ?? false) == true;

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text('🗳️ ${type.toUpperCase()} Election'),
                        onTap: () => _showElectionPopup(election),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: $status'),
                            if (election['state'] != null)
                              Text('State: ${election['state']}'),
                          ],
                        ),
                        trailing: approved
                            ? Chip(
                          label: Text('Nominations Open ✅'),
                          backgroundColor: Colors.green.shade100,
                        )
                            : Chip(
                          label: Text('Pending Approval'),
                          backgroundColor: Colors.orange.shade100,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
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
