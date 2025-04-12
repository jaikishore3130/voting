import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CandidateDashboard extends StatefulWidget {
  final String aadhaarNumber;

  const CandidateDashboard({super.key, required this.aadhaarNumber});

  @override
  State<CandidateDashboard> createState() => _CandidateDashboardState();
}

class _CandidateDashboardState extends State<CandidateDashboard> {
  String candidateName = '';
  String partyName = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCandidateDetails();
  }

  Future<void> fetchCandidateDetails() async {
    try {
      // Assuming Firestore collection: "candidates", field: "aadhaar"
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collectionGroup('candidates')
          .where('aadhaar', isEqualTo: widget.aadhaarNumber)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data() as Map<String, dynamic>;
        setState(() {
          candidateName = data['name'] ?? 'Candidate';
          partyName = data['party'] ?? 'Unknown Party';
          isLoading = false;
        });
      } else {
        setState(() {
          candidateName = 'Candidate';
          partyName = 'Unknown';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching candidate: $e');
      setState(() {
        candidateName = 'Candidate';
        partyName = 'Unknown';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isLoading
            ? Text("Loading...")
            : Text("Welcome, $candidateName"),
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            "$candidateName ($partyName)",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          _buildCard(
            title: "Your Profile",
            icon: Icons.person,
            content: "View and update your personal and party details.",
            onTap: () {},
          ),
          _buildCard(
            title: "Campaign Manager",
            icon: Icons.campaign,
            content: "Manage campaign strategies and announcements.",
            onTap: () {},
          ),
          _buildCard(
            title: "Election Info",
            icon: Icons.how_to_vote,
            content: "Check ongoing and upcoming elections.",
            onTap: () {},
          ),
          _buildCard(
            title: "Track Nominations",
            icon: Icons.check_circle_outline,
            content: "View nomination status and updates.",
            onTap: () {},
          ),
          _buildCard(
            title: "Voter Feedback",
            icon: Icons.feedback_outlined,
            content: "View suggestions or complaints from voters.",
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required String content,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple, size: 30),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
