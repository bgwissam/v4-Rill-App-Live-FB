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
  double? commentFieldSize;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    _getCommentFieldSize(size);
    return Container(
      decoration: widget.imageComments.isNotEmpty
          ? BoxDecoration(
              color: color_13, borderRadius: BorderRadius.circular(12))
          : BoxDecoration(),
      height: commentFieldSize! > 0.0 ? commentFieldSize : 50,
      child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemCount: widget.imageComments.length,
          itemBuilder: (context, index) {
            var timeStampComment = widget.imageComments[index]?.dateTime;
            commentTime = DateTime.parse(timeStampComment.toDate().toString());
            var difference = _calculateTimeDifference(commentTime);
            var _isLiked = false;
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color_6)),
                child: ListTile(
                  leading: widget.imageComments[index]!.avatarUrl != null
                      ? Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  fit: BoxFit.fill,
                                  image: NetworkImage(widget
                                      .imageComments[index]!.avatarUrl!))),
                        )
                      : Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  fit: BoxFit.fill,
                                  image: Image.asset(
                                          'assets/images/empty_profile_photo.png')
                                      .image)),
                        ),
                  title: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //User
                            Text(
                              widget.imageComments[index]!.fullName!
                                  .capitalize(),
                              style: heading_4,
                            ),
                            //Time
                            Text('$difference', style: textStyle_16)
                          ],
                        ),
                      ),
                      Expanded(
                        child: IconButton(
                          icon: Image.asset(_isLiked
                              ? 'assets/icons/heart_rill_icon_dark.png'
                              : 'assets/icons/heart_rill_icon_light.png'),
                          onPressed: () async {
                            setState(() {
                              _isLiked = !_isLiked;
                              print('$_isLiked');
                            });
                          },
                        ),
                      )
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
    return 'just now';
  }

  _getCommentFieldSize(var size) {
    print('size comment ${widget.imageComments.length}');
    if (widget.imageComments.length >= 3) {
      commentFieldSize = size.height - 350;
      return commentFieldSize;
    }

    if (widget.imageComments.length >= 2) {
      commentFieldSize = size.height - 450;
      return commentFieldSize;
    }

    if (widget.imageComments.isNotEmpty) {
      commentFieldSize = size.height - 550;
      return commentFieldSize;
    } else {
      commentFieldSize = 0;
      return commentFieldSize;
    }
  }
}
