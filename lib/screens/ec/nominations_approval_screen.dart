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
  _NominationsApprovalScreenState createState() =>
      _NominationsApprovalScreenState();
}

class _NominationsApprovalScreenState extends State<NominationsApprovalScreen> {
  List<Map<String, dynamic>> nominations = [];
  bool isloading=true;

  @override
  void initState() {
    super.initState();
    fetchNominations();
  }

  Future<void> fetchNominations() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('nominations')
        .doc('list')
        .collection(widget.subCollectionId)
        .get();

    final allDocs = querySnapshot.docs;

    if (allDocs.isNotEmpty) {
      setState(() {
        nominations = allDocs.map((doc) {
          final data = doc.data();
          data['aadhaar'] = doc.id; // Add Aadhaar number from doc.id
          return data;
        }).toList();
      });
    } else {
      print("No nominations found.");
      setState(() {
        nominations = [];
      });
    }
  }

  void showCandidateDetails(Map<String, dynamic> candidateData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(candidateData['name'] ?? 'Candidate'),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildInfo('Aadhaar', candidateData['aadhaar']),
                buildInfo('Name', candidateData['name']),
                buildInfo('Gender', candidateData['gender']),
                buildInfo('DOB', candidateData['dob']),
                buildInfo('Father Name', candidateData['father_name']),
                buildInfo('Mother Name', candidateData['mother_name']),
                buildInfo('Education', candidateData['education']),
                buildInfo('Phone', candidateData['phone']),
                buildInfo('State', candidateData['state']),
                buildInfo('Constituency', candidateData['constituency']),
                buildInfo('Address', candidateData['address'] ?? '500037'),


                const SizedBox(height: 20),
                if (widget.role == 'EC_HEAD' || widget.role == 'EC_DEPUTY_HEAD')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => approveNomination(candidateData),
                        child: Text('Approve'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => rejectNomination(candidateData),
                        child: Text('Reject'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildInfo(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text('$label: ${value ?? "-"}'),
    );
  }

  Future<void> approveNomination(Map<String, dynamic> data) async {
    final partyName = data['party'];
    final aadhaar = data['aadhaar']; // Get from fetched data
    final subCollectionId = widget.subCollectionId;

    final docRef = FirebaseFirestore.instance


        .collection('election_status')
        .doc('lok_sabha')
        .collection(subCollectionId)
        .doc('party')
        .collection('list')
        .doc(partyName)
        .collection('candidates')
        .doc(aadhaar); // ✅ use Aadhaar from nomination doc

    await docRef.set(data);


    // Remove the nomination from Firestore
    final docReff = FirebaseFirestore.instance
        .collection('nominations')
        .doc('list')
        .collection(subCollectionId)
        .doc(aadhaar); // Use Aadhaar as the doc ID for nomination

    await docReff.delete(); // Delete the document from Firestore

    // Remove the nomination from the list
    setState(() {
      nominations.removeWhere((candidate) => candidate['aadhaar'] == aadhaar);
    });

    // If there are no more candidates, show a "No more candidates" message
    if (nominations.isEmpty) {
      await Future.delayed(Duration(seconds: 3)); // Show circular progress for 3 seconds
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No more candidates to approve.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nomination Approved')),
      );
    }
  }

  Future<void> rejectNomination(Map<String, dynamic> data) async {
    String reason = '';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Reject Reason"),
        content: TextField(
          onChanged: (value) => reason = value,
          decoration: InputDecoration(hintText: 'Enter reason for rejection'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: Text("Submit"),
          ),
        ],
      ),
    );

    if (reason.isNotEmpty) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rejected with reason: $reason')),
      );
      // Optional: Store rejection reason in Firestore if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nominations Approval')),
      body: nominations.isEmpty
          ? Center(
        child: FutureBuilder(
          future: Future.delayed(Duration(seconds: 3)),
          builder: (context, snapshot) {
            // Check if the delay has completed and show the message
            if (snapshot.connectionState == ConnectionState.done) {
              return Text('No more candidates');
            } else {
              return CircularProgressIndicator(); // Show loading spinner while waiting
            }
          },
        ),
      )
          : ListView.builder(
        itemCount: nominations.length,
        itemBuilder: (context, index) {
          final candidate = nominations[index];
          return ListTile(
            title: Text(candidate['name'] ?? 'No Name'),
            subtitle: Text(candidate['party'] ?? 'Unknown Party'),
            onTap: () => showCandidateDetails(candidate),
          );
        },
      ),
    );
  }}
