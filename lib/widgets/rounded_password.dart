import 'package:flutter/material.dart';
import 'text_field_container.dart';

class rounded_password_field extends StatelessWidget {
  const rounded_password_field({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFieldContainer(
        child: TextField(
      obscureText: true,
      decoration: InputDecoration(
          hintText: "Password",
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.purple, width: 5.0),
            borderRadius: BorderRadius.circular(29),
          )),
    ));
  }
}
