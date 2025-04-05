import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  final String aadhaarNumber;

  HomeScreen({required this.aadhaarNumber});

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
    final doc = await FirebaseFirestore.instance
        .collection('voters')
        .doc(widget.aadhaarNumber)
        .get();
    if (doc.exists) {
      setState(() {
        _profileData = doc.data();
      });
    }
  }



  Future<void> _fetchNews() async {
    final url = Uri.parse("https://newsapi.org/v2/top-headlines?country=in&category=politics&apiKey=a3f1989aed15478ba01410509c7a239f");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _newsArticles = data['articles'].take(5).toList();
      });
    }
  }
  int _calculateAgeFromDob(String dobString) {
    try {
      final dob = DateTime.parse(dobString);
      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0; // fallback if format fails
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
                  ? CircleAvatar(backgroundImage: NetworkImage(_profileData!['photoUrl']))
                  : CircleAvatar(child: Icon(Icons.person)),
              title: Text(_profileData!['name'] ?? "Name"),
              subtitle: Text("Age: ${_calculateAgeFromDob(_profileData!['dob'])}\nConstituency: ${_profileData!['constituency'] ?? ''}"
              ),
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
