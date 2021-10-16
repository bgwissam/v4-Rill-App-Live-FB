import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:rillliveapp/authentication/email_confirmation.dart';
import 'package:rillliveapp/authentication/register.dart';
import 'package:rillliveapp/models/file_model.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/screens/main_screen.dart';
import 'package:rillliveapp/services/auth.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/loading_animation.dart';
import 'package:rillliveapp/shared/loading_view.dart';

import '../wrapper.dart';

class SignInSignUp extends StatefulWidget {
  const SignInSignUp({Key? key}) : super(key: key);

  @override
  _SignInSignUpState createState() => _SignInSignUpState();
}

class _SignInSignUpState extends State<SignInSignUp> {
  final _registerKey = GlobalKey<FormState>();
  final _signinKey = GlobalKey<FormState>();
  bool _isSigningIn = false;
  bool _isRegistering = false;
  bool _isLoading = false;
  late String userName;
  late String password;
  late String errorMessage = '';
  late String emailAddress;
  double _signingInWidgetHeight = 0;
  double _signingInWidgetWidth = 0;
  late bool _showPassword = false;
  late Future _checkSignedIn;

  //Database repositories
  AuthService as = AuthService();
  DatabaseService db = DatabaseService();
  @override
  void initState() {
    super.initState();
    _isSigningIn = false;
    _checkSignedIn = checkSignedInUser();
  }

  @override
  Widget build(BuildContext context) {
    var _size = MediaQuery.of(context).size;
    return MultiProvider(
      providers: [
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
        StreamProvider<UserModel?>.value(
          value: AuthService().user,
          initialData: null,
          catchError: (_, error) {
            print('Error streaming user: $error');
            return null;
          },
        ),
      ],
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SizedBox(
            height: _size.height,
            width: _size.width,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                //back ground image
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage('assets/images/bg3.png'),
                        fit: BoxFit.cover),
                  ),
                  //Column for buttons
                  child: FutureBuilder(
                    future: _checkSignedIn,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return const Center(
                            child: LoadingView(),
                          );
                        } else if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          print('we are here');
                          return const Center(
                            child: LoadingView(),
                          );
                        } else {
                          return Container();
                        }
                      } else {
                        return Column(
                          //mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/logo_type.png',
                              height: 250,
                              width: 250,
                            ),
                            //Sign in button
                            const SizedBox(
                              height: 30,
                            ),
                            AnimatedContainer(
                              width: _signingInWidgetWidth,
                              height: _signingInWidgetHeight,
                              alignment: Alignment.center,
                              duration: const Duration(seconds: 2),
                              curve: Curves.fastOutSlowIn,
                              child: _signIn(context),
                            ),
                            SizedBox(
                              width: _size.width - 50,
                              child: ElevatedButton(
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(color: Color(0xffdf1266)),
                                ),
                                onPressed: () async {
                                  if (!_isSigningIn) {
                                    setState(() {
                                      _signingInWidgetHeight = 130;
                                      _signingInWidgetWidth = _size.width - 50;
                                      _isSigningIn = true;
                                    });
                                  } else {
                                    if (!_signinKey.currentState!.validate()) {
                                      print('keys are not valid');
                                    } else {
                                      setState(() {
                                        _isLoading = true;
                                      });
                                      var response = await signInUser(
                                          userName: userName,
                                          password: password);
                                      if (response != null) {
                                        if (response.user!.emailVerified ==
                                            false) {
                                          as.resendVerificationCode();
                                          Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (builder) =>
                                                      EmailConfirmation()),
                                              (route) => false);
                                        } else {
                                          Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                builder: (builder) => Wrapper(
                                                  guestUser: false,
                                                ),
                                              ),
                                              (route) => false);
                                        }
                                      } else {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Color(0xffdf1266)),
                                  primary: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            //Sign up button
                            SizedBox(
                              width: _size.width - 50,
                              child: ElevatedButton(
                                child: const Text('Sign Up'),
                                onPressed: () async {
                                  WidgetsBinding.instance!
                                      .addPostFrameCallback((_) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const Register(),
                                      ),
                                    );
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Color(0xffdf1266)),
                                  primary: const Color(0xffdf1266),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            errorMessage != null
                                ? Expanded(
                                    child: Container(
                                        padding: EdgeInsets.all(10),
                                        child: Text(
                                          errorMessage,
                                          style: errorText,
                                          textAlign: TextAlign.center,
                                        )),
                                  )
                                : SizedBox.shrink(),

                            TextButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (builder) =>
                                        const Wrapper(guestUser: true),
                                  ),
                                );
                              },
                              child: const Text(
                                "Skip for now",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xffdf1266)),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {},
                              child: const Text(
                                "Browse the app as a Guest User",
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  //Other method sign in

                  //Skip button
                ),
                _isLoading
                    ? Container(
                        height: 50,
                        width: 50,
                        child: const Center(
                          child: LoadingAmination(
                            animationType: 'ThreeInOut',
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //Presents the sign in fields
  Widget _signIn(BuildContext context) {
    return Form(
      key: _signinKey,
      child: Column(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: '',
              decoration: const InputDecoration(
                  hintText: 'Email Address', filled: false),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Email address cannot be empty';
                }
                return null;
              },
              onChanged: (val) {
                setState(() {
                  userName = val.trim();
                });
              },
            ),
          ),
          Expanded(
            child: TextFormField(
              initialValue: '',
              decoration: InputDecoration(
                hintText: 'Password',
                filled: false,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                  icon: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              enableInteractiveSelection: true,
              obscureText: !_showPassword,
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'password cannot be empty';
                }
                return null;
              },
              onChanged: (val) {
                setState(() {
                  password = val.trim();
                });
              },
            ),
          )
        ],
      ),
    );
  }

  //check if user is signed in
  Future<String?> checkSignedInUser() async {
    var result = await as.attemptAutoLogin();
    if (result.isNotEmpty) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (builder) => MainScreen(
                    userId: result,
                  )),
          (route) => false);
    }
  }

  //Sign in user
  Future<UserCredential?> signInUser(
      {required String userName, required String password}) async {
    try {
      var result = await as
          .login(userName: userName, password: password)
          .catchError((error) {
        print('the error: $error');

        setState(() {
          errorMessage = error.toString().split(']')[1];
        });
        return null;
      });
      return result;
    } catch (e) {
      print('An error occured trying to sign in user: $e');
      rethrow;
    }
  }
}
