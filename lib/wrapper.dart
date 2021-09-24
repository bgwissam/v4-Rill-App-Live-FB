/*
 * Wrapper job is to check whether the current user is signed in in which he/she would be redirected to 
 * the home screen, or to the sign in or register screen if they're not
 */

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rillliveapp/authentication/signin.dart';
import 'package:rillliveapp/models/file_model.dart';
import 'package:rillliveapp/screens/main_screen.dart';
import 'package:rillliveapp/services/database.dart';

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
  DatabaseService db = DatabaseService();
  @override
  void initState() {
    super.initState();
    //Initiate a future to check user verification
  }

  //check if user is verified
  Future<String?> checkSignedInUser() async {
    var userResult = FirebaseAuth.instance.currentUser;
    if (userResult != null) {
      if (userResult.emailVerified) {
        _isUserVerified = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    currentUser = Provider.of<UserModel?>(context);
    if (currentUser?.userId != null) {
      setState(() {
        _isUserSignedIn = true;
      });
    }
    return _isUserSignedIn
        ? MultiProvider(
            providers: [
                StreamProvider<UserModel>.value(
                  value: db.streamUserById(userId: currentUser?.userId),
                  initialData: UserModel(),
                  catchError: (context, error) {
                    print('Error Current User Stream: $error');
                    return UserModel();
                  },
                ),
                StreamProvider<List<ImageVideoModel?>>.value(
                  value: db.getImageList(),
                  initialData: [],
                  catchError: (context, error) {
                    print('Error fetching all feed: $error');
                    return [];
                  },
                ),
                StreamProvider<List<StreamingModel?>>.value(
                  value: db.getStreamingVidoes(),
                  initialData: [],
                  catchError: (context, error) {
                    print('Error fetching image stream: $error');
                    return [];
                  },
                ),
              ],
            child: MainScreen(
              userId: currentUser?.userId,
              currenUser: currentUser,
            ))
        : const SignInSignUp();
  }
}
