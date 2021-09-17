/*
 * Wrapper job is to check whether the current user is signed in in which he/she would be redirected to 
 * the home screen, or to the sign in or register screen if they're not
 */

import 'package:flutter/material.dart';
import 'package:rillliveapp/authentication/signin.dart';
import 'package:rillliveapp/screens/main_screen.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({Key? key, required this.userSignedIn}) : super(key: key);
  final bool userSignedIn;
  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  var _isUserVerified = false;
  var _isUserSignedIn = false;

  @override
  void initState() {
    super.initState();
    //Initiate a future to check user verification
  }

  @override
  Widget build(BuildContext context) {
    return _isUserVerified && _isUserSignedIn
        ? const MainScreen()
        : const SignInSignUp();
  }
}
