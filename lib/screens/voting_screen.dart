import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voting/screens/voter/vote_now_screen.dart';
import 'package:voting/screens/voter/voter_dashboard.dart';

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

      // Fetch all candidates for the voter's constituency
      List<Map<String, dynamic>> candidates = await _fetchAllCandidates(electionId);

      // Find the candidate who was selected by the user
      Map<String, dynamic>? selectedCandidate = candidates.firstWhere(
            (c) => c['aadhaar'] == candidate['aadhaar'],
        orElse: () {
          throw Exception("Candidate not found.");
        },
      );
      print(selectedCandidate);

      // Check if selectedCandidate is null
      if (selectedCandidate == null) {
        _showMessage("The selected candidate is not valid for your constituency.");
        return;
      }

      final voteDocRef = firestore
          .collection('votes')
          .doc(selectedElectionId)
          .collection('voters')
          .doc(widget.aadhaar);

      final voteSnapshot = await voteDocRef.get();

      // Check if the user has already voted
      if (voteSnapshot.exists) {
        _showMessage("You have already voted.");
        return;
      }

      // Firestore transaction for atomic operations
      await firestore.runTransaction((transaction) async {
        // Debugging print
        print('Selected Candidate Aadhaar: ${selectedCandidate?['aadhaar']}');

        // Reference to candidate's vote count and the election's total votes
        final candidateDocRef = firestore
            .collection('election_status')
            .doc('lok')
            .collection(selectedElectionId!)
            .doc('party')
            .collection('list')
            .doc(selectedCandidate?['party'])
            .collection('candidates')
            .doc(selectedCandidate?['aadhaar']);

        final electionDocRef = firestore.collection('election_status')
            .doc('lok_sabha') // Ensure this path is correct
            .collection(selectedElectionId!) // Ensure this ID is correct
            .doc('election_info');

        print("Candidate Doc Ref: $candidateDocRef");
        print("Election Doc Ref: $electionDocRef");

        // Get current candidate data and election data
        final candidateSnapshot = await transaction.get(candidateDocRef);
        final electionSnapshot = await transaction.get(electionDocRef);

        print('Candidate Snapshot Exists: ${candidateSnapshot.exists}');
        print('Election Snapshot Exists: ${electionSnapshot.exists}');

        if (!candidateSnapshot.exists) {
          print("❌ Candidate not found.");
          throw Exception("Candidate not found.");
        }

        if (!electionSnapshot.exists) {
          print("❌ Election not found.");
          throw Exception("Election not found.");
        }

        // Check the election status before updating vote count
        final electionStatus = electionSnapshot.data()?['status'];

        if (electionStatus == 'completed') {
          // Get current vote count for the candidate and total votes for the election
          final currentVoteCount = candidateSnapshot.data()?['vote_count'] ?? 0;
          final totalVotes = electionSnapshot.data()?['total_votes'] ?? 0;

          // Encrypt vote and user details
          final encryptedVote = _encryptVote(selectedCandidate?['aadhaar']);
          final encryptedUser = _encryptUser(widget.aadhaar);

          // Update the candidate's vote count and the election's total votes
          transaction.update(candidateDocRef, {
            'vote_count': currentVoteCount + 1, // Increment vote count for the candidate
          });

          transaction.update(electionDocRef, {
            'total_votes': totalVotes + 1, // Increment total votes for the election
          });

          // Store the vote in the votes collection
          transaction.set(voteDocRef, {
            'election_id': widget.election["id"],
            'candidate_id': encryptedVote,
            'user_id': encryptedUser,
            'timestamp': FieldValue.serverTimestamp(),
            'visible': false, // Hide until polling ends
            'voted': true,
          });
        } else {
          // If election status is not completed, don't update vote count
          _showMessage("Voting is not allowed until the election is completed.");
          return;
        }
      });

      // Show success message and a dialog
      _showMessage("✅ Vote submitted successfully!");

      // Show a popup dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Vote Submitted"),
            content: Text("Your vote has been successfully submitted."),
            actions: [
              TextButton(
                onPressed: () {
                  // Close the dialog and navigate to the home page
                  Navigator.pop(context); // Close the dialog

                  // Use pushReplacement to navigate to the home page and prevent back navigation
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => VoterDashboard(aadhaarNumber: widget.aadhaar)),
                        (Route<dynamic> route) => false, // This will remove all the previous routes
                  );
                },
                child: Text("Go to Home Page"),
              ),
            ],
          );
        },
      );

      setState(() {
        // Reset the selected candidate after voting
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
    return "user_$userId";
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