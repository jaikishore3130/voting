import 'package:flutter/material.dart';
import 'package:voting/screens/splash_screen.dart';
import 'package:voting/screens/authentication_screen.dart';
import 'package:voting/screens/voter_login_screen.dart';
import 'package:voting/screens/candidate_login_screen.dart';
import 'package:voting/screens/ec_login_screen.dart';
import 'package:voting/screens/voter/vote_now_screen.dart';

class Routes {
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/': (context) => SplashScreen(),
      '/auth': (context) => AuthenticationScreen(),
      '/voterLogin': (context) => VoterLoginScreen(userType: 'voter',),
      '/candidateLogin': (context) => CandidateLoginScreen(),
      '/ecLogin': (context) => ECLoginScreen(),

    };
  }
}
