import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NominationsApprovalScreen extends StatefulWidget {
  final String aadhaarNumber;
  final String subCollectionId;
  final String role;

  const NominationsApprovalScreen({
    required this.aadhaarNumber,
    required this.subCollectionId,
    required this.role,
    Key? key,
  }) : super(key: key);

  @override
  _NominationsApprovalScreenState createState() => _NominationsApprovalScreenState();
}

class _NominationsApprovalScreenState extends State<NominationsApprovalScreen> {
  List<String> allSubCollectionIds = [];
  List<Map<String, dynamic>> nominations = [];


  @override
  void initState() {
    super.initState();
    _fetchSubCollectionIds();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchSubCollectionIds(); // Re-fetch every time screen becomes visible
  }
  Future<void> _fetchSubCollectionIds() async {
    final electionControlRef = FirebaseFirestore.instance
        .collection('election_control')
        .doc('central_election_info');

    final docSnapshot = await electionControlRef.get();

    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      if (data != null && data.containsKey('sub_collection_ids')) {
        final allIds = List<String>.from(data['sub_collection_ids']);
        final filteredIds = <String>[];

        for (final id in allIds) {
          final nominationRef = FirebaseFirestore.instance
              .collection('nominations')
              .doc('list')
              .collection(id);

          final snapshot = await nominationRef.limit(1).get();

          if (snapshot.docs.isNotEmpty) {
            filteredIds.add(id);
          }
        }

        setState(() {
          allSubCollectionIds = filteredIds;
        });

        // After filtering, fetch nominations
        fetchNominations();
      }
    }
  }


  Future<void> fetchNominations() async {
    final List<Map<String, dynamic>> allNominations = [];

    for (String subId in allSubCollectionIds) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('nominations')
          .doc('list')
          .collection(subId)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['aadhaar'] = doc.id;
        data['subCollectionId'] = subId; // Store subId for future reference
        allNominations.add(data);
      }
    }

    setState(() {
      nominations = allNominations;
    });
  }

  Future<void> approveNomination(Map<String, dynamic> data) async {
    final partyName = data['party'];
    final aadhaar = data['aadhaar'];
    final subCollectionId = data['subCollectionId']; // 👈 dynamic value

    final docRefff = FirebaseFirestore.instance
        .collection('election_status')
        .doc('lok_sabha')
        .collection(subCollectionId)
        .doc('party')
        .collection('list')
        .doc(partyName)
        .collection('candidates')
        .doc(aadhaar);

    await docRefff.set(data);

      final electionControlRef = FirebaseFirestore.instance.collection('aa').doc('list');
      final docSnapshot = await electionControlRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('sub_collection_ids')) {
          setState(() {
            allSubCollectionIds.addAll(List<String>.from(data[aadhaar]));
          });
        }
      }



    final docRef = FirebaseFirestore.instance
        .collection('nominations')
        .doc('list')
        .collection(subCollectionId)
        .doc(aadhaar);

    await docRef.delete();

    setState(() {
      nominations.removeWhere((candidate) =>
      candidate['aadhaar'] == aadhaar &&
          candidate['subCollectionId'] == subCollectionId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nomination Approved')),
    );
  }

  Future<void> rejectNomination(Map<String, dynamic> data) async {
    String reason = '';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Reason for Rejection"),
        content: TextField(
          onChanged: (value) => reason = value,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter rejection reason',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (reason.isNotEmpty) {
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Rejected: $reason')),
                );
              }
            },
            child: Text("Submit"),
          ),
        ],
      ),
    );
  }

  void showCandidateDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            shrinkWrap: true,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    data['name'] ?? 'Candidate',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              Divider(),
              buildInfo('Aadhaar', data['aadhaar']),
              buildInfo('Gender', data['gender']),
              buildInfo('DOB', data['dob']),
              buildInfo('Father', data['father_name']),
              buildInfo('Mother', data['mother_name']),
              buildInfo('Education', data['education']),
              buildInfo('Phone', data['phone']),
              buildInfo('State', data['state']),
              buildInfo('Constituency', data['constituency']),
              buildInfo('Address', data['address']),
              const SizedBox(height: 20),
              if (widget.role == 'EC_HEAD' || widget.role == 'EC_DEPUTY_HEAD')
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        await approveNomination(data);
                        if (context.mounted) {
                          Navigator.pop(context); // 👈 Closes the popup after successful approval
                        }
                      },
                      icon: Icon(Icons.check),
                      label: Text("Approve"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),

                    ElevatedButton.icon(
                      onPressed: () => rejectNomination(data),
                      icon: Icon(Icons.close),
                      label: Text("Reject"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInfo(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$title: ", style: TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value ?? "-", overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nominations Approval', style: const TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.blue.shade900,
      ),
      body: nominations.isEmpty
          ? Center(
        child: FutureBuilder(
          future: Future.delayed(Duration(seconds: 3)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Text('No more candidates');
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      )
          : ListView.builder(
        itemCount: nominations.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final candidate = nominations[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade200,
                child: Icon(Icons.person, color: Colors.blueAccent),
              ),
              title: Text(candidate['name'] ?? 'Unnamed',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Party: ${candidate['party'] ?? 'Unknown'}"),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () => showCandidateDetails(candidate),
            ),
          );
        },
      ),
    );
  }
}
