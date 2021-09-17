import 'package:firebase_auth/firebase_auth.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  DatabaseService db = DatabaseService();
  var newUser;

  //Create a user object based on firebase user
  UserModel? _userFromFirebaseUser(User? user) {
    return user != null ? UserModel(userId: user.uid) : null;
  }

  //Change user screen when user is obtained
  Stream<UserModel?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }

  //Get user id from attributes
  Future<String> getUserIdFromUserAttributes() async {
    return '';
  }

  //Attempt to login check if user is signed in
  Future<String> attemptAutoLogin() async {
    return '';
  }

  //This section will cover the authentication part of firebase
  //Id token changes
  Future<void> listenToAuthChanges() async {
    try {
      _auth.idTokenChanges().listen((User? user) {
        if (user == null) {
          print('user is signed out');
        } else {
          print('user is signed in');
        }
      });
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  //login user
  Future<UserCredential?> login(
      {String? userName, String? emailAddress, String? password}) async {
    try {
      var result = await _auth.signInWithEmailAndPassword(
        email: userName!.trim(),
        password: password!.trim(),
      );

      return result;
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  //Anonymous login
  Future signInAnonymously({String? emailAddress}) async {
    try {
      var result = await _auth.signInAnonymously();
      var user = result.user;
      if (user!.uid != null) {
        return user.uid;
      } else {
        print('failed to get user id');
        return null;
      }
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  //Verify user
  Future<bool> verifyUser() async {
    return false;
  }

  //Register user
  Future<String> signUp({
    String? userName,
    String? password,
    String? emailAddress,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? bioDescription,
    bool? isActive,
    String? mobileNumber,
    String? address,
  }) async {
    try {
      var result = await _auth.createUserWithEmailAndPassword(
          email: emailAddress!.trim(), password: password!.trim());

      var user = result.user;
      if (user != null) {
        await db
            .createUser(
          userId: user.uid,
          firstName: firstName,
          lastName: lastName,
          emailAddress: emailAddress,
          mobileNumber: mobileNumber,
          isActive: isActive,
          avatarUrl: avatarUrl,
          bioDescription: bioDescription,
          address: address,
        )
            .then((value) {
          print('The user creation result: $value');
          return value;
        });
        user = _auth.currentUser;
        try {
          await user!.sendEmailVerification();
          return user.uid;
        } catch (e, stackTrace) {
          await Sentry.captureException(e, stackTrace: stackTrace);
          print('Could not send verification: $e');
          rethrow;
        }
      }
      return '';
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  //Resend verification code
  Future<String> resendVerificationCode(
      {String? userName, String? emailAddress}) async {
    return '';
  }

  //Verify sign up
  Future<bool> confirmSignUp(
      {String? userName,
      String? emailAddress,
      String? confirmationCode}) async {
    var user = _auth.currentUser;
    try {
      await user!.sendEmailVerification();
      return true;
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return false;
    }
  }

  //Sign out users
  Future signOut() async {
    try {
      await _auth.signOut();
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  //reset password for users
  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return false;
    }
  }
}
