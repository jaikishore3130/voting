import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class VotingInstructionsDialog extends StatefulWidget {
  const VotingInstructionsDialog({super.key});

  @override
  State<VotingInstructionsDialog> createState() => _VotingInstructionsDialogState();
}

class _VotingInstructionsDialogState extends State<VotingInstructionsDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> steps = [
    {
      'title': 'Step 1: Login',
      'desc': 'Login using your Aadhaar number and OTP verification.',
      'animation': 'assets/animations/voting step 1.json',
    },
    {
      'title': 'Step 2: Biometric Verification',
      'desc': 'Authenticate your identity with fingerprint or face scan.',
      'animation': 'assets/animations/voting step 2.json',
    },
    {
      'title': 'Step 3: Vote',
      'desc': 'Choose your candidate and submit your vote securely.',
      'animation': 'assets/animations/voting step 3.json',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(16),
      content: SizedBox(
        height: screenHeight * 0.6,
        width: screenWidth * 0.85,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: steps.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: screenHeight * 0.25,
                        child: Lottie.asset(
                          steps[index]['animation']!,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        steps[index]['title']!,
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          steps[index]['desc']!,
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                steps.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 12 : 8,
                  height: _currentPage == index ? 12 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.blue : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_currentPage == steps.length - 1)
              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF05285E),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
                ],
        ),
      ),
    );
  }
}
