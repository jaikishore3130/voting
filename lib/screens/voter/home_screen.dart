import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui'; // For ImageFilter.blur
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:voting/screens/candidate/nomination_tab.dart';
import 'package:voting/screens/nomination_screen.dart';
class HomeScreen extends StatefulWidget {
  final String aadhaarNumber;

  HomeScreen({required this.aadhaarNumber});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profileData;
  List<dynamic> _newsArticles = [];
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _timer;
  bool _isNominationEnabled = false;
  final allSubCollectionIds = [];


  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchNews();
    _fetchNominationStatus();
// 🆕 fetch nomination flag
  }


  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
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
  Future<void> _fetchNominationStatus() async {


    final electionStatusRef = FirebaseFirestore.instance
        .collection('election_status')
        .doc('lok_sabha');

    // Step 1: Fetch all election subcollection IDs from /election_control/central_election_info
    final centralElectionInfoDoc = await FirebaseFirestore.instance
        .collection('election_control')
        .doc('central_election_info')
        .get();

    final subCollectionIds = List<String>.from(
        centralElectionInfoDoc.data()?['sub_collection_ids'] ?? []);

    String selectedElectionId = '';
    DateTime latestElectionDate = DateTime(1900);

    // Step 2: Find latest completed election
    for (final subColId in subCollectionIds) {

      final electionInfoDoc = await electionStatusRef
          .collection(subColId)
          .doc('election_info')
          .get();

      final data = electionInfoDoc.data();
      if (data == null) continue;

      final status = data['status'];

      // Step 4: Check if the nomination is open and show the nomination button
      if (status=="nominations_open") {
        setState(() {
          _isNominationEnabled = true; // Enable the nomination button
        });
      }
    }}

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

  int _calculateAgeFromDob(String dobString) {
    try {
      final dob = DateTime.parse(dobString);
      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month ||
          (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  Future<ImageProvider> _getDecryptedProfileImage(String aadhaar) async {
    final imageUrl =
        'https://raw.githubusercontent.com/jaikishore3130/encrypted-profile-images/main/$aadhaar.enc';
    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode == 200) {
      final encryptedBytes = response.bodyBytes;

      final key = encrypt.Key.fromUtf8('28212821282128212821282128212821');
      final iv = encrypt.IV.fromUtf8('3031303130313031'); // Same IV

      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(encryptedBytes),
        iv: iv,
      );

      print("✅ Decrypted length: ${decrypted.length}");
      print("✅ Magic bytes: ${decrypted.sublist(0, 3)}"); // Should print [255, 216, 255]

      return MemoryImage(Uint8List.fromList(decrypted));
    } else {
      throw Exception('❌ Failed to load image');
    }
  }
  String capitalize(String? input) {
    if (input == null || input.isEmpty) return 'N/A';
    return input
        .toLowerCase()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
  Widget _buildInfoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              capitalize(value?.toString()),
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _profileData == null
              ? Center(child: CircularProgressIndicator())
              : Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  FutureBuilder<ImageProvider>(
                    future: _getDecryptedProfileImage(widget.aadhaarNumber),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircleAvatar(
                          radius: 60,
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return CircleAvatar(
                          radius: 60,
                          child: Icon(Icons.error),
                        );
                      } else {
                        return CircleAvatar(
                          radius: 60,
                          backgroundImage: snapshot.data,
                        );
                      }
                    },
                  ),
                  SizedBox(height: 15),
                  Text(
                    capitalize(_profileData!['name']),


                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(height: 30),
                  _buildInfoRow("Father's Name", _profileData!['father_name']),
                  _buildInfoRow("Phone", _profileData!['phone'].toString()),

                  _buildInfoRow("Age", _calculateAgeFromDob(_profileData!['dob']).toString()),
                  _buildInfoRow("Constituency", _profileData!['constituency']),
                  _buildInfoRow("Address", _profileData!['address']),

                ],
              ),
            ),
          ),
          SizedBox(height: 15),
          if (_isNominationEnabled)
            ElevatedButton.icon(
              onPressed: () async {
                // Check if the user already has a nomination in Firestore
                final nominationRef = FirebaseFirestore.instance.collection('nominations');
                final userNomination = await nominationRef.doc(widget.aadhaarNumber).get();

                if (userNomination.exists) {
                  // If the nomination already exists, navigate to the NominationStatusScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NominationTab()),
                  );
                } else {
                  // If no nomination exists, navigate to the NominationScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NominationScreen(aadhaarNumber: widget.aadhaarNumber),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(
                Icons.how_to_vote,
                color: Colors.white,
              ),
              label: Text(
                "Submit Nomination",
                style: TextStyle(color: Colors.white),
              ),
            ),


          SizedBox(height: 20),
          Text(
            "Latest Political News",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          _newsArticles.isEmpty
              ? Center(child: Text("No news available"))
              : SizedBox(
            height: 350,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _newsArticles.length,
              itemBuilder: (context, index) {
                final article = _newsArticles[index];
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) {
                        return Stack(
                          children: [
                            BackdropFilter(
                              filter: ImageFilter.blur(
                                  sigmaX: 6, sigmaY: 6),
                              child: Container(
                                color: Colors.black.withOpacity(0.2),
                              ),
                            ),
                            Center(
                              child: Dialog(
                                insetPadding: EdgeInsets.all(20),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(15),
                                ),
                                backgroundColor: Colors.white,
                                child: Stack(
                                  children: [
                                    Container(
                                      constraints: BoxConstraints(
                                        maxHeight: MediaQuery.of(context)
                                            .size
                                            .height *
                                            0.75,
                                        maxWidth: MediaQuery.of(context)
                                            .size
                                            .width *
                                            0.9,
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            if (article['urlToImage'] !=
                                                null)
                                              ClipRRect(
                                                borderRadius:
                                                BorderRadius.circular(
                                                    10),
                                                child: Image.network(
                                                  article['urlToImage'],
                                                  width: double.infinity,
                                                  height: 180,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            SizedBox(height: 16),
                                            Text(
                                              article['title'] ?? '',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight:
                                                FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              (article['content'] ??
                                                  article[
                                                  'description'] ??
                                                  'No description available.')
                                                  .toString()
                                                  .replaceAll(
                                                  RegExp(
                                                      r'\[\+\d+ chars\]'),
                                                  ''),
                                              style: TextStyle(
                                                  fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () =>
                                            Navigator.of(context).pop(),
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundColor:
                                          Colors.grey.shade300,
                                          child: Icon(Icons.close,
                                              color: Colors.black,
                                              size: 18),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (article['urlToImage'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: Image.network(
                              article['urlToImage'],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            article['title'] ?? '',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
}
