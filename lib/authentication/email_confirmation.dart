import 'package:flutter/material.dart';
import 'package:rillliveapp/authentication/signin.dart';
import 'package:rillliveapp/services/auth.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';

class EmailConfirmation extends StatefulWidget {
  const EmailConfirmation({Key? key}) : super(key: key);

  @override
  _EmailConfirmationState createState() => _EmailConfirmationState();
}

class _EmailConfirmationState extends State<EmailConfirmation> {
  final _formKey = GlobalKey<FormState>();
  //Services
  AuthService as = AuthService();
  DatabaseService db = DatabaseService();
  late String confirmationCode;
  late String sendingVerification;
  late String? emailAddress;
  @override
  void initState() {
    super.initState();
    as.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        backgroundColor: color_4,
      ),
      body: _buildEmailVerificationPage(),
    );
  }

  Widget _buildEmailVerificationPage() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Form(
        key: _formKey,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TextFormField(
              //   initialValue: '',
              //   keyboardType: TextInputType.number,
              //   decoration: const InputDecoration(
              //       hintText: 'Verification code', filled: false),
              //   validator: (val) {
              //     if (val == null || val.isEmpty) {
              //       return 'validation code is empty';
              //     }
              //     return null;
              //   },
              //   onChanged: (val) {
              //     setState(() {
              //       confirmationCode = val;
              //     });
              //   },
              // ),
              Container(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                    'A verification link has been sent to your email, kinldy verify your email before proceeding',
                    style: textStyle_1),
              ),
              Container(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                    'If you cannot find the email in your inbox, please check junk of spam folder',
                    style: textStyle_6),
              ),
              const SizedBox(
                height: 35,
              ),
              InkWell(
                onTap: () async {
                  await Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (builder) => const SignInSignUp()),
                      (route) => false);
                },
                child: Text('Go back to Login Page', style: textStyle_1),
              )
            ],
          ),
        ),
      ),
    );
  }
}
