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

  Future<void> _fetchElections() async {
    final ongoing = <Map<String, dynamic>>[];
    final upcoming = <Map<String, dynamic>>[];

    // Step 1: Get the `lok_sabha` document reference
    final lokSabhaDocRef = FirebaseFirestore.instance.collection('election_status').doc('lok_sabha');

    // Step 2: Workaround to get all subcollections under 'lok_sabha'
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

        final pollingStart = (data['polling_start'] as Timestamp?)?.toDate();
        final pollingEnd = (data['polling_end'] as Timestamp?)?.toDate();
        final now = DateTime.now();

        // Classify the election based on the current time
        if (pollingStart != null && pollingEnd != null) {
          if (now.isAfter(pollingStart) && now.isBefore(pollingEnd)) {
            ongoing.add(data); // Ongoing elections
          } else if (now.isBefore(pollingStart)) {
            upcoming.add(data); // Upcoming elections
          }
        }
      } catch (e) {
        print("❌ Error reading $subColId: $e");
      }
    }

    // Step 3: Update UI
    setState(() {
      ongoingElections = ongoing;
      upcomingElections = upcoming;
    });
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
        final pollingStart = (election['polling_start'] as Timestamp?)?.toDate();
        final pollingEnd = (election['polling_end'] as Timestamp?)?.toDate();

        String formatDateTime(DateTime? dateTime) {
          if (dateTime == null) return 'N/A';
          final local = dateTime.toLocal();
          return "${local.day}-${local.month}-${local.year} at ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}";
        }

        return ListTile(
          leading: const Icon(Icons.how_to_vote, color: Colors.blue),
          title: Text(
            election['election_type']?.toString().toUpperCase() ?? 'ELECTION',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            pollingEnd != null && DateTime.now().isAfter(pollingStart!) && DateTime.now().isBefore(pollingEnd)
                ? "Polling ends: ${formatDateTime(pollingEnd)}"
                : "Polling starts: ${formatDateTime(pollingStart)}",
          ),
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
