import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voting/screens/voter/vote_now_screen.dart';

class VotingScreen extends StatefulWidget {
  final Map<String, dynamic> election;
  final String aadhaar;

  const VotingScreen({
    Key? key,
    required this.election,
    required this.aadhaar,
  }) : super(key: key);

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  List<String> allSubCollectionIds = [];
  bool isLoading = true;
  Map<String, dynamic>? selectedCandidate;
  String? selectedElectionId;
  List<Map<String, dynamic>> candidates = [];

  @override
  void initState() {
    super.initState();
    print("🗳️ Election: ${widget.election}");
    print("🧑‍💼 Voter Aadhaar: ${widget.aadhaar}");
    _fetchSubCollectionIds();
  }

  Future<void> _fetchSubCollectionIds() async {
    try {
      final electionControlRef = FirebaseFirestore.instance
          .collection('election_control')
          .doc('central_election_info');

      final docSnapshot = await electionControlRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data.containsKey('sub_collection_ids')) {
          final ids = List<String>.from(data['sub_collection_ids']);

          for (final id in ids) {
            final type = id.split('_').first;
            final statusDoc = await FirebaseFirestore.instance
                .collection('election_status')
                .doc('lok_sabha')
                .collection(id)
                .doc('election_info')
                .get();

            if (statusDoc.exists &&
                statusDoc.data()?['status'] == 'polling_open') {
              final allCandidates = await _fetchAllCandidates(id);

              setState(() {
                allSubCollectionIds = [id];
                selectedElectionId = id;
                candidates = allCandidates;
                isLoading = false;
              });
              return;
            }
          }

          // No polling open elections found
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print("⚠️ No central_election_info doc found.");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("❌ Error filtering sub-collections: $e");
      setState(() => isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllCandidates(
      String subCollectionId) async {
    try {
      final String electionType = subCollectionId.split("_").first;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Fetch voter's constituency
      final voterDoc = await firestore.collection('voters').doc(widget.aadhaar).get();
      final voterConstituency = voterDoc.data()?['constituency'];

      if (voterConstituency == null) {
        print("🚫 Voter constituency not found.");
        return [];
      }

      final CollectionReference partyListRef = firestore
          .collection('election_status')
          .doc(electionType)
          .collection(subCollectionId)
          .doc('party')
          .collection('list');

      final QuerySnapshot partyListSnapshot = await partyListRef.get();

      if (partyListSnapshot.docs.isEmpty) {
        print("🚫 No parties found in: $subCollectionId");
        return [];
      }

      List<Map<String, dynamic>> filteredCandidates = [];

      for (final partyDoc in partyListSnapshot.docs) {
        final String partyName = partyDoc.id;
        final CollectionReference candidatesRef = partyDoc.reference.collection('candidates');

        final QuerySnapshot candidatesSnapshot = await candidatesRef.get();

        for (final candidateDoc in candidatesSnapshot.docs) {
          final data = candidateDoc.data() as Map<String, dynamic>;
          final candidateConstituency = data['constituency'];

          if (candidateConstituency == voterConstituency) {
            data['party'] = partyName;
            data['aadhaar'] = candidateDoc.id;
            filteredCandidates.add(data);
          }
        }
      }

      print("✅ Candidates in voter's constituency (${voterConstituency}): ${filteredCandidates.length}");
      return filteredCandidates;
    } catch (e) {
      print("❌ Error fetching candidates: $e");
      return [];
    }
  }

  void _showCandidates(String subCollectionId) async {
    final candidateWidgets = <Widget>[];

    try {
      final allCandidates = await _fetchAllCandidates(subCollectionId);

      if (allCandidates.isEmpty) {
        candidateWidgets.add(const ListTile(title: Text('No candidates found')));
      }

      for (final candidate in allCandidates) {
        final name = candidate['name'] ?? 'Unknown';
        final party = candidate['party'] ?? 'Unknown';
        final aadhaar = candidate['aadhaar'] ?? 'Unknown';

        candidateWidgets.add(
          ListTile(
            title: Text(name),
            subtitle: Text('$party - Aadhaar: $aadhaar'),
            onTap: () => _showCandidateDetails(candidate),
          ),
        );
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Candidates'),
          content: SingleChildScrollView(
            child: Column(children: candidateWidgets),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      print("❌ Failed to show candidates: $e");
    }
  }

  void _showCandidateDetails(Map<String, dynamic> candidate) {
    setState(() {
      selectedCandidate = candidate;  // Store the selected candidate
    });
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(candidate['name'] ?? 'Candidate Details'),
        content: Text(
            'Party: ${candidate['party']}\nAadhaar: ${candidate['aadhaar']}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vote Now')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allSubCollectionIds.isEmpty
          ? const Center(child: Text("No ongoing elections."))
          : _buildVotingForm(candidates, selectedElectionId ?? ''),

    );
  }

  Widget _buildVotingForm(List<Map<String, dynamic>> candidates, String electionId) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select your candidate:', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: candidates.length + 1, // ✅ +1 for NOTA
              itemBuilder: (context, index) {
                if (index == candidates.length) {
                  return RadioListTile<Map<String, dynamic>>(
                    title: const Text('NOTA (None of the Above)'),
                    value: notaCandidate,
                    groupValue: selectedCandidate,
                    onChanged: (value) {
                      setState(() {
                        selectedCandidate = value;
                      });
                    },
                  );
                }


                final candidate = candidates[index];
                return RadioListTile<Map<String, dynamic>>(
                  title: Text('${candidate['name']} (${candidate['party']})'),
                  value: candidate,
                  groupValue: selectedCandidate,
                  onChanged: (value) {
                    setState(() {
                      selectedCandidate = value;
                    });
                  },
                );
              },
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: selectedCandidate == null
                  ? null
                  : () => _submitVote(selectedCandidate!, electionId),
              child: const Text('Submit Vote'),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _submitVote(Map<String, dynamic> candidate, String electionId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final voteDocRef = firestore
          .collection('votes')
          .doc(widget.election['id'])
          .collection('voters')
          .doc(widget.aadhaar);

      final voteSnapshot = await voteDocRef.get();

      if (voteSnapshot.exists) {
        _showMessage("You have already voted.");
        return;
      }

      // Encrypt vote and user details
      final encryptedVote = _encryptVote(candidate['aadhaar']);
      final encryptedUser = _encryptUser(widget.aadhaar);

      await voteDocRef.set({
        'election_id': widget.election["id"],
        'candidate_id': encryptedVote,
        'user_id': encryptedUser,
        'timestamp': FieldValue.serverTimestamp(),
        'visible': false, // Hide until polling ends
      });

      _showMessage("✅ Vote submitted successfully!");

      setState(() {
        selectedCandidate = null;
      });
    } catch (e) {
      print("❌ Error submitting vote: $e");
      _showMessage("Something went wrong while submitting your vote.");
    }
  }
  String _encryptVote(String vote) {
    // TODO: Replace with AES or another secure encryption
    return "enc_$vote";
  }

  String _encryptUser(String userId) {
    // TODO: Replace with secure encryption
    return "user_${userId.hashCode}";
  }
  final Map<String, dynamic> notaCandidate = {
    'name': 'NOTA',
    'party': 'None',
    'aadhaar': 'NOTA',
  };


  Future<void> _showMessage(String msg, {bool popAfter = false}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Vote Status"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close the dialog only
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );

    if (popAfter) {
      Navigator.of(context).pop(); // Pop VotingScreen itself
    }
  }


}
