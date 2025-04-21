import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:voting/screens/candidate/home_tab.dart';
import 'package:voting/screens/candidate/campaign_tab.dart';
import 'package:voting/screens/candidate/election_info_tab.dart';
import 'package:voting/screens/candidate/nomination_tab.dart';
import 'package:voting/screens/candidate/feedback_tab.dart';

class CandidateDashboard extends StatefulWidget {
  final String aadhaarNumber;

  const CandidateDashboard({super.key, required this.aadhaarNumber});

  @override
  State<CandidateDashboard> createState() => _CandidateDashboardState();
}

class _CandidateDashboardState extends State<CandidateDashboard> {
  int _currentIndex = 0;
  String candidateName = '';
  String partyName = '';
  bool isLoading = true;

  final List<Widget> _tabs = [];

  @override
  void initState() {
    super.initState();
    fetchCandidateDetails();
  }

  Future<void> fetchCandidateDetails() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collectionGroup('candidates')
          .where('aadhaar', isEqualTo: widget.aadhaarNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        candidateName = data['name'] ?? 'Candidate';
        partyName = data['party'] ?? 'Unknown Party';
      } else {
        candidateName = 'Candidate';
        partyName = 'Unknown';
      }
    } catch (e) {
      print('Error fetching candidate: $e');
      candidateName = 'Candidate';
      partyName = 'Unknown';
    } finally {
      setState(() {
        isLoading = false;
        _tabs.addAll([
          HomeScreen( aadhaarNumber: widget.aadhaarNumber,),
          CampaignTab(),
          ElectionInfoTab(),
          NominationTab(aadhaarNumber: '', subCollectionId: '',),
          FeedbackTab(),
        ]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLoading ? "Loading..." : "Welcome, $candidateName"),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading ? Center(child: CircularProgressIndicator()) : _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Campaign'),
          BottomNavigationBarItem(icon: Icon(Icons.how_to_vote), label: 'Elections'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Nominations'),
          BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'Feedback'),
        ],
      ),
    );
  }
}
