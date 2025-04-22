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
  Color _statusColor = Colors.grey;
  IconData _statusIcon = Icons.hourglass_top;

  @override
  void initState() {
    super.initState();
    _fetchNominationStatus();
  }

  Future<void> _fetchNominationStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('nominations')
          .doc('list')
          .collection(widget.subCollectionId)
          .doc(widget.aadhaarNumber)
          .get();

      if (!doc.exists) {
        setState(() {
          _statusMessage = "No nomination found.";
          _statusColor = Colors.orange;
          _statusIcon = Icons.info_outline;
        });
        return;
      }

      final data = doc.data()!;
      final deputyStatus = data['deputy_head_status'] ?? 'submitted';
      final ecHeadStatus = data['ec_head_status'] ?? '';
      final rejectionReason = data['rejection_reason'];

      if (rejectionReason != null && rejectionReason.isNotEmpty) {
        setState(() {
          _statusMessage = "❌ Your nomination was rejected.";
          _rejectionReason = rejectionReason;
          _statusColor = Colors.red.shade600;
          _statusIcon = Icons.cancel;
        });
      } else if (ecHeadStatus == 'approved') {
        setState(() {
          _statusMessage = "✅ Approved by EC Head.";
          _statusColor = Colors.green;
          _statusIcon = Icons.verified;
        });
      } else if (deputyStatus == 'approved') {
        setState(() {
          _statusMessage = "✅ Approved by EC Deputy Head.";
          _statusColor = Colors.blue;
          _statusIcon = Icons.thumb_up_alt_outlined;
        });
      } else {
        setState(() {
          _statusMessage = "⏳ Submitted to EC Deputy Head.";
          _statusColor = Colors.orangeAccent;
          _statusIcon = Icons.hourglass_bottom;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "⚠️ Error: ${e.toString()}";
        _statusColor = Colors.red;
        _statusIcon = Icons.error_outline;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: _statusColor.withOpacity(0.1),
                child: Icon(_statusIcon, size: 40, color: _statusColor),
              ),
              const SizedBox(height: 20),
              Text(
                "Nomination Status",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: _statusColor),
              ),
              if (_rejectionReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_outlined, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Reason: $_rejectionReason",
                          style: const TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
