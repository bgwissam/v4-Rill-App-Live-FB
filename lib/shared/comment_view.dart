import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rillliveapp/models/file_model.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/extensions.dart';

class CommentsView extends StatefulWidget {
  const CommentsView({Key? key, required this.imageComments, this.fileId})
      : super(key: key);
  final List<CommentModel?> imageComments;
  final String? fileId;
  @override
  _CommentsViewState createState() => _CommentsViewState();
}

class _CommentsViewState extends State<CommentsView> {
  var currentTime = DateTime.now();
  var commentTime;

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.all(12),
      decoration: widget.imageComments.isNotEmpty
          ? BoxDecoration(
              color: color_13, borderRadius: BorderRadius.circular(12))
          : BoxDecoration(),
      height: size.height - 350,
      child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemCount: widget.imageComments.length,
          itemBuilder: (context, index) {
            var timeStampComment = widget.imageComments[index]?.dateTime;
            commentTime = DateTime.parse(timeStampComment.toDate().toString());
            var difference = _calculateTimeDifference(commentTime);
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color_6)),
                child: ListTile(
                  leading: widget.imageComments[index]!.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.imageComments[index]!.avatarUrl!)
                      : Image.asset('assets/images/g.png'),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //User
                      Text(
                        widget.imageComments[index]!.fullName!.capitalize(),
                        style: heading_4,
                      ),
                      //Time
                      Text('$difference', style: textStyle_16)
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(widget.imageComments[index]!.comment!,
                        style: textStyle_9),
                  ),
                ),
              ),
            );
          }),
    );
  }

  //Calculate time different
  _calculateTimeDifference(var commentTime) {
    var difference;

    //difference in days
    if (currentTime.difference(commentTime).inDays > 0) {
      difference = '${currentTime.difference(commentTime).inDays} d';
      return difference;
    }
    //difference in hours
    if (currentTime.difference(commentTime).inHours > 0) {
      difference = '${currentTime.difference(commentTime).inHours} h';
      return difference;
    }
    //difference in minutes
    if (currentTime.difference(commentTime).inMinutes > 0) {
      difference = '${currentTime.difference(commentTime).inMinutes} m';
      return difference;
    }
    //difference in secends
    if (currentTime.difference(commentTime).inSeconds > 0) {
      difference = '${currentTime.difference(commentTime).inSeconds} s';
      return difference;
    }
  }
}
