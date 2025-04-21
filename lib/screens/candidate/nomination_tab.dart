import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NominationTab extends StatefulWidget {
  final String aadhaarNumber;
  final String subCollectionId;

  const NominationTab({
    super.key,
    required this.aadhaarNumber,
    required this.subCollectionId,
  });

  @override
  State<NominationTab> createState() => _NominationTabState();
}

class _NominationTabState extends State<NominationTab> {
  String _statusMessage = "Fetching nomination status...";
  String? _rejectionReason;

  @override
  void initState() {
    super.initState();
    _fetchNominationStatus();
  }

  Future<void> _fetchNominationStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('nominations').doc('list').collection(widget.subCollectionId)
          .doc(widget.aadhaarNumber)
          .get();

      if (!doc.exists) {
        setState(() {
          _statusMessage = "No nomination found.";
        });
        return;
      }

      final data = doc.data()!;
      final deputyStatus = data['deputy_head_status'] ?? 'submitted';
      final ecHeadStatus = data['ec_head_status'] ?? '';
      final rejectionReason = data['rejection_reason'];

      if (rejectionReason != null && rejectionReason.isNotEmpty) {
        setState(() {
          _statusMessage = "Your nomination was rejected.";
          _rejectionReason = rejectionReason;
        });
      } else if (ecHeadStatus == 'approved') {
        setState(() {
          _statusMessage = "Your nomination is approved by EC Head.";
        });
      } else if (deputyStatus == 'approved') {
        setState(() {
          _statusMessage = "EC Deputy Head approved your nomination.";
        });
      } else {
        setState(() {
          _statusMessage = "Your nomination has been submitted to EC Deputy Head.";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error fetching status: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.how_to_vote, size: 60, color: Colors.deepPurple),
            SizedBox(height: 20),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            if (_rejectionReason != null) ...[
              SizedBox(height: 10),
              Text(
                "Reason: $_rejectionReason",
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
