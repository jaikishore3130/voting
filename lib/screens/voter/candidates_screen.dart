import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

class CandidatesScreen extends StatefulWidget {
  @override
  _CandidatesScreenState createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String? selectedElection;
  List<Map<String, dynamic>> candidates = [];
  List<Map<String, dynamic>> parties = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _fetchParties();
  }



  Future<void> _fetchLokSabhaCandidates() async {
    List<Map<String, dynamic>> fetchedCandidates = [];

    try {
      final partySnapshots = await FirebaseFirestore.instance.collection('LOK_SABHA').get();

      for (var partyDoc in partySnapshots.docs) {
        final partyName = partyDoc.id;

        final candidateSnapshots = await FirebaseFirestore.instance
            .collection('LOK_SABHA')
            .doc(partyName)
            .collection('candidates')
            .get();

        for (var candidateDoc in candidateSnapshots.docs) {
          final data = candidateDoc.data();

          // Organize fields in a consistent, readable format with fallbacks
          final candidateData = {
            'party': partyName,
            'name': data['name'] ?? 'Unnamed',
            'age': data['age'] ?? 'N/A',
            'gender': data['gender'] ?? 'N/A',
            'education': data['education'] ?? 'N/A',
            'criminal_history': data['criminal_history'] ?? '0',
            'assets': data['assets'] ?? 'N/A',
            'liabilities': data['liabilities'] ?? 'N/A',
            'votes_received': data['votes_received'] ?? 0,
            'winner': data['winner'] ?? false,
            'email': data['email'] ?? 'N/A',
            'phone': data['phone'] ?? 'N/A',

            'state': data['state'] ?? 'Unknown',
            'constituency': data['constituency'] ?? 'Unknown',
            'permanent_address': data['permanent_address'] ?? 'N/A',
            'manifesto': data['manifesto'] ?? '',
            'imageUrl': data['profile_image'] ?? '',
          };

          fetchedCandidates.add(candidateData);
        }
      }

      // Sort candidates alphabetically by name
      fetchedCandidates.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

      setState(() {
        candidates = fetchedCandidates;
      });
    } catch (e) {
      print("❌ Error fetching candidates: $e");
    }
  }

  Future<void> _fetchParties() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('LOK_SABHA').get();

      final fetchedParties = snapshot.docs.map((doc) {
        final data = doc.data();
        data['name'] = doc.id;
        data['logoUrl'] = data['logoUrl'] ?? '';
        data['leader'] = data['leader'] ?? 'N/A';
        data['symbol'] = data['symbol'] ?? 'N/A';
        return data;
      }).toList();

      setState(() {
        parties = fetchedParties;
      });
    } catch (e) {
      print("❌ Error fetching parties: $e");
    }
  }

  void _showCandidatePopup(Map<String, dynamic> candidate) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),
            Center(
              child: Container(
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        candidate['imageUrl'] != null && candidate['imageUrl'].toString().isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            candidate['imageUrl'],
                            height: 150,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.person, size: 100),
                          ),
                        )
                            : Icon(Icons.person, size: 100),
                        SizedBox(height: 10),
                        Text(
                          candidate['name'] ?? 'Unnamed',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Divider(thickness: 1, height: 20),
                        _infoText("Party", candidate['party']),
                        _infoText("Age", candidate['age']),
                        _infoText("Gender", candidate['gender']),
                        _infoText("Education", candidate['education']),
                        _infoText("Criminal History", candidate['criminal_history']),
                        _infoText("Assets", candidate['assets']),
                        _infoText("Liabilities", candidate['liabilities']),
                        _infoText("Votes Received", candidate['votes_received'].toString()),
                        _infoText("Winner", candidate['winner'] == true ? "Yes" : "No"),
                        _infoText("Email", candidate['email']),
                        _infoText("Phone", candidate['phone']),
                        _infoText("User ID", candidate['user_id']),
                        _infoText("State", candidate['state']),
                        _infoText("Constituency", candidate['constituency']),
                        _infoText("Address", candidate['permanent_address']),
                        if (candidate['manifesto'] != null && candidate['manifesto'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Divider(thickness: 1),
                                Text("Manifesto:",
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text(candidate['manifesto'],
                                    maxLines: 5, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoText(String label, dynamic value) {
    if (value == null || value.toString().isEmpty || value == 'N/A') return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value.toString())),
        ],
      ),
    );
  }

  Widget _buildCandidateCard(Map<String, dynamic> candidate) {
    return GestureDetector(
      onTap: () => _showCandidatePopup(candidate),
      child: Card(
        elevation: 3,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundImage: (candidate['imageUrl'] != null && candidate['imageUrl'].toString().isNotEmpty)
                    ? NetworkImage(candidate['imageUrl'])
                    : null,
                child: (candidate['imageUrl'] == null || candidate['imageUrl'].toString().isEmpty)
                    ? Icon(Icons.person, size: 40)
                    : null,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(candidate['name'] ?? '',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Party: ${candidate['party']}"),
                    Text("Constituency: ${candidate['constituency'] ?? 'N/A'}"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartyTile(Map<String, dynamic> party) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: party['logoUrl'] != null && party['logoUrl'].toString().isNotEmpty
            ? CircleAvatar(
          backgroundImage: NetworkImage(party['logoUrl']),
          radius: 24,
          onBackgroundImageError: (_, __) {},
        )
            : CircleAvatar(
          child: Icon(Icons.flag),
          radius: 24,
        ),
        title: Text(party['name'], style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text("Leader: ${party['leader'] ?? 'N/A'}"),
            Text("Symbol: ${party['symbol'] ?? 'N/A'}"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.blue,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: "Candidates"),
              Tab(text: "Parties"),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Candidates Tab
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedElection,
                      decoration: InputDecoration(labelText: "Select Election", border: OutlineInputBorder()),
                      items: ["Lok Sabha", "Vidhan Sabha", "Rajya Sabha"]
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) async {
                        setState(() {
                          selectedElection = val;
                          candidates.clear();
                        });

                        if (val == "Lok Sabha") {
                          await _fetchLokSabhaCandidates();
                        }
                      },
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: candidates.isEmpty
                          ? Center(child: Text("No candidates to show."))
                          : ListView.builder(
                        itemCount: candidates.length,
                        itemBuilder: (context, index) =>
                            _buildCandidateCard(candidates[index]),
                      ),
                    ),
                  ],
                ),
              ),
              // Parties Tab
              parties.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: parties.length,
                  itemBuilder: (context, index) => _buildPartyTile(parties[index]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
