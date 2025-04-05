import 'package:flutter/material.dart';

class VoteNowScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Ongoing"),
              Tab(text: "Upcoming"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                Center(child: Text("List of Ongoing Elections")),
                Center(child: Text("List of Upcoming Elections")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
