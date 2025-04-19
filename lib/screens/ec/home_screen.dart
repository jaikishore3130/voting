import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  final String aadhaarNumber;

  HomeScreen({required this.aadhaarNumber});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;
  List<NewsArticle> _newsArticles = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _fetchNews();
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<DocumentSnapshot> _fetchCandidateProfile() async {
    return await FirebaseFirestore.instance
        .collection('EC_EMPLOYEES')
        .doc(widget.aadhaarNumber)
        .get();
  }

  Future<void> _fetchNews() async {
    final url = Uri.parse(
        "https://newsapi.org/v2/everything?q=politics%20india&sortBy=publishedAt&language=en&apiKey=a3f1989aed15478ba01410509c7a239f");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> articles = data['articles'];

      final filtered = articles
          .where((article) => article['urlToImage'] != null)
          .take(5)
          .map((json) => NewsArticle.fromJson(json))
          .toList();

      setState(() {
        _newsArticles = filtered;
      });

      if (filtered.length > 1) {
        _startAutoSlide();
      }
    }
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(Duration(seconds: 4), (Timer timer) {
      if (_currentPage < _newsArticles.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _showNewsPopup(BuildContext context, NewsArticle article) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        child: article.imageUrl.isNotEmpty
                            ? Image.network(article.imageUrl,
                            width: double.infinity, height: 200, fit: BoxFit.cover)
                            : Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: Icon(Icons.image, size: 80),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(article.title,
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text(article.content,
                                style: TextStyle(fontSize: 16), textAlign: TextAlign.justify),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( appBar: AppBar(
      title: FutureBuilder<DocumentSnapshot>(
        future: _fetchCandidateProfile(), // Fetch employee data
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: Icon(
                    Icons.account_circle,
                    size: 30,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(width: 10),
                Text("Loading...", style: TextStyle(fontSize: 20)),
              ],
            );
          } else if (snapshot.hasError) {
            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: Icon(
                    Icons.account_circle,
                    size: 30,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(width: 10),
                Text("Error loading data", style: TextStyle(fontSize: 20)),
              ],
            );
          } else if (snapshot.hasData) {
            var employeeData = snapshot.data?.data() as Map<String, dynamic>;
            String employeeName = employeeData['name'] ?? "Unknown";
            String employeeROLE = employeeData['role'] ?? "Unknown";
            String employeeSTATE = employeeData['state'] ?? "Unknown";
            employeeROLE=employeeROLE.replaceAll('_', ' ') ;
            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Welcome $employeeName",
                        style: TextStyle(fontSize: 20)),
                    Text(
                      "$employeeROLE - $employeeSTATE",
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            );
          } else {
            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: Icon(
                    Icons.account_circle,
                    size: 30,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(width: 10),
                Text("No Data Found", style: TextStyle(fontSize: 20)),
              ],
            );
          }
        },
      ),
      backgroundColor: Colors.blueAccent,
      elevation: 0,
    ),
      backgroundColor: Color(0xFFF5F7FA),
      body: FutureBuilder<DocumentSnapshot>(
        future: _fetchCandidateProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Candidate not found.'));
          } else {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            String name = data['name'] ?? 'N/A';
            String age = data['age']?.toString() ?? 'N/A';
            String phone = data['phone']?.toString() ?? 'N/A';
            String email = data['email'] ?? 'N/A';
            String role = data['role'] ?? 'N/A';
            String state = data['state'] ?? 'N/A';
            String? profileImageUrl = data['profileImageUrl'];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                      ),
                      child: CircleAvatar(
                        radius: 75,
                        backgroundImage: (profileImageUrl != null && profileImageUrl.isNotEmpty)
                            ? NetworkImage(profileImageUrl)
                            : null,
                        backgroundColor: Colors.grey.shade300,
                        child: (profileImageUrl == null || profileImageUrl.isEmpty)
                            ? Icon(Icons.person, size: 75, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      "Welcome to the EC Dashboard",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          ProfileDetailRow(label: "Name", value: name),
                          ProfileDetailRow(label: "Age", value: age),
                          ProfileDetailRow(label: "Phone", value: phone),
                          ProfileDetailRow(label: "Email", value: email),
                          ProfileDetailRow(label: "Role", value: role),
                          ProfileDetailRow(label: "State", value: state),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "Latest Political News",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (_newsArticles.isEmpty)
                    Center(child: CircularProgressIndicator())
                  else
                    SizedBox(
                      height: 220,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _newsArticles.length,
                        itemBuilder: (context, index) {
                          final article = _newsArticles[index];
                          return GestureDetector(
                            onTap: () => _showNewsPopup(context, article),
                            child: Container(
                              margin: EdgeInsets.only(right: 10),
                              child: Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                      child: article.imageUrl.isNotEmpty
                                          ? Image.network(article.imageUrl,
                                          height: 120, width: double.infinity, fit: BoxFit.cover)
                                          : Container(
                                        height: 120,
                                        width: double.infinity,
                                        color: Colors.grey[300],
                                        child: Icon(Icons.image, size: 50),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Text(
                                        article.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

class ProfileDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const ProfileDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "$label:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: TextStyle(fontSize: 18, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class NewsArticle {
  final String title;
  final String imageUrl;
  final String content;

  NewsArticle({required this.title, required this.imageUrl, required this.content});

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'No Title',
      imageUrl: json['urlToImage'] ?? '',
      content: json['content'] ?? 'No Content Available',
    );
  }
}
