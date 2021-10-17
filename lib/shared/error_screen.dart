import 'package:flutter/material.dart';

class ErrorScreen extends StatefulWidget {
  const ErrorScreen({Key? key, this.error}) : super(key: key);
  final String? error;
  @override
  _ErrorScreenState createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.white, body: _buildErrorScreen());
  }

  _buildErrorScreen() {
    return Center(
      child: Text(widget.error.toString()),
    );
  }
}
