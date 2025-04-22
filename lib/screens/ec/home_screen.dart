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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: _fetchCandidateProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildAppBarProfile("Loading...", isTablet);
            } else if (snapshot.hasError) {
              return _buildAppBarProfile("Error loading data", isTablet);
            } else if (snapshot.hasData) {
              var data = snapshot.data?.data() as Map<String, dynamic>;
              String name = data['name'] ?? "Unknown";
              String role = (data['role'] ?? "Unknown").replaceAll('_', ' ');
              String state = data['state'] ?? "Unknown";
              return _buildAppBarProfile("Welcome $name\n$role - $state", isTablet);
            } else {
              return _buildAppBarProfile("No Data Found", isTablet);
            }
          },
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: FutureBuilder<DocumentSnapshot>(
        future: _fetchCandidateProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Candidate not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final profileImageUrl = data['profileImageUrl'] as String?;
          final name = data['name'] ?? 'N/A';
          final age = data['age']?.toString() ?? 'N/A';
          final phone = data['phone']?.toString() ?? 'N/A';
          final email = data['email'] ?? 'N/A';
          final role = data['role'] ?? 'N/A';
          final state = data['state'] ?? 'N/A';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Center(
                  child: CircleAvatar(
                    radius: isTablet ? 90 : 75,
                    backgroundImage: profileImageUrl?.isNotEmpty == true
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    backgroundColor: Colors.grey.shade300,
                    child: (profileImageUrl == null || profileImageUrl.isEmpty)
                        ? Icon(Icons.person, size: isTablet ? 90 : 75, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    "Welcome to the EC Dashboard",
                    style: TextStyle(
                      fontSize: isTablet ? 28 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
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
                        ProfileDetailRow(label: "State", value: state),],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "Latest Political News",
                  style: TextStyle(fontSize: isTablet ? 24 : 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (_newsArticles.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else
                  SizedBox(
                    height: isTablet ? 250 : 220,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _newsArticles.length,
                      itemBuilder: (context, index) {
                        final article = _newsArticles[index];
                        return GestureDetector(
                          onTap: () => _showNewsPopup(context, article),
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                    child: article.imageUrl.isNotEmpty
                                        ? Image.network(article.imageUrl,
                                        height: isTablet ? 140 : 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover)
                                        : Container(
                                      height: 120,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image, size: 50),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(
                                      article.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: isTablet ? 18 : 16,
                                        fontWeight: FontWeight.w600,
                                      ),
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
        },
      ),
    );
  }
  Widget _buildAppBarProfile(String text, bool isTablet) {
    final parts = text.split("\n");
    return Row(
      children: [
        const CircleAvatar(
          backgroundColor: Colors.white,
          radius: 20,
          child: Icon(Icons.person, size: 30, color: Colors.blueAccent),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: parts.map((line) {
              return Text(
                line,
                style: TextStyle(fontSize: isTablet ? 18 : 16),
                overflow: TextOverflow.ellipsis,
              );
            }).toList(),
          ),
        )
      ],
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
