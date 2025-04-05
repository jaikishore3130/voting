import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;



class VoterDashboard extends StatefulWidget {
  @override
  _VoterDashboardState createState() => _VoterDashboardState();
}

class _VoterDashboardState extends State<VoterDashboard> {
  int _currentIndex = 2;

  final List<Widget> _screens = [

    VoteNowScreen(),
    ResultsScreen(),
    HomeScreen(),
    CandidatesScreen(),
    FeedbackScreen(),
  ];

  final List<String> _titles = [

    "Vote Now",
    "Election Results",
    "Home",
    "Candidates",
    "Feedback & Suggestions",
  ];

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
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profileData;
  List<dynamic> _newsArticles = [];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchNews();
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('voters').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _profileData = doc.data();
        });
      }
    }
    else{

    }
  }

  Future<void> _fetchNews() async {
    final url = Uri.parse("https://newsapi.org/v2/top-headlines?country=in&category=politics&apiKey=YOUR_NEWSAPI_KEY");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _newsArticles = data['articles'].take(5).toList(); // show 5 articles
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _profileData == null
              ? CircularProgressIndicator()
              : Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: _profileData!['photoUrl'] != null
                  ? CircleAvatar(
                backgroundImage: NetworkImage(_profileData!['photoUrl']),
              )
                  : CircleAvatar(child: Icon(Icons.person)),
              title: Text(_profileData!['name'] ?? "Name"),
              subtitle: Text("Age: ${_profileData!['age'] ?? ''}\nConstituency: ${_profileData!['constituency'] ?? ''}"),
              isThreeLine: true,
            ),
          ),
          SizedBox(height: 20),
          Text("Latest Political News", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          ..._newsArticles.map((article) => Card(
            child: ListTile(
              title: Text(article['title'] ?? ""),
              subtitle: Text(article['description'] ?? ""),
            ),
          )),
        ],
      ),
    );
  }
}
class NominationFormScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nomination Form")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Nomination Form Placeholder", style: TextStyle(fontSize: 18)),
            // You can later add form fields here for name, party, manifesto, etc.
          ],
        ),
      ),
    );
  }
}
class VoteNowScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
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
                Center(child: Text("List of Ongoing Elections")),
                Center(child: Text("List of Upcoming Elections")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class ResultsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Past Election Results", style: TextStyle(fontSize: 18)),
    );
  }
}
class CandidatesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Candidate History & Manifestos", style: TextStyle(fontSize: 18)),
    );
  }
}
class FeedbackScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: "Raise an issue or give feedback to candidates",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              String feedback = _controller.text;
              if (feedback.isNotEmpty) {
                // Save to Firebase or show confirmation
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Feedback submitted!")));
                _controller.clear();
              }
            },
            child: Text("Submit"),
          ),
        ],
      ),
    );
  }
}
