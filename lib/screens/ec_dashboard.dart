import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:voting/screens/ec/home_screen.dart';
import 'package:voting/screens/ec/election_control_screen.dart';
import 'package:voting/screens/ec/nominations_approval_screen.dart';
import 'package:voting/screens/ec/feedback_screen.dart';

class EcEmployeeDashboard extends StatefulWidget {
  final String aadhaarNumber;
  final String role; // EC_STATE, EC_HEAD, EC_DEPUTY_HEAD
  final String state;

  const EcEmployeeDashboard({
    required this.aadhaarNumber,
    required this.role,
    required this.state,
  });

  @override
  State<EcEmployeeDashboard> createState() => _EcEmployeeDashboardState();
}

class _EcEmployeeDashboardState extends State<EcEmployeeDashboard> {
  int _currentIndex = 0;

  // Ensure you're passing the aadhaarNumber to HomeScreen correctly
  final List<Widget> _tabs = [];

  @override
  void initState() {
    super.initState();
    // Initialize the tabs after the widget's initialization
    _tabs.addAll([
      HomeScreen(aadhaarNumber: widget.aadhaarNumber),
      // Pass the aadhaarNumber here
      ElectionControlScreen(role: widget.role, uid: widget.aadhaarNumber,),
      NominationsApprovalScreen(),
      FeedbackScreen(),
    ]);
  }

  Future<DocumentSnapshot> _fetchCandidateProfile() async {
    return await FirebaseFirestore.instance
        .collection('EC_EMPLOYEES')
        .doc(widget.aadhaarNumber)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _tabs[_currentIndex], // This changes based on the selected tab
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (newIndex) => setState(() => _currentIndex = newIndex),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_vote),
            label: "Election Control",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: "Nominations",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback),
            label: "Feedback",
          ),
        ],
      ),
      backgroundColor: Colors.white, // A neutral background color
    );
  }
}