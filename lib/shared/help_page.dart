import 'package:flutter/material.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/shared/color_styles.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({Key? key, this.userModel}) : super(key: key);
  final UserModel? userModel;
  @override
  _HelpPageState createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final _formKey = GlobalKey<FormState>();
  var size;
  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
          child: _helpPageForm(),
        ));
  }

  Widget _helpPageForm() {
    return Padding(
      padding: const EdgeInsets.only(top: 25, left: 10, right: 10),
      child: SizedBox(
        height: size.height,
        child: Column(
          children: [
            //will build the title UI text
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('Customer Service',
                  textAlign: TextAlign.left, style: textStyle_3),
            ),
          ],
        ),
      ),
    );
  }
}
