import 'package:flutter/material.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/loading_animation.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({Key? key, this.userModel}) : super(key: key);
  final UserModel? userModel;
  @override
  _HelpPageState createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final _formKey = GlobalKey<FormState>();
  var size;
  late String title;
  late String description;
  bool _isLoading = false;
  //services
  DatabaseService db = DatabaseService();
  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
          child: Stack(children: [
            _helpPageForm(),
            !_isLoading
                ? const SizedBox.shrink()
                : Positioned(
                    top: size.height / 2,
                    left: size.width / 2 - 50,
                    child: LoadingAmination(
                      animationType: 'ThreeInOut',
                    ),
                  )
          ]),
        ));
  }

  Widget _helpPageForm() {
    return Padding(
      padding: const EdgeInsets.only(top: 25, left: 10, right: 10),
      child: SizedBox(
        height: size.height,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //will build the title UI text
                Padding(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: Text('Customer Service',
                      textAlign: TextAlign.left, style: textStyle_3),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: Text(
                    'You can use the following form to report an issue to Rill customer service, issues such as policy violation, app bugs and errors. We will do our best to get back to you within 48 hours',
                    style: textStyle_21,
                  ),
                ),

                //Issue title
                Padding(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: TextFormField(
                    initialValue: '',
                    decoration: InputDecoration(
                      hintText: 'Subject Title',
                      hintStyle: textStyle_22,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: color_4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (val) {
                      if (val != null && val.isEmpty) {
                        return 'Subject is required';
                      }
                      return null;
                    },
                    onChanged: (val) {
                      title = val.trim().toString();
                    },
                  ),
                ),

                //Short description
                Padding(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: TextFormField(
                    initialValue: '',
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Describe the issue',
                      hintStyle: textStyle_22,
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: color_4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (val) {
                      if (val != null && val.isEmpty) {
                        return 'Description is required';
                      }
                      if (val!.length < 50) {
                        return 'You need to elaborate more';
                      }
                      return null;
                    },
                    onChanged: (val) {
                      title = val.trim().toString();
                    },
                  ),
                ),

                //button to submit form
                Padding(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: SizedBox(
                      width: size.width,
                      child: TextButton(
                          style: TextButton.styleFrom(backgroundColor: color_4),
                          onPressed: () async {
                            //we shall add this one later
                          },
                          child: Text(
                            'Submit',
                            style: textStyle_20,
                          ))),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
