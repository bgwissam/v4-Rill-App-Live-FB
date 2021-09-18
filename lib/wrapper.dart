/*
 * Wrapper job is to check whether the current user is signed in in which he/she would be redirected to 
 * the home screen, or to the sign in or register screen if they're not
 */

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rillliveapp/authentication/signin.dart';
import 'package:rillliveapp/screens/main_screen.dart';

import 'models/user_model.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  var _isUserVerified = false;
  var _isUserSignedIn = false;
  late UserModel? currentUser;
  @override
  void initState() {
    super.initState();
    //Initiate a future to check user verification
  }

  //check if user is verified
  Future<String?> checkSignedInUser() async {
    var userResult = FirebaseAuth.instance.currentUser;
    print('User verified: $userResult');
    if (userResult != null) {
      if (userResult.emailVerified) {
        _isUserVerified = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    currentUser = Provider.of<UserModel?>(context);
    print('User signed In: ${currentUser?.userId}');
    if (currentUser?.userId != null) {
      setState(() {
        _isUserSignedIn = true;
      });
    }
    return _isUserSignedIn
        ? MainScreen(userId: currentUser?.userId)
        : const SignInSignUp();
  }
}
