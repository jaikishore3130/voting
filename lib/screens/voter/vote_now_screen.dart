import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VoteNowScreen extends StatelessWidget {
  const VoteNowScreen({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> fetchElectionsByTiming(String type) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('election_status')
          .orderBy('polling_start') // Optional sorting
          .get();

      final now = DateTime.now();

      return snapshot.docs.map((doc) => doc.data()).where((data) {
        final pollingStart = (data['polling_start'] as Timestamp?)?.toDate();
        final pollingEnd = (data['polling_end'] as Timestamp?)?.toDate();

        if (pollingStart == null || pollingEnd == null) return false;

        if (type == 'ongoing') {
          return now.isAfter(pollingStart) && now.isBefore(pollingEnd);
        } else if (type == 'upcoming') {
          return now.isBefore(pollingStart);
        }

        return false;
      }).toList();
    } catch (e) {
      print("Error fetching elections: $e");
      return [];
    }
  }

  Widget buildElectionList(String type) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchElectionsByTiming(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final elections = snapshot.data ?? [];

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
