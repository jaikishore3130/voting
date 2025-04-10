import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class Candidates extends StatefulWidget {
  @override
  _CandidatesState createState() => _CandidatesState();
}

class _CandidatesState extends State<Candidates> {
  late List<Map<String, dynamic>> _candidates = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  String? _selectedElection;
  String? _selectedState;
  String? _selectedParty;

  final List<String> electionTypes = [
    'Lok Sabha',
    'Vidhan Sabha',
    'Rajya Sabha'
  ];
  final List<String> states = [
    'All States','Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh', 'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh',
    'Jharkhand', 'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland',
    'Odisha','Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand','West Bengal',
    'Andaman and Nicobar Islands', 'Chandigarh','Dadra and Nagar Haveli and Daman and Diu', 'Lakshadweep', 'Delhi', 'Puducherry',
  ];
  // fetch dynamically if needed
  final List<String> parties = [
    'All Parties', 'BJP', 'TRS', 'INC', 'BSP', 'NCP', 'VBA', 'APoI', 'CPI(M)', 'BDJS', 'AITC', 'RSP', 'SP', 'YSRCP',
    'TDP', 'JnP', 'INLD', 'SBSP', 'IND', 'SHS', 'AAP', 'SAD', 'JKN', 'JKPDP','JPC', 'DMK', 'PMK', 'NTK', 'MNM', 'AIADMK', 'RJD',
    'CPI(ML)(L)', 'SSD', 'PPA', 'JD(S)', 'NPEP', 'BMUP', 'BJD', 'AIMIM', 'HAMS', 'AHFBK', 'PPID', 'SPL', 'ASDC', 'RLD', 'PSPL',
    'JD(U)', 'BTP', 'AIFB', 'AGP', 'AIUDF', 'ABSKP', 'PUNEKP', 'RTORP', 'JNJP', 'LTSP', 'RVNP', 'JANADIP', 'SDPI', 'DMDK',
    'ABGP', 'VCK', 'JMM', 'LIP', 'JDR', 'MOSP', 'MADP', 'AJPR', 'PMP', 'BBMP', 'AJSUP', 'JVM', 'RMPOI', 'LJP',
    'BJKVP', 'SWP', 'NEINDP', 'RSPSR', 'ravp', 'RSOSP', 'BLSP', 'WPOI', 'SUCI(C)', 'SJDD', 'ANC', 'JDL', 'VSIP', 'AAM', 'JKP',
    'BOPF', 'UPPL', 'CPIM', 'GGP', 'KEC(M)', 'KEC', 'JAPL', 'AKBMP', 'TJS', 'IUML', 'BSCP', 'ADAL', 'BRPI', 'MNF', 'PRISMP',
    'VPI', 'YKP', 'NDPP', 'RLTP', 'RAHIS', 'NPF', 'BLSD', 'BVA', 'NAWPP', 'AINRC', 'BNDl', 'MSHP', 'BARESP', 'BLRP', 'AIPF',
    'WAP', 'VCSMP', 'SAD(M)', 'UDP', 'SKM', 'SDF', 'PDP', 'JHP', 'TMC(M)', 'IPFT', 'JKNPP', 'DSSP', 'AHNP', 'PHJSP'
  ];

// fetch dynamically if needed

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
  }

  Future<void> _fetchCandidates({bool isLoadMore = false}) async {
    if (_isLoading || (!_hasMore && !isLoadMore) || _selectedElection == null) return; // Don't fetch if no election type is selected or there are no more candidates

    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> fetchedCandidates = [];

      final String electionType = _selectedElection?.toUpperCase().replaceAll(' ', '_') ?? 'defaultElectionType';
      print(electionType); // Provide a default value

      // Initialize query to get the first set of candidates or load more if required
      Query query = FirebaseFirestore.instance.collection(electionType);

      // If we're loading more candidates, use startAfterDocument() for pagination
      if (isLoadMore && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!); // Start from last document
      }

      // Fetch snapshot for the selected election type
      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        _hasMore = false; // No more candidates to load
      }

      // Loop through each party and fetch candidates
      for (var partyDoc in snapshot.docs) {
        final partyName = partyDoc.id;

        // Filter by selected party
        if (_selectedParty != null && _selectedParty != 'All Parties' && _selectedParty != partyName) continue;

        final candidateSnapshots = await FirebaseFirestore.instance
            .collection(electionType) // Use selected election type
            .doc(partyName)
            .collection('candidates')
            .limit(5) // Limit the number of candidates to 20 per batch
            .get();

        for (var doc in candidateSnapshots.docs) {
          final data = doc.data();

          // Filter by selected state
          if (_selectedState != null && _selectedState != 'All States' && _selectedState != data['state']) continue;

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
            'profile_image': data['profile_image'] ?? '',
          });
        }
      }

      // Set the last document for pagination
      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      // Sort candidates by name
      fetchedCandidates.sort((a, b) => a['name'].toString().compareTo(b['name'].toString()));

      setState(() {
        if (isLoadMore) {
          _candidates.addAll(fetchedCandidates);  // Append new candidates to the list
        } else {
          _candidates = fetchedCandidates;  // Initial load (when isLoadMore is false)
        }
      });
    } catch (e) {
      print('❌ Error fetching candidates: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showCandidatePopup(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Stack(
            children: [
              // External Background (Blurred)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),

                ),
              ),

              // Internal Dialog Content (White)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(

                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: data['profile_image'] != null && data['profile_image'].isNotEmpty
                          ? CachedNetworkImageProvider(data['profile_image'])
                          : AssetImage('assets/default_avatar.png') as ImageProvider,
                      child: data['profile_image'] == null || data['profile_image'].isEmpty
                          ? Icon(Icons.person, size: 50)
                          : null,
                    ),
                    SizedBox(height: 12),
                    Text(
                      data['name'] ?? 'Unnamed',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    _popupRow('Party', data['party']),
                    _popupRow('Age', data['age']),
                    _popupRow('Gender', data['gender']),
                    _popupRow('Education', data['education']),
                    _popupRow('Address', data['permanent_address']),
                    _popupRow('Criminal Cases', data['criminal_history']),
                    _popupRow('Assets', data['assets']),
                    _popupRow('Liabilities', data['liabilities']),
                    _popupRow('Votes', data['votes_received'].toString()),
                    _popupRow('Winner', data['winner'].toString()),
                    _popupRow('Email', data['email']),
                    _popupRow('Phone', data['phone']),
                    _popupRow('State', data['state']),
                    _popupRow('Constituency', data['constituency']),
                  ],
                ),
              ),

              // Close Button
              Positioned(
                right: 10,
                top: 10,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey.shade300,
                    child: Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  Widget _popupRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value?.toString() ?? 'N/A'),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Election type dropdown (full width with border)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text('Select Election Type'),
                value: _selectedElection,
                onChanged: (val) {
                  setState(() {
                    _selectedElection = val;
                    _candidates.clear();
                    _lastDocument = null;
                    _hasMore = true;
                  });
                  _fetchCandidates();
                },
                items: electionTypes.map((e) =>
                    DropdownMenuItem(value: e, child: Text(e))).toList(),
              ),
            ),
          ),
        ),

        // Show message if no election type is select
        // State and Party dropdowns
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // State Dropdown
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      hint: Text('State'),
                      value: _selectedState,
                      isExpanded: true,
                      onChanged: (val) {
                        setState(() {
                          _selectedState = val;
                          _candidates.clear();
                          _lastDocument = null;
                          _hasMore = true;
                        });
                        _fetchCandidates();
                      },
                      items: states.map((e) =>
                          DropdownMenuItem(value: e, child: Text(e))).toList(),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 10),

              // Party Dropdown
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      hint: Text('Party'),
                      value: _selectedParty,
                      isExpanded: true,
                      onChanged: (val) {
                        setState(() {
                          _selectedParty = val;
                          _candidates.clear();
                          _lastDocument = null;
                          _hasMore = true;
                        });
                        _fetchCandidates();
                      },
                      items: parties.map((e) =>
                          DropdownMenuItem(value: e, child: Text(e))).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 10),

        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _candidates.isEmpty
              ? Center(child: Text('No candidates available.'))
              : ListView.builder(
            itemCount: _candidates.length + (_hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < _candidates.length) {
                final data = _candidates[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 50,
                    backgroundImage: data['profile_image'] != null && data['profile_image'].isNotEmpty
                        ? CachedNetworkImageProvider(data['profile_image'])
                        : AssetImage('assets/default_avatar.png') as ImageProvider,
                    child: data['profile_image'] == null || data['profile_image'].isEmpty
                        ? Icon(Icons.person, size: 45)
                        : null,
                  ),
                  title: Text(data['name'] ?? 'Unnamed',style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Party: ${data['party'] ?? 'Unknown'}'),
                  onTap: () => _showCandidatePopup(data),
                );
              } else {
                return Center(
                  child: TextButton(
                    onPressed: () => _fetchCandidates(isLoadMore: true),
                    child: _isLoading
                        ? CircularProgressIndicator()  // Show loading indicator when fetching
                        : Text('Load More',
                    style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

}
