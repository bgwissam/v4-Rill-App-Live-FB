/*
 * Wrapper job is to check whether the current user is signed in in which he/she would be redirected to 
 * the home screen, or to the sign in or register screen if they're not
 */

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rillliveapp/authentication/signin.dart';
import 'package:rillliveapp/models/file_model.dart';
import 'package:rillliveapp/screens/main_screen.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/parameters.dart';
import 'models/user_model.dart';

class Wrapper extends StatefulWidget {
  final bool? guestUser;
  const Wrapper({Key? key, this.guestUser}) : super(key: key);

  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  var _isUserVerified = false;
  var _isUserSignedIn = false;
  var _guestUser = false;
  late UserModel? currentUser;
  DatabaseService db = DatabaseService();
  FirebaseMessaging _fcm = FirebaseMessaging.instance;
  String? token;
  @override
  void initState() {
    super.initState();
    _guestUser = widget.guestUser!;
    _getFcmToken();
  }

  _getFcmToken() async {
    token = await _fcm.getToken();
  }

  _addFcmToken() async {
    if (currentUser?.userId != null && currentUser?.fcmToken != null) {
      if (currentUser?.fcmToken != token) {
        await db.userModelCollection
            .doc(currentUser?.userId)
            .update({UserParams.FCM_TOKEN: token});
      }
    }
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
      _addFcmToken();
      setState(() {
        _isUserSignedIn = true;
      });
    }
    return _isUserSignedIn || _guestUser
        ? MultiProvider(
            providers: [
                //provides current user data
                StreamProvider<UserModel>.value(
                  value: db.streamUserById(userId: currentUser?.userId),
                  initialData: UserModel(),
                  catchError: (context, error) {
                    print('Error Current User Stream: $error');
                    return UserModel();
                  },
                ),
                //provides a stream of uploaded images and videos
                StreamProvider<List<ImageVideoModel?>>.value(
                  value: db.getImageList(),
                  initialData: [],
                  catchError: (context, error) {
                    print('Error fetching all feed: $error');
                    return [];
                  },
                ),
                //live streaming videos
                StreamProvider<List<StreamingModel?>>.value(
                  value: db.getStreamingVidoes(),
                  initialData: [],
                  catchError: (context, error) {
                    print('Error fetching live streams: $error');
                    return [];
                  },
                ),
                //ended streaming videos
                StreamProvider<List<EndedStreamsModel?>>.value(
                  value: db.getEndedStreamingVidoes(),
                  initialData: [],
                  catchError: (context, error) {
                    print('Error fetching ended stream: $error');
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
