import 'package:flutter/material.dart';

class CommentsView extends StatefulWidget {
  const CommentsView({Key? key, required this.immageComments})
      : super(key: key);
  final List<Map<String, dynamic>> immageComments;
  @override
  _CommentsViewState createState() => _CommentsViewState();
}

class _CommentsViewState extends State<CommentsView> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: widget.immageComments.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(widget.immageComments[index]['name']!),
              subtitle: Text(widget.immageComments[index]['comment']!),
            );
          }),
    );
  }
}
