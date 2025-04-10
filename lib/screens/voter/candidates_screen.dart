import 'package:flutter/material.dart';
import 'candidates.dart';
import 'parties_screen.dart';

class CandidatesScreen extends StatelessWidget {
  const CandidatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.black,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: 'Candidates'),
              Tab(text: 'Parties'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                Candidates(),
                PartiesScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
