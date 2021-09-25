import 'package:flutter/material.dart';
import 'package:rillliveapp/models/file_model.dart';
import 'package:rillliveapp/shared/color_styles.dart';

class CommentsView extends StatefulWidget {
  const CommentsView({Key? key, required this.immageComments, this.fileId})
      : super(key: key);
  final List<CommentModel?> immageComments;
  final String? fileId;
  @override
  _CommentsViewState createState() => _CommentsViewState();
}

class _CommentsViewState extends State<CommentsView> {
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SizedBox(
      height: size.height - 350,
      child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemCount: widget.immageComments.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color_6)),
                child: ListTile(
                  title: Text(widget.immageComments[index]!.fullName!),
                  subtitle: Text(widget.immageComments[index]!.comment!),
                ),
              ),
            );
          }),
    );
  }
}
