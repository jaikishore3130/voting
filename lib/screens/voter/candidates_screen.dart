import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CandidatesScreen extends StatefulWidget {
  @override
  _CandidatesScreenState createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  String? selectedElection;
  String? selectedState;
  String? selectedParty;

  List<Map<String, dynamic>> allCandidates = [];
  List<Map<String, dynamic>> displayedCandidates = [];

  List<Map<String, dynamic>> parties = [];
  List<String> allStates = [];

  int candidatesToShow = 20;
  bool _isLoadingMore = false;
  bool _hasMoreCandidates = true;
  int _candidatesLimit = 20; // Number of candidates to load per "Load More"


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchParties();
    _fetchStates();
  }

  Future<void> _fetchStates() async {
    final snapshot = await FirebaseFirestore.instance.collection('LOK_SABHA').get();
    Set<String> statesSet = {};

    for (var partyDoc in snapshot.docs) {
      final candidateSnapshots = await partyDoc.reference.collection('candidates').get();
      for (var doc in candidateSnapshots.docs) {
        final state = doc['state'];
        if (state != null && state.toString().trim().isNotEmpty) {
          statesSet.add(state);
        }
      }
    }

    setState(() {
      allStates = statesSet.toList()..sort();
    });
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

  Future<void> _fetchCandidates() async {
    if (selectedElection == null || selectedElection != 'Lok Sabha') return;

    List<Map<String, dynamic>> fetchedCandidates = [];

    final snapshot = await FirebaseFirestore.instance.collection('LOK_SABHA').get();

    for (var partyDoc in snapshot.docs) {
      final partyName = partyDoc.id;

      // Filter by selected party
      if (selectedParty != null && selectedParty != partyName) continue;

      final candidateSnapshots = await FirebaseFirestore.instance
          .collection('LOK_SABHA')
          .doc(partyName)
          .collection('candidates')
          .get();

      for (var doc in candidateSnapshots.docs) {
        final data = doc.data();

        if (selectedState != null && selectedState != data['state']) continue;

        fetchedCandidates.add({
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
          'user_id': data['user_id'] ?? '',
          'state': data['state'] ?? 'Unknown',
          'constituency': data['constituency'] ?? 'Unknown',
          'permanent_address': data['permanent_address'] ?? 'N/A',
          'manifesto': data['manifesto'] ?? '',
          'imageUrl': data['profile_image'] ?? '',
        });
      }
    }

    fetchedCandidates.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

    setState(() {
      allCandidates = fetchedCandidates;
      displayedCandidates = allCandidates.take(candidatesToShow).toList();
    });
  }

  void _loadMoreCandidates() async {
    if (_isLoadingMore || !_hasMoreCandidates) return;

    setState(() => _isLoadingMore = true);

    await Future.delayed(Duration(milliseconds: 300)); // optional UI delay

    final nextCandidates = allCandidates
        .skip(displayedCandidates.length)
        .take(_candidatesLimit)
        .toList();

    setState(() {
      displayedCandidates.addAll(nextCandidates);
      _isLoadingMore = false;
      _hasMoreCandidates = displayedCandidates.length < allCandidates.length;
    });
  }


  void _resetFiltersAndCandidates() {
    candidatesToShow = 20;
    allCandidates.clear();
    displayedCandidates.clear();
  }

  Widget _dropdownWrapper({required String title, required List<String> items, String? selected, required Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(
      value: selected,
      decoration: InputDecoration(labelText: title, border: OutlineInputBorder()),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredStates = selectedParty == null
        ? allStates
        : _getStatesByParty(selectedParty!);

    final filteredParties = selectedState == null
        ? parties
        : _getPartiesByState(selectedState!);

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
                    _dropdownWrapper(
                      title: "Select Election",
                      items: ["Lok Sabha"],
                      selected: selectedElection,
                      onChanged: (val) {
                        setState(() {
                          selectedElection = val;
                          selectedState = null;
                          selectedParty = null;
                          _resetFiltersAndCandidates();
                          _fetchCandidates();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // STATE DROPDOWN WITH CLEAR ICON
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedState,
                            decoration: InputDecoration(
                              labelText: 'Select State',
                              suffixIcon: selectedState != null
                                  ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    selectedState = null;
                                    _resetFiltersAndCandidates();
                                    _fetchCandidates();
                                  });
                                },
                              )
                                  : null,
                            ),
                            items: filteredStates.map((state) {
                              return DropdownMenuItem<String>(
                                value: state,
                                child: Text(state, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                selectedState = val;
                                _resetFiltersAndCandidates();
                                _fetchCandidates();
                              });
                            },
                          ),
                        ),


                        SizedBox(width: 10),

                        // PARTY DROPDOWN WITH CLEAR ICON
                        Expanded(
                          child: Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                decoration: InputDecoration(labelText: 'Select Party'),
                                value: selectedParty,
                                items: filteredParties.map((party) {
                                  return DropdownMenuItem<String>(
                                    value: party['name'],
                                    child: Text(party['name'], overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedParty = val;
                                    _resetFiltersAndCandidates();
                                    _fetchCandidates();
                                  });
                                },
                              ),
                              if (selectedParty != null)
                                Positioned(
                                  right: 0,
                                  child: IconButton(
                                    icon: Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        selectedParty = null;
                                        _resetFiltersAndCandidates();
                                        _fetchCandidates();
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),


                    const SizedBox(height: 10),
                    Expanded(
                      child: displayedCandidates.isEmpty
                          ? Center(child: Text("No candidates to show."))
                          : NotificationListener<ScrollNotification>(
                        onNotification: (ScrollNotification scrollInfo) {
                          if (scrollInfo.metrics.pixels ==
                              scrollInfo.metrics.maxScrollExtent &&
                              displayedCandidates.length < allCandidates.length) {
                            _loadMoreCandidates();
                          }
                          return false;
                        },
                        child: ListView.builder(
                          itemCount: displayedCandidates.length + 1, // +1 for "Load More" button
                          itemBuilder: (context, index) {
                            if (index < displayedCandidates.length) {
                              return _buildCandidateCard(displayedCandidates[index]);
                            } else {
                              // Show Load More Button only if more candidates exist
                              return (displayedCandidates.length < allCandidates.length)
                                  ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: TextButton(
                                    onPressed: _loadMoreCandidates,
                                    child: Text(
                                      "Load More",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                                  : SizedBox.shrink(); // If no more candidates, show nothing
                            }
                          },
                        ),

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

  List<String> _getStatesByParty(String party) {
    Set<String> result = {};
    for (var candidate in allCandidates) {
      if (candidate['party'] == party && candidate['state'] != null) {
        result.add(candidate['state']);
      }
    }
    return result.toList();
  }

  List<Map<String, dynamic>> _getPartiesByState(String state) {
    Set<String> partyNames = {};
    for (var candidate in allCandidates) {
      if (candidate['state'] == state && candidate['party'] != null) {
        partyNames.add(candidate['party']);
      }
    }
    return parties.where((party) => partyNames.contains(party['name'])).toList();
  }

  // Reuse your original methods for candidate popup and UI rendering
  Widget _buildCandidateCard(Map<String, dynamic> candidate) {
    return GestureDetector(
      onTap: () => _showCandidatePopup(candidate),
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: CircleAvatar(
            radius: 30,
            backgroundImage: (candidate['imageUrl'] != null && candidate['imageUrl'].toString().isNotEmpty)
                ? NetworkImage(candidate['imageUrl'])
                : null,
            child: (candidate['imageUrl'] == null || candidate['imageUrl'].toString().isEmpty)
                ? Icon(Icons.person, size: 30)
                : null,
          ),
          title: Text(candidate['name'], style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("Party: ${candidate['party']}\nConstituency: ${candidate['constituency']}"),
        ),
      ),
    );
  }

  Widget _buildPartyTile(Map<String, dynamic> party) {
    return Card(
      child: ListTile(
        leading: party['logoUrl'] != null && party['logoUrl'].toString().isNotEmpty
            ? CircleAvatar(backgroundImage: NetworkImage(party['logoUrl']))
            : CircleAvatar(child: Icon(Icons.flag)),
        title: Text(party['name']),
        subtitle: Text("Leader: ${party['leader']}\nSymbol: ${party['symbol']}"),
      ),
    );
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

// Reuse your existing popup implementation here.
  }

