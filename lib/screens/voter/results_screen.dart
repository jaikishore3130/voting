import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ResultsScreen extends StatelessWidget {
  final List<String> electionTypes = [
    'Lok Sabha',
    'Vidhan Sabha',
    'Rajya Sabha',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: electionTypes.length,
      itemBuilder: (context, index) {
        final election = electionTypes[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(election, style: TextStyle(fontSize: 18)),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => ElectionResultDialog(electionType: election),
              );
            },
          ),
        );
      },
    );
  }
}

class ElectionResultDialog extends StatefulWidget {
  final String electionType;

  const ElectionResultDialog({required this.electionType});

  @override
  _ElectionResultDialogState createState() => _ElectionResultDialogState();
}

class _ElectionResultDialogState extends State<ElectionResultDialog> {
  bool isLoading = true;
  String? winningParty;
  String? winningSymbol;
  Map<String, int> partyWinCount = {};
  List<Map<String, dynamic>> winners = [];

  @override
  void initState() {
    super.initState();
    fetchResults();
  }

  Future<void> fetchResults() async {
    final collectionName = widget.electionType.toUpperCase().replaceAll(' ', '_');
    final firestore = FirebaseFirestore.instance;
    final electionRef = firestore.collection(collectionName);

    Map<String, int> countMap = {};
    List<Map<String, dynamic>> winnerList = [];
    String? topParty;
    String? topSymbol;
    int maxCount = 0;

    final partyDocs = await electionRef.get();

    for (var partyDoc in partyDocs.docs) {
      final candidatesSnap = await electionRef
          .doc(partyDoc.id)
          .collection('candidates')
          .where('winner', isEqualTo: true)
          .get();

      for (var doc in candidatesSnap.docs) {
        final data = doc.data();
        winnerList.add(data);

        final party = data['party'] ?? partyDoc.id;
        final symbol = data['symbol'];

        countMap[party] = (countMap[party] ?? 0) + 1;

        if (countMap[party]! > maxCount) {
          maxCount = countMap[party]!;
          topParty = party;
          topSymbol = symbol;
        }
      }
    }

    setState(() {
      partyWinCount = countMap;
      winners = winnerList;
      winningParty = topParty;
      winningSymbol = topSymbol;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: isLoading
          ? Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator()),
      )
          : Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button and winner
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade300,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  if (winningSymbol != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.network(
                        winningSymbol!,
                        height: 50,
                        width: 50,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.flag, size: 40),
                      ),
                    ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "🏆 $winningParty",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
                          color:Colors.black54,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Seats Won by Parties", style: TextStyle(fontSize: 16)),
                    SizedBox(height: 16),
                    PartySeatPieChart(data: partyWinCount),
                    SizedBox(height: 16),
                    Text("Winning Candidates", style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: winners.length,
                      itemBuilder: (_, i) {
                        final c = winners[i];
                        return ListTile(
                          leading: Icon(Icons.person),
                          title: Text(c['name'] ?? 'Unknown'),
                          subtitle: Text('${c['party']} - ${c['constituency']}'),
                        );
                      },
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
}

class PartySeatPieChart extends StatelessWidget {
  final Map<String, int> data;

  const PartySeatPieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0, (sum, val) => sum + val);
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top5 = sortedEntries.take(5).toList();
    final othersTotal = sortedEntries.skip(5).fold(0, (sum, e) => sum + e.value);
    final displayEntries = [...top5];
    if (othersTotal > 0) {
      displayEntries.add(MapEntry('Others', othersTotal));
    }

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.grey, // for "Others"
    ];

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.5,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              startDegreeOffset: -90,
              sections: displayEntries.mapIndexed((index, entry) {
                final percentage = (entry.value / total) * 100;
                return PieChartSectionData(
                  value: entry.value.toDouble(),
                  title: '${percentage.toStringAsFixed(1)}%',
                  color: colors[index % colors.length],
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              pieTouchData: PieTouchData(enabled: true),
            ),
            swapAnimationDuration: Duration(milliseconds: 800),
            swapAnimationCurve: Curves.easeInOutCubic,
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: displayEntries.mapIndexed((index, entry) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: colors[index % colors.length],
                ),
                SizedBox(width: 6),
                Text('${entry.key} (${entry.value})'),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

extension MapIndexedExtension<K, V> on Iterable<MapEntry<K, V>> {
  Iterable<T> mapIndexed<T>(T Function(int index, MapEntry<K, V> e) f) {
    int index = 0;
    return map((e) => f(index++, e));
  }
}
