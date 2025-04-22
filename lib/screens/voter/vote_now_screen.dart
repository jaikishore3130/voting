import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VoteNowScreen extends StatefulWidget {
  const VoteNowScreen({Key? key}) : super(key: key);

  @override
  _VoteNowScreenState createState() => _VoteNowScreenState();
}

class _VoteNowScreenState extends State<VoteNowScreen> {
  List<Map<String, dynamic>> ongoingElections = [];
  List<Map<String, dynamic>> upcomingElections = [];
  List<String> allSubCollectionIds = [];

  @override
  void initState() {
    super.initState();
    _fetchSubCollectionIds().then((_) {
      _fetchElections();
    });
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Navigating to voting screen...")),
    );
  }

  Future<List<Map<String, dynamic>>> fetchAllParties() async {
    final List<Map<String, dynamic>> partyList = [];

    try {
      final partiesSnapshot = await FirebaseFirestore.instance
          .collection('election_status')
          .doc('lok_sabha')
          .collection('lok_sabha_04-22-2025_02-45-04')
          .doc('election_info')
          .collection('parties')
          .get();

      print('📦 Total Parties Fetched: ${partiesSnapshot.docs.length}');

      for (var doc in partiesSnapshot.docs) {
        final partyData = doc.data();
        partyList.add({
          'party_id': doc.id, // Party ID is used as party name
          ...partyData,
        });
      }

      print('📋 All Parties:');
      for (var party in partyList) {
        print(party);
      }
    } catch (e) {
      print('❌ Error fetching parties: $e');
    }

    return partyList;
  }

  void _showCandidates(Map<String, dynamic> election) async {
    final subColId = election['election_id'] ?? 'lok_sabha_04-22-2025_02-45-04'; // fallback if null
    print('🧭 Using SubCollection ID: $subColId');

    final candidateWidgets = <Widget>[];

    try {
      // Fetch all parties using the fetchAllParties function
      final partiesList = await fetchAllParties();

      if (partiesList.isEmpty) {
        print("⚠️ No parties found in: $subColId");
        candidateWidgets.add(const ListTile(title: Text('No parties found')));
      }

      // Loop through each party and fetch its candidates
      for (final party in partiesList) {
        final partyName = party['party_id']; // Party name is the document ID
        final candidatesPath = FirebaseFirestore.instance
            .collection('election_status')
            .doc('lok_sabha')
            .collection(subColId)
            .doc('election_info')
            .collection('parties')
            .doc(partyName) // Fetching party-specific candidates
            .collection('candidates');

        print('🏛️ Party: $partyName - Fetching candidates...');

        final candidatesSnapshot = await candidatesPath.get();
        final candidateDocs = candidatesSnapshot.docs;

        if (candidateDocs.isEmpty) {
          print("⚠️ No candidates under party: $partyName");
          continue;
        }

        for (final candidateDoc in candidateDocs) {
          final candidateData = candidateDoc.data();
          final candidateName = candidateData['name'] ?? 'Unknown';
          final aadhaarNumber = candidateDoc.id;

          print('🧑 Candidate: $candidateName - Aadhaar: $aadhaarNumber');

          candidateWidgets.add(
            ListTile(
              title: Text(candidateName),
              subtitle: Text('$partyName - Aadhaar: $aadhaarNumber'),
              onTap: () => _showCandidateDetails(candidateData),
            ),
          );
        }
      }

      // Handle case where no candidates found at all
      if (candidateWidgets.isEmpty) {
        candidateWidgets.add(const ListTile(
          title: Text('No candidates found'),
        ));
      }

      // Show dialog with the list of candidates
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Candidates"),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView(children: candidateWidgets),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    } catch (e) {
      print("❌ Error fetching candidates: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load candidates")),
      );
    }
  }


  void _showCandidateDetails(Map<String, dynamic> candidate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(candidate['name'] ?? 'Candidate Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Party: ${candidate['party'] ?? 'N/A'}'),
            Text('Constituency: ${candidate['constituency'] ?? 'N/A'}'),
            Text('Age: ${candidate['age'] ?? 'N/A'}'),
            Text('Education: ${candidate['education'] ?? 'N/A'}'),
            Text('Criminal Records: ${candidate['criminal_records'] ?? 'None'}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget buildElectionList(String type) {
    final elections = type == 'ongoing' ? ongoingElections : upcomingElections;

    if (elections.isEmpty) {
      return Center(child: Text("No ${type == 'upcoming' ? 'upcoming' : 'ongoing'} elections found."));
    }

    return ListView.builder(
      itemCount: elections.length,
      itemBuilder: (context, index) {
        final election = elections[index];
        return ListTile(
          leading: const Icon(Icons.how_to_vote, color: Colors.blue),
          title: Text(
            election['election_type']?.toString().toUpperCase() ?? 'ELECTION',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            type == 'ongoing'
                ? "Ends: ${(election['polling_end'] as Timestamp?)?.toDate()}"
                : "Starts: ${(election['polling_start'] as Timestamp?)?.toDate()}",
          ),
          onTap: () => type == 'ongoing'
              ? _showOngoingPopup(election)
              : _showUpcomingPopup(election),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Ongoing"),
              Tab(text: "Upcoming"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                buildElectionList('ongoing'),
                buildElectionList('upcoming'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
