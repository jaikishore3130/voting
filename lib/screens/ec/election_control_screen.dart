import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ElectionControlScreen extends StatefulWidget {
  final String role;
  final String uid;
  final String? state;

  const ElectionControlScreen({
    required this.role,
    required this.uid,
    this.state,
    Key? key,
  }) : super(key: key);

  @override
  State<ElectionControlScreen> createState() => _ElectionControlScreenState();
}

class _ElectionControlScreenState extends State<ElectionControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> ongoingElections = [];
  List<Map<String, dynamic>> completedElections = [];
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel(); // Safely cancels only if initialized
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchElections(); // Fetch elections initially
    _timer = Timer.periodic(Duration(seconds: 10), (_) => _autoUpdateStatuses());
  }

  // Fetch elections from Firestore
  Future<void> _fetchElections() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('election_status')
        .orderBy('timestamp', descending: true)
        .get();

    final elections = snapshot.docs.map((doc) => doc.data()).toList();

    setState(() {
      ongoingElections = elections.where((e) {
        final status = e['status'];
        return status != 'completed' && status != 'aborted' && status != 'rejected';
      }).toList();

      completedElections = elections.where((e) {
        final status = e['status'];
        return status == 'completed' || status == 'aborted' || status == 'rejected';
      }).toList();
    });
  }

  // Auto update election statuses
  Future<void> _autoUpdateStatuses() async {
    final snapshot = await FirebaseFirestore.instance.collection('election_status').get();
    final now = DateTime.now();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status'];

      final nominationEnd = (data['nominations_end'] as Timestamp).toDate();
      final pollingStart = (data['polling_start'] as Timestamp).toDate();
      final pollingEnd = (data['polling_end'] as Timestamp).toDate();

      if (status == 'nominations_open' && now.isAfter(nominationEnd)) {
        await doc.reference.update({'status': 'polling_open'});
      } else if (status == 'polling_open' && now.isAfter(pollingEnd)) {
        await doc.reference.update({'status': 'completed'});
      }
    }
  }

  // Show dialog to create a new election
  void _showCreateElectionDialog() {
    String electionType = 'lok_sabha';
    DateTime? nominationStart, nominationEnd, pollingStart, pollingEnd;

    Future<void> pickDateTime(Function(DateTime) onPicked) async {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );
      if (pickedDate == null) return;

      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime == null) return;

      final finalDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
      onPicked(finalDateTime);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Create New Election"),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: electionType,
                  onChanged: (val) => setState(() => electionType = val!),
                  items: [
                    DropdownMenuItem(value: 'lok_sabha', child: Text('Lok Sabha')),
                    DropdownMenuItem(value: 'rajya_sabha', child: Text('Rajya Sabha')),
                    DropdownMenuItem(value: 'vidhan_sabha', child: Text('Vidhan Sabha')),
                  ],
                  decoration: InputDecoration(labelText: 'Election Type'),
                ),
                SizedBox(height: 10),
                _dateField("Nomination Start", nominationStart, () => pickDateTime((dt) => setState(() => nominationStart = dt))),
                _dateField("Nomination End", nominationEnd, () => pickDateTime((dt) => setState(() => nominationEnd = dt))),
                _dateField("Polling Start", pollingStart, () => pickDateTime((dt) => setState(() => pollingStart = dt))),
                _dateField("Polling End", pollingEnd, () => pickDateTime((dt) => setState(() => pollingEnd = dt))),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if ([nominationStart, nominationEnd, pollingStart, pollingEnd].contains(null)) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("⚠️ All fields are required")));
                return;
              }

              final doc = FirebaseFirestore.instance.collection('election_status').doc();
              await doc.set({
                'election_id': doc.id,
                'election_type': electionType,
                'nominations_start': nominationStart,
                'nominations_end': nominationEnd,
                'polling_start': pollingStart,
                'polling_end': pollingEnd,
                'status': 'pending_approval',
                'approvals': {
                  'ec_head': true,
                  'ec_deputy': false,
                },
                'created_by': widget.uid,
                'timestamp': Timestamp.now(),
              });

              Navigator.pop(context);
              _fetchElections();
            },
            child: Text("Create"),
          ),
        ],
      ),
    );
  }

  // Helper function to display date fields
  Widget _dateField(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(date != null ? date.toString() : 'Select $label'),
      ),
    );
  }

  // Show actions for an election
  void _showElectionActions(Map<String, dynamic> election) {
    final isHead = widget.role == 'EC_HEAD';
    final isDeputy = widget.role == 'EC_DEPUTY_HEAD';
    final status = election['status'];
    final pollingEnd = (election['polling_end'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Election: ${election['election_type']}"),
        content: Text("Status: ${status.replaceAll('_', ' ').toUpperCase()}"),
        actions: [
          if (isHead && pollingEnd.isAfter(DateTime.now()) && status != 'completed' && status != 'aborted')
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('election_status')
                    .doc(election['election_id'])
                    .update({'status': 'aborted'});

                Navigator.pop(context);
                _fetchElections();
              },
              child: Text("Abort 🛑", style: TextStyle(color: Colors.red)),
            ),
          if (isDeputy && status == 'pending_approval') ...[
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('election_status')
                    .doc(election['election_id'])
                    .update({
                  'status': 'nominations_open',
                  'approvals.ec_deputy': true,
                });

                Navigator.pop(context);
                _fetchElections();
              },
              child: Text("Approve ✅"),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('election_status')
                    .doc(election['election_id'])
                    .update({
                  'status': 'rejected',
                  'approvals.ec_deputy': false,
                });

                Navigator.pop(context);
                _fetchElections();
              },
              child: Text("Reject ❌", style: TextStyle(color: Colors.red)),
            ),
          ]
        ],
      ),
    );
  }

  // Build the election tile for each election
  Widget _buildElectionTile(Map<String, dynamic> e) {
    final status = e['status']?.toString().replaceAll('_', ' ').toUpperCase();
    final type = e['election_type']?.toString().toUpperCase();
    return ListTile(
      title: Text("$type"),
      subtitle: Text("Status: $status"),
      onTap: () => _showElectionActions(e),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🗳️ Election Control"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Ongoing Elections"),
            Tab(text: "Completed Elections"),
          ],
        ),
        actions: [
          if (widget.role == 'EC_HEAD')
            IconButton(
              icon: Icon(Icons.add_circle_outline),
              onPressed: _showCreateElectionDialog,
              tooltip: "Create Election",
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ongoingElections.isEmpty
              ? Center(child: Text("No ongoing elections."))
              : ListView(children: ongoingElections.map(_buildElectionTile).toList()),
          completedElections.isEmpty
              ? Center(child: Text("No completed elections."))
              : ListView(children: completedElections.map(_buildElectionTile).toList()),
        ],
      ),
    );
  }
}
