import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:voting/screens/voter_login_screen.dart';
import 'package:voting/screens/voting_screen.dart';
import 'package:voting/services/biometric_service.dart';

class VoteNowScreen extends StatefulWidget {
  const VoteNowScreen({Key? key}) : super(key: key);

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
        builder: (context) => VotingScreen(election: election),
      ),
    );
  }
  Future<List<Map<String, dynamic>>> _fetchAllCandidates(String subColId) async {
    try {
      final electionStatusRef = FirebaseFirestore.instance
          .collection('election_status')
          .doc('lok_sabha');

      // Step 1: Fetch party list under the given election
      final partyListDoc = await electionStatusRef
          .collection(subColId)
          .doc('party')
          .collection('list')
          .get();

      List<Map<String, dynamic>> allCandidates = [];

      for (final partyDoc in partyListDoc.docs) {
        final partyId = partyDoc.id;
        final candidatesSnapshot = await electionStatusRef
            .collection(subColId)
            .doc('party')
            .collection('list')
            .doc(partyId)
            .collection('candidates')
            .get();

        for (final candidateDoc in candidatesSnapshot.docs) {
          print("$candidateDoc");
          final candidateData = candidateDoc.data();
          candidateData['party'] = partyId;
          allCandidates.add(candidateData);
        }
      }

      print("✅ All Candidates Fetched: $allCandidates");
      return allCandidates;

    } catch (e) {
      print("🔥 Firestore fetch error: $e");
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
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                election['election_type'] ?? 'Election',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            if (isOngoing) ...[
              ElevatedButton(
                onPressed: () async {
                  final loginSuccess = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) =>  VoterLoginScreen()),
                  );

                  if (loginSuccess == true) {
                    final biometricSuccess = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BiometricAuthScreen()),
                    );

                    if (biometricSuccess == true) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VotingScreen(election: election['election_type']),
                        ),
                      );
                    }
                  }
                },
                child: const Text('Vote Now'),
              ),

            ],
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showCandidates(election);
              },
              child: const Text('Show Candidates'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vote Now'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ongoing'),
            Tab(text: 'Upcoming'),
          ],
        ),
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