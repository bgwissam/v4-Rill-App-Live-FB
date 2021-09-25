import 'package:flutter/material.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/auth.dart';
import 'package:rillliveapp/shared/color_styles.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({Key? key, this.userModel}) : super(key: key);
  final UserModel? userModel;
  @override
  _SecurityPageState createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _formKey = GlobalKey<FormState>();
  //services
  AuthService as = AuthService();
  //booleans
  bool obsecureOld = true;
  bool obsecureNew = true;
  bool obsecureConfirm = true;
  //Strings
  late String? oldPassword;
  late String? newPassword;
  late String? confirmPassword;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    print('email: ${widget.userModel?.emailAddress}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Security Features'),
        backgroundColor: color_4,
        actions: [
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                var result = await as.updatePassword(
                    newPassword: newPassword,
                    currentPassword: oldPassword,
                    emailAddress: widget.userModel?.emailAddress);

                result.cancel();
                Navigator.pop(context);
              }
            },
            child: Text(
              'Save',
              style: TextStyle(color: color_9),
            ),
          )
        ],
      ),
      body: _buildPasswordChangeView(),
    );
  }

  Widget _buildPasswordChangeView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                    'The following page will allow you to change your password, please note that your password should remain a secret to you only and should not be shared with other users or it will implicate your account!',
                    style: textStyle_7),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: TextFormField(
                  initialValue: '',
                  obscureText: obsecureOld,
                  validator: (val) =>
                      val!.isEmpty ? 'current password cannot be empty' : null,
                  decoration: InputDecoration(
                    label: Text('Current Password'),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obsecureOld = !obsecureOld;
                        });
                      },
                      icon: Icon(obsecureOld
                          ? Icons.visibility
                          : Icons.visibility_off),
                    ),
                  ),
                  onChanged: (val) {
                    oldPassword = val;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: TextFormField(
                  initialValue: '',
                  obscureText: obsecureNew,
                  validator: (val) =>
                      val!.isEmpty ? 'Password cannot be empty' : null,
                  decoration: InputDecoration(
                    label: Text('New Password'),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obsecureNew = !obsecureNew;
                        });
                      },
                      icon: Icon(obsecureNew
                          ? Icons.visibility
                          : Icons.visibility_off),
                    ),
                  ),
                  onChanged: (val) {
                    newPassword = val;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: TextFormField(
                  initialValue: '',
                  obscureText: obsecureConfirm,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return 'confirm password should not be empty';
                    }
                    if (val != newPassword) {
                      return 'passwords do not match';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    label: Text(
                      'Confirm Password',
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obsecureConfirm = !obsecureConfirm;
                        });
                      },
                      icon: Icon(obsecureConfirm
                          ? Icons.visibility
                          : Icons.visibility_off),
                    ),
                  ),
                  onChanged: (val) {
                    confirmPassword = val;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
