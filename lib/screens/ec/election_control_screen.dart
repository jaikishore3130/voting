import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  final allSubCollectionIds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSubCollectionIds();  // Fetch the stored election IDs
    _fetchElections();
    _timer = Timer.periodic(Duration(seconds: 10), (_) => _autoUpdateStatuses());
  }


  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchElections() async {
    final ongoing = <Map<String, dynamic>>[];
    final completed = <Map<String, dynamic>>[];

    // Step 1: Get the `lok_sabha` document reference
    final lokSabhaDocRef = FirebaseFirestore.instance.collection('election_status').doc('lok_sabha');

    // Step 2: Workaround to get all subcollections under 'lok_sabha'
    // Firestore doesn’t support listing subcollections directly on web, so we simulate:


    for (final subColId in allSubCollectionIds) {
      try {
        final docSnapshot = await lokSabhaDocRef
            .collection(subColId)
            .doc('election_info')
            .get();

        final data = docSnapshot.data();
        if (data == null) continue;

        data['election_id'] = subColId;
        data['election_type'] = 'lok_sabha';

        final status = data['status'];
        if (status == 'pending_approval' ||
            status == 'nominations_open' ||
            status == 'polling_open') {
          ongoing.add(data);
        } else if (status == 'completed' ||
            status == 'aborted' ||
            status == 'rejected') {
          completed.add(data);
        }
      } catch (e) {
        print("❌ Error reading $subColId: $e");
      }
    }

    // Step 3: Update UI
    setState(() {
      ongoingElections = ongoing;
      completedElections = completed;
    });
  }


  Future<void> _autoUpdateStatuses() async {
    final snapshot = await FirebaseFirestore.instance
        .collectionGroup('election_info')
        .get();

    final now = DateTime.now();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final ref = doc.reference;
      final status = data['status'];

      final nominationEnd = (data['nominations_end'] as Timestamp).toDate();
      final pollingEnd = (data['polling_end'] as Timestamp).toDate();

      if (status == 'nominations_open' && now.isAfter(nominationEnd)) {
        await ref.update({'status': 'polling_open'});
      } else if (status == 'polling_open' && now.isAfter(pollingEnd)) {
        await ref.update({'status': 'completed'});
      }
    }

    await _fetchElections();
  }

  // Step 1: Declare the list where all the election IDs are stored


// Step 2: Modify _showCreateElectionDialog() to add the election ID to the list dynamically
  // Step 4: Add the election ID to Firestore central election control
  Future<void> _showCreateElectionDialog() async {
    String electionType = 'lok_sabha';
    DateTime? nominationStart, nominationEnd, pollingStart, pollingEnd;

    Future<void> pickDateTime(Function(DateTime) onPicked) async {
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
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

              // Step 3: Generate the election ID dynamically
              final electionId = '${electionType}_${DateFormat('MM-dd-yyyy_HH-mm-ss').format(DateTime.now())}';

              final docRef = FirebaseFirestore.instance
                  .collection('election_status')
                  .doc(electionType)
                  .collection(electionId)
                  .doc('election_info');

              await docRef.set({
                'election_id': electionId,
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

              // Step 4: Update Firestore central document with the new election ID
              final electionControlRef = FirebaseFirestore.instance.collection('election_control').doc('central_election_info');

// Check if the document exists
              final docSnapshot = await electionControlRef.get();

              if (!docSnapshot.exists) {
                // If the document doesn't exist, create it with an empty sub_collection_ids list
                await electionControlRef.set({
                  'sub_collection_ids': [electionId] // Add the electionId to the array
                });
              } else {
                // If the document exists, just update the sub_collection_ids field
                await electionControlRef.update({
                  'sub_collection_ids': FieldValue.arrayUnion([electionId])
                });
              }


              // Step 5: Refetch the elections
              setState(() {
                allSubCollectionIds.add(electionId);
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
  Future<void> _fetchSubCollectionIds() async {
    final electionControlRef = FirebaseFirestore.instance.collection('election_control').doc('central_election_info');
    final docSnapshot = await electionControlRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null && data.containsKey('sub_collection_ids')) {
        setState(() {
          allSubCollectionIds.addAll(List<String>.from(data['sub_collection_ids']));
        });
      }
    }
  }


  Widget _dateField(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(date != null ? DateFormat('yyyy-MM-dd HH:mm').format(date) : 'Select $label'),
      ),
    );
  }

  void _showElectionActions(Map<String, dynamic> election) {
    final status = election['status'];
    final pollingEnd = (election['polling_end'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Election: ${election['election_type']}"),
        content: Text("Status: ${status.replaceAll('_', ' ').toUpperCase()}"),
        actions: [
          if (widget.role == 'EC_HEAD' && status != 'completed')
            TextButton(
              onPressed: () async {
                final docRef = FirebaseFirestore.instance
                    .collection('election_status')
                    .doc(election['election_type'])
                    .collection(election['election_id'])
                    .doc('election_info');
                await docRef.update({'status': 'aborted'});
                Navigator.pop(context);
                _fetchElections();
              },
              child: Text("Abort 🛑", style: TextStyle(color: Colors.red)),
            ),
          if (widget.role == 'EC_DEPUTY_HEAD' && status == 'pending_approval') ...[
            TextButton(
              onPressed: () async {
                final docRef = FirebaseFirestore.instance
                    .collection('election_status')
                    .doc(election['election_type'])
                    .collection(election['election_id'])
                    .doc('election_info');
                await docRef.update({
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
                final docRef = FirebaseFirestore.instance
                    .collection('election_status')
                    .doc(election['election_type'])
                    .collection(election['election_id'])
                    .doc('election_info');
                await docRef.update({
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

  Widget _buildElectionTile(Map<String, dynamic> election) {
    // Handle the timestamp conversion if it exists in the election map
    DateTime? electionDate;
    if (election['timestamp'] is Timestamp) {
      electionDate = election['timestamp'].toDate();  // Convert Timestamp to DateTime
    } else if (election['timestamp'] is String) {
      electionDate = DateTime.parse(election['timestamp']);  // Convert String to DateTime
    }

    final type = election['election_type']?.toString().toUpperCase();
    final status = election['status']?.toString().replaceAll('_', ' ').toUpperCase();

    return ListTile(
      title: Text(type ?? "ELECTION"),
      subtitle: Text("Status: $status"),
      trailing: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status ?? '',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
      onTap: () => _showElectionActions(election),
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
