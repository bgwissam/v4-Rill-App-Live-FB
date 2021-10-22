import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rillliveapp/models/file_model.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/comment_add.dart';
import 'package:rillliveapp/shared/comment_view.dart';
import 'package:rillliveapp/shared/loading_animation.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:better_player/better_player.dart';

class VideoPlayerProvider extends StatelessWidget {
  const VideoPlayerProvider(
      {Key? key,
      this.fileId,
      this.collection,
      this.playerUrl,
      this.userModel,
      this.videoOwnerId})
      : super(key: key);
  final UserModel? userModel;
  final String? fileId;
  final String? collection;
  final String? playerUrl;
  final String? videoOwnerId;
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
        videoOwnerId: videoOwnerId,
      ),
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage(
      {Key? key,
      this.videoPlayerUrl,
      this.userModel,
      this.fileId,
      this.videoOwnerId})
      : super(key: key);
  final UserModel? userModel;
  final String? fileId;
  final String? videoPlayerUrl;
  final String? videoOwnerId;
  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late ChewieController chewieController;
  DatabaseService db = DatabaseService();
  late ScrollController _scrollController;
  late Future _initializeController;
  var commentProvider;
  var getUser;
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    getUser = _detailsForImageOwner(uid: widget.videoOwnerId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    commentProvider = Provider.of<List<CommentModel?>>(context);
    return FutureBuilder(
        future: getUser,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            return Scaffold(
              appBar: AppBar(
                leading: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: Image.network(
                        snapshot.data.avatarUrl! ?? 'assets/images/g.png'),
                  ),
                ),
                title: Text(
                    '${snapshot.data.firstName} ${snapshot.data.lastName}'),
                backgroundColor: color_4,
              ),
              body: ListView(
                controller: _scrollController,
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
              bottomNavigationBar: ScrollToHideWidget(
                controller: _scrollController,
                child: CommentAdd(
                    userModel: widget.userModel,
                    fileId: widget.fileId,
                    collection: 'comments'),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error retreiving user\'s data!: ${snapshot.error}'),
            );
          } else {
            return const Scaffold(
                body: Center(
              child: LoadingAmination(
                animationType: 'ThreeInOut',
              ),
            ));
          }
        });
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
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: BetterPlayer.network(
        widget.videoPlayerUrl!,
        betterPlayerConfiguration: const BetterPlayerConfiguration(
          autoPlay: true,
          aspectRatio: 9 / 16,
        ),
      ),
    );
  }

  //get the details for the image owner
  Future<UserModel> _detailsForImageOwner({String? uid}) async {
    return db.getSelectedUserById(uid: uid);
  }
}

class ScrollToHideWidget extends StatefulWidget {
  const ScrollToHideWidget(
      {Key? key,
      this.child,
      this.controller,
      this.duration = const Duration(milliseconds: 300)})
      : super(key: key);
  final Widget? child;
  final ScrollController? controller;
  final Duration? duration;
  @override
  _ScrollToHideWidgetState createState() => _ScrollToHideWidgetState();
}

class _ScrollToHideWidgetState extends State<ScrollToHideWidget> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(listen);
  }

  void listen() {
    final direction = widget.controller?.position.userScrollDirection;
    if (direction == ScrollDirection.forward) {
      hide();
    } else {
      show();
    }
  }

  void show() {
    setState(() {
      _isVisible = true;
    });
  }

  void hide() {
    setState(() {
      _isVisible = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller?.removeListener(listen);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: widget.duration!,
      height: _isVisible ? 90 : 0,
      child: Wrap(children: [widget.child!]),
    );
  }
}
