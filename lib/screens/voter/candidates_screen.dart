import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CandidatesScreen extends StatefulWidget {
  @override
  _CandidatesScreenState createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  String? selectedParty;
  String? selectedState;
  String? selectedType;

  List<Map<String, dynamic>> candidates = [];
  List<Map<String, dynamic>> parties = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCandidates();
    _fetchParties();
  }

  Future<void> _fetchCandidates() async {
    final snapshot = await FirebaseFirestore.instance.collection('candidates')
        .get();
    setState(() {
      candidates =
          snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
    });
  }

  Future<void> _fetchParties() async {
    final snapshot = await FirebaseFirestore.instance.collection('parties')
        .get();
    setState(() {
      parties = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }

  List<Map<String, dynamic>> get filteredCandidates {
    return candidates.where((candidate) {
      final matchParty = selectedParty == null ||
          candidate['party'] == selectedParty;
      final matchState = selectedState == null ||
          candidate['state'] == selectedState;
      final matchType = selectedType == null ||
          candidate['type'] == selectedType;
      return matchParty && matchState && matchType;
    }).toList();
  }

  Widget _buildDropdown(String title, List<String> options, String? selected,
      void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: selected,
      decoration: InputDecoration(
          labelText: title, border: OutlineInputBorder()),
      items: options.map((item) =>
          DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCandidateCard(Map<String, dynamic> candidate) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(candidate['name'] ?? '',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text("Party: ${candidate['party']}"),
            Text("State: ${candidate['state']}"),
            Text("Type: ${candidate['type']}"),
            SizedBox(height: 6),
            if (candidate['manifesto'] != null)
              Text("Manifesto: ${candidate['manifesto']}", maxLines: 3,
                  overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyTile(Map<String, dynamic> party) {
    return ListTile(
      leading: party['logoUrl'] != null
          ? Image.network(party['logoUrl'], width: 40, height: 40)
          : Icon(Icons.flag),
      title: Text(party['name'], style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
          "Leader: ${party['leader'] ?? 'N/A'}\nSymbol: ${party['symbol'] ??
              'N/A'}"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.blue, // Optional: change tab background color
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
              // ---------- Candidates Tab ----------
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Filter Options
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            "Party",
                            candidates.map((c) => c['party'].toString())
                                .toSet()
                                .toList(),
                            selectedParty,
                                (val) => setState(() => selectedParty = val),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildDropdown(
                            "State",
                            candidates.map((c) => c['state'].toString())
                                .toSet()
                                .toList(),
                            selectedState,
                                (val) => setState(() => selectedState = val),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    _buildDropdown(
                      "Candidate Type",
                      candidates.map((c) => c['type'].toString())
                          .toSet()
                          .toList(),
                      selectedType,
                          (val) => setState(() => selectedType = val),
                    ),
                    SizedBox(height: 10),
                    // Candidate List
                    Expanded(
                      child: filteredCandidates.isEmpty
                          ? Center(
                          child: Text("No candidates match your filters."))
                          : PageView.builder(
                        itemCount: filteredCandidates.length,
                        controller: PageController(viewportFraction: 0.9),
                        itemBuilder: (context, index) {
                          return _buildCandidateCard(filteredCandidates[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // ---------- Party Tab ----------
              parties.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: parties.length,
                itemBuilder: (context, index) {
                  return _buildPartyTile(parties[index]);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}