
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VotingScreen extends StatefulWidget {
  final Map<String, dynamic> election;

  const VotingScreen({super.key, required this.election});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  List<Map<String, dynamic>> candidates = [
    {"name": "Candidate A", "id": "candidate_a"},
    {"name": "Candidate B", "id": "candidate_b"},
  ]; // Replace with filtered candidates from voter's constituency

  void _handleVote(String candidateId) async {
    final confirmed = await _showCaptchaAndOTPConfirmation();
    if (!confirmed) return;

    await _submitVote(candidateId);
    _showSuccessDialog();
  }

  Future<bool> _showCaptchaAndOTPConfirmation() async {
    // You can add a CAPTCHA widget and OTP screen here
    // Simulate success:
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }

  Future<void> _submitVote(String candidateId) async {
    final encryptedVote = _encryptVote(candidateId);
    final encryptedUser = _encryptUser(); // if needed

    await FirebaseFirestore.instance.collection("votes").add({
      "election_id": widget.election["id"],
      "candidate_id": encryptedVote,
      "user_id": encryptedUser,
      "timestamp": FieldValue.serverTimestamp(),
      "visible": false, // Keep hidden until polling_end
    });
  }

  String _encryptVote(String candidateId) {
    // Use your AES encryption here
    return candidateId; // temp for demo
  }

  String _encryptUser() {
    // Encrypt Aadhaar or user id
    return "user_encrypted";
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Vote Submitted"),
        content: const Text("Your vote has been securely submitted."),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Voting - ${widget.election['election_type']}')),
      body: ListView.builder(
        itemCount: candidates.length,
        itemBuilder: (context, index) {
          final candidate = candidates[index];
          return ListTile(
            title: Text(candidate["name"]),
            onTap: () => _handleVote(candidate["id"]),
          );
        },
      ),
    );
  }
}
