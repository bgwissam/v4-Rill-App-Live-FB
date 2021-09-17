import 'package:flutter/material.dart';
import 'package:rillliveapp/widgets/text_field_container.dart';

class RoundedInputField extends StatelessWidget {
  final String hintText;
  final TextInputType inputType;
  final TextInputAction inputAction;

  const RoundedInputField({
    Key? key,
    required this.hintText,
    required this.inputType,
    required this.inputAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const TextFieldContainer(
      child: TextField(
        decoration: InputDecoration(
          hintText: "Email",
          hintStyle: TextStyle(color: Color(0xffdf1266)),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xffdf1266)),
          ),
        ),
      ),
    );
  }
}
