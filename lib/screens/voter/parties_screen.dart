import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PartiesScreen extends StatelessWidget {
  final Query<Map<String, dynamic>> _partiesQuery =
  FirebaseFirestore.instance.collection('LOK_SABHA');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _partiesQuery.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator(),);

        final docs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final party = docs[index].data();
            final partyName = docs[index].id;

            return ListTile(
              leading: party['logoUrl'] != null
                  ? Image.network(party['logoUrl'], width: 50,
                  height: 50,
                  errorBuilder: (_, __, ___) => Icon(Icons.flag))
                  : Icon(Icons.flag),
              title: Text(
                partyName, style: TextStyle(fontWeight: FontWeight.bold),),
              subtitle: Text('Leader: ${party['leader'] ??
                  'Unknown'} \nParty Symbol:${party['symbol'] ?? 'Unknown'}'),
              onTap: () => _showPartyDialog(context, partyName, party),
            );
          },
        );
      },
    );
  }


  void _showPartyDialog(BuildContext context, String name, Map<String, dynamic> party) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,  // Make dialog background transparent
        child: Stack(
          children: [
            // This is the blurred background (everything behind the dialog)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),

            ),
            // The actual content of the dialog with a white background
            AlertDialog(
              backgroundColor: Colors.white, // Set internal background to white
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name),
                  GestureDetector(
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
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (party['logoUrl'] != null)
                    Image.network(
                      party['logoUrl'],
                      width: 200,
                      height: 200,
                      errorBuilder: (_, __, ___) => Icon(Icons.flag),
                    ),
                  SizedBox(height: 10),
                  Text("Leader: ${party['leader'] ?? 'Unknown'}"),
                  Text("Symbol: ${party['symbol'] ?? ''}"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}