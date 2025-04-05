import 'package:flutter/material.dart';
import 'package:voting/screens/voter/home_screen.dart';
import 'package:voting/screens/voter/vote_now_screen.dart';
import 'package:voting/screens/voter/results_screen.dart';
import 'package:voting/screens/voter/candidates_screen.dart';
import 'package:voting/screens/voter/feedback_screen.dart';

class VoterDashboard extends StatefulWidget {
  final String aadhaarNumber;

  VoterDashboard({required this.aadhaarNumber});

  @override
  _VoterDashboardState createState() => _VoterDashboardState();
}

class _VoterDashboardState extends State<VoterDashboard> {
  int _currentIndex = 2;
  late List<Widget> _screens;

  final List<String> _titles = [
    "Vote Now",
    "Election Results",
    "Home",
    "Candidates",
    "Feedback & Suggestions",
  ];

  @override
  void initState() {
    super.initState();
    _screens = [
      VoteNowScreen(),
      ResultsScreen(),
      HomeScreen(aadhaarNumber: widget.aadhaarNumber), // ✅ Correct usage
      CandidatesScreen(),
      FeedbackScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.how_to_vote), label: "Vote Now"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Results"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Candidates"),
          BottomNavigationBarItem(icon: Icon(Icons.feedback), label: "Feedback"),
        ],
      ),
    );
  }
}
