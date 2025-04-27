import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:voting/screens/relogin_screen.dart';
import 'package:voting/screens/voting_screen.dart';
import 'package:voting/services/biometric_service.dart';
import 'package:voting/screens/VotingInstructionsDialog.dart';

class VoteNowScreen extends StatefulWidget {
  final String aadhaar;
  const VoteNowScreen({required this.aadhaar});

  @override
  _VoteNowScreenState createState() => _VoteNowScreenState();
}

class _VoteNowScreenState extends State<VoteNowScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> ongoingElections = [];
  List<Map<String, dynamic>> upcomingElections = [];
  List<String> allSubCollectionIds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSubCollectionIds().then((_) {
      _fetchElections();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }


  Future<void> _fetchSubCollectionIds() async {
    final electionControlRef = FirebaseFirestore.instance
        .collection('election_control')
        .doc('central_election_info');

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

  Future<void> _fetchElections() async {
    final ongoing = <Map<String, dynamic>>[];
    final upcoming = <Map<String, dynamic>>[];
    final lokSabhaDocRef = FirebaseFirestore.instance.collection('election_status').doc('lok_sabha');

    for (final subColId in allSubCollectionIds) {
      try {
        final docSnapshot = await lokSabhaDocRef.collection(subColId).doc('election_info').get();
        final data = docSnapshot.data();
        if (data == null) continue;

        data['election_id'] = subColId;
        data['election_type'] = 'lok_sabha';

        final pollingStart = (data['polling_start'] as Timestamp?)?.toDate();
        final pollingEnd = (data['polling_end'] as Timestamp?)?.toDate();
        final now = DateTime.now();

        if (pollingStart != null && pollingEnd != null) {
          if (now.isAfter(pollingStart) && now.isBefore(pollingEnd)) {
            ongoing.add(data);
          } else if (now.isBefore(pollingStart)) {
            upcoming.add(data);
          }
        }
      } catch (e) {
        print("❌ Error reading $subColId: $e");
      }
    }

    setState(() {
      ongoingElections = ongoing;
      upcomingElections = upcoming;
    });
  }

  void _showOngoingPopup(Map<String, dynamic> election) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Election Options'),
        content: const Text('Do you want to cast your vote or view candidates?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToVotingScreen(election);
            },
            child: const Text('Cast Vote'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCandidates(election);
            },
            child: const Text('Show Candidates'),
          ),
        ],
      ),
    );
  }

  void _showUpcomingPopup(Map<String, dynamic> election) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(election['election_type'] ?? 'Upcoming Election'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Polling Starts: ${election['polling_start'].toDate()}'),
            Text('Polling Ends: ${election['polling_end'].toDate()}'),
            const SizedBox(height: 10),
            const Text('Nominated Candidates:'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCandidates(election);
            },
            child: const Text('Show Candidates'),
          ),
        ],
      ),
    );
  }

  void _navigateToVotingScreen(Map<String, dynamic> election) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VotingScreen(election: election,aadhaar: widget.aadhaar,),
      ),
    );
  }
  Future<List<Map<String, dynamic>>> _fetchAllCandidates(String subCollectionId) async {
    try {
      final String electionType = subCollectionId.split("_").first;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Reference to the election status collection
      final CollectionReference electionCollectionRef = firestore
          .collection('election_status')
          .doc(electionType)
          .collection(subCollectionId)
      .doc('party').collection('list');

      // Fetch the list of all parties
      final QuerySnapshot partyListSnapshot = await electionCollectionRef.get();

      // Log the path being queried
      print("🧭 Querying path: ${electionCollectionRef.path}");

      // Ensure the party list exists
      if (partyListSnapshot.docs.isEmpty) {
        print("🚫 No parties found in the list for subCollectionId: $subCollectionId");
        return [];
      }

      print("✅ Found ${partyListSnapshot.docs.length} parties in subCollectionId: $subCollectionId");

      // List to store all the candidates
      List<Map<String, dynamic>> allCandidates = [];

      // Loop through each party
      for (final partyDoc in partyListSnapshot.docs) {
        final String partyName = partyDoc.id;

        // Reference to the candidates collection under each party
        final CollectionReference candidatesCollectionRef = partyDoc.reference.collection('candidates');

        // Fetch all candidates for the party
        final QuerySnapshot candidatesSnapshot = await candidatesCollectionRef.get();

        // Log the candidates collection path being queried
        print("🧭 Querying candidates path: ${candidatesCollectionRef.path}");

        // Loop through each candidate and add to the list
        for (final candidateDoc in candidatesSnapshot.docs) {
          final candidateData = candidateDoc.data() as Map<String, dynamic>;
          candidateData['party'] = partyName;  // Add party name to candidate data
          candidateData['aadhaar'] = candidateDoc.id;  // Use candidate's ID as Aadhaar
          allCandidates.add(candidateData);
        }
      }

      print("✅ Total Candidates Fetched: ${allCandidates.length}");
      return allCandidates;

    } catch (e) {
      print("❌ Error fetching candidates: $e");
      return [];
    }
  }

  void _showCandidates(Map<String, dynamic> election) async {
    final subColId = election['election_id'] ?? 'lok_sabha_04-22-2025_11-10-56';
    print('🧭 Using SubCollection ID: $subColId');

    final candidateWidgets = <Widget>[];

    try {
      final allCandidates = await _fetchAllCandidates(subColId);

      if (allCandidates.isEmpty) {
        print("⚠️ No candidates found in: $subColId");
        candidateWidgets.add(const ListTile(title: Text('No candidates found')));
      }

      for (final candidateData in allCandidates) {
        final candidateName = candidateData['name'] ?? 'Unknown';
        final partyName = candidateData['party'] ?? 'Unknown';
        final aadhaarNumber = candidateData['aadhaar_number'] ?? 'Unknown';

        print('🧑 Candidate: $candidateName - Aadhaar: $aadhaarNumber');

        candidateWidgets.add(
          ListTile(
            title: Text(candidateName),
            subtitle: Text('$partyName - Aadhaar: $aadhaarNumber'),
            onTap: () => _showCandidateDetails(candidateData),
          ),
        );
      }

      if (candidateWidgets.isEmpty) {
        candidateWidgets.add(const ListTile(title: Text('No candidates found')));
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Candidates'),
          content: SingleChildScrollView(child: Column(children: candidateWidgets)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      print("⚠️ Failed to fetch candidates: $e");
    }
  }

  void _showCandidateDetails(Map<String, dynamic> candidateData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(candidateData['name'] ?? 'Candidate Details'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Party: ${candidateData['party'] ?? 'Unknown'}'),
            Text('Aadhaar: ${candidateData['aadhaar_number'] ?? 'Unknown'}'),
            // Add any other candidate details here
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showElectionPopup({
    required Map<String, dynamic> election,
    required bool isOngoing,
  }) async {
    // Print election details for debugging
    print(election);

    final firestore = FirebaseFirestore.instance;

    // Reference to the voter's Firestore document using their Aadhaar number
    final voterDocRef = firestore
        .collection('votes')
        .doc(election['election_id'])
        .collection('voters')
        .doc(widget.aadhaar);

    // Fetch the voter's document to check if they have voted
    final voterSnapshot = await voterDocRef.get();

    bool hasVoted = false;

    // Check if the voter's document exists and if they have already voted
    if (voterSnapshot.exists) {
      final voterData = voterSnapshot.data();
      if (voterData != null && voterData['voted'] == true) {
        hasVoted = true;  // Voter has already voted
      }
      print(voterData);
    }


    // Show the election popup dialog
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.blue.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      election['election_id'] ?? 'Election',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (hasVoted)
              // If the voter has already voted, show the message instead of the vote button
                Text(
                  'You have already submitted your vote.',
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                )
              else if (isOngoing)
              // If the election is ongoing and the voter has not voted yet, show the "Vote Now" button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF073C6A),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    // Show instructions dialog before proceeding
                    final proceed = await showDialog(
                      context: context,
                      builder: (context) => const VotingInstructionsDialog(),
                    );

                    if (proceed == true) {
                      final loginSuccess = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReLoginWithOtpScreen(userType: 'voting'),
                        ),
                      );

                      if (loginSuccess == true) {
                        // Proceed with biometric authentication
                        final biometricSuccess = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BiometricAuthScreen(
                              aadhaar: widget.aadhaar,
                              election: election,
                            ),
                          ),
                        );

                        if (biometricSuccess == true) {
                          // Navigate to the voting screen after biometric authentication
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VotingScreen(
                                election: election,
                                aadhaar: widget.aadhaar,
                              ),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text(
                    'Vote Now',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              const SizedBox(height: 12),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  foregroundColor: const Color(0xFF073C6A), // splash/hover
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showCandidates(election);  // Show candidates list
                },
                child: const Text(
                  'Show Candidates',
                  style: TextStyle(
                    color: Color(0xFF073C6A),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ongoing'),
            Tab(text: 'Upcoming'),
          ],
        ),

      body: TabBarView(
        controller: _tabController,
        children: [
          ListView(
            children: ongoingElections.map((election) => ListTile(
              title: Text(election['election_type'] ?? 'Election'),
              subtitle: Text('Polling Starts: ${election['polling_start'].toDate()}'),
              onTap: () => _showElectionPopup(election: election, isOngoing: true),
            )).toList(),
          ),
          ListView(
            children: upcomingElections.map((election) => ListTile(
              title: Text(election['election_type'] ?? 'Election'),
              subtitle: Text('Polling Starts: ${election['polling_start'].toDate()}'),
              onTap: () => _showElectionPopup(election: election, isOngoing: false),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

