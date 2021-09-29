import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rillliveapp/models/file_model.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/comment_add.dart';
import 'package:rillliveapp/shared/comment_view.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:better_player/better_player.dart';

class VideoPlayerProvider extends StatelessWidget {
  const VideoPlayerProvider(
      {Key? key, this.fileId, this.collection, this.playerUrl, this.userModel})
      : super(key: key);
  final UserModel? userModel;
  final String? fileId;
  final String? collection;
  final String? playerUrl;
  @override
  Widget build(BuildContext context) {
    DatabaseService db = DatabaseService();
    return StreamProvider<List<CommentModel?>>.value(
      initialData: [],
      value: db.streamCommentForFile(fileId: fileId, collection: collection),
      catchError: (context, error) {
        print('an error occured: $error');
        return [];
      },
      child: VideoPlayerPage(
        videoPlayerUrl: playerUrl,
        userModel: userModel,
        fileId: fileId,
      ),
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage(
      {Key? key, this.videoPlayerUrl, this.userModel, this.fileId})
      : super(key: key);
  final UserModel? userModel;
  final String? fileId;
  final String? videoPlayerUrl;
  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late ChewieController chewieController;
  late Future _initializeController;
  var commentProvider;

  @override
  void initState() {
    print('the user model: ${widget.userModel!.firstName}');
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    commentProvider = Provider.of<List<CommentModel?>>(context);
    return Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(3.0),
            child: FittedBox(
              fit: BoxFit.fill,
              child: Image.network(widget.userModel!.avatarUrl!),
            ),
          ),
          title: Text(
              '${widget.userModel!.firstName} ${widget.userModel!.lastName}'),
          backgroundColor: color_4,
        ),
        body: SingleChildScrollView(
          physics: ScrollPhysics(),
          child: Column(
            children: [
              //Video player widget
              _videoPlayerBetter(),
              //Like, and share
              _likeShareView(),
              //Comements widget
              CommentsView(
                  imageComments: commentProvider, fileId: widget.fileId)
            ],
          ),
        ),
        bottomNavigationBar: CommentAdd(
            userModel: widget.userModel,
            fileId: widget.fileId,
            collection: 'comments'));
  }

  Widget _likeShareView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: color_6)),
            child: TextButton(
              child: Text(
                'Like',
                style: textStyle_3,
              ),
              onPressed: () async {},
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: color_6)),
            child: TextButton(
              child: Text(
                'Share',
                style: textStyle_3,
              ),
              onPressed: () async {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _videoPlayerBetter() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: BetterPlayer.network(widget.videoPlayerUrl!),
    );
  }
}
