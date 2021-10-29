import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:rillliveapp/models/file_model.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/comment_add.dart';
import 'package:rillliveapp/shared/comment_view.dart';
import 'package:rillliveapp/shared/extensions.dart';
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
      this.videoOwnerId,
      this.imageProvider})
      : super(key: key);
  final UserModel? userModel;
  final String? fileId;
  final String? collection;
  final String? playerUrl;
  final String? videoOwnerId;
  final ImageVideoModel? imageProvider;
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
        imageProvider: imageProvider,
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
      this.videoOwnerId,
      this.imageProvider})
      : super(key: key);
  final UserModel? userModel;
  final String? fileId;
  final String? videoPlayerUrl;
  final String? videoOwnerId;
  final ImageVideoModel? imageProvider;
  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  DatabaseService db = DatabaseService();
  late ScrollController _scrollController;
  late BetterPlayerController _betterPlayerController;
  List<BetterPlayerEvent> events = [];
  StreamController<DateTime> _eventStreamController =
      StreamController.broadcast();
  var commentProvider;
  var getUser;
  bool _isLiked = false;
  @override
  void initState() {
    super.initState();
    BetterPlayerConfiguration betterPlayerConfiguration =
        const BetterPlayerConfiguration(
      aspectRatio: 9 / 16,
      fit: BoxFit.contain,
    );
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network, widget.videoPlayerUrl!);
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);
    _betterPlayerController.setupDataSource(dataSource);
    _betterPlayerController.addEventsListener(_handleEvent);
    _scrollController = ScrollController();
    getUser = _detailsForImageOwner(uid: widget.videoOwnerId);
  }

  @override
  void dispose() {
    _eventStreamController.close();
    _betterPlayerController.removeEventsListener(_handleEvent);
    _scrollController.dispose();

    super.dispose();
  }

  void _handleEvent(BetterPlayerEvent event) {
    events.insert(0, event);

    ///Used to refresh only list of events
    _eventStreamController.add(DateTime.now());
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
                  padding: const EdgeInsets.all(8.0),
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: Image.network(snapshot.data.avatarUrl ??
                        'assets/images/empty_profile_photo.png'),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${snapshot.data.firstName.toString().capitalize()} ${snapshot.data.lastName.toString().capitalize()}',
                              style: heading_4,
                            ),
                            Text(
                              '${snapshot.data.address.toString().capitalize()}',
                              style: heading_4,
                            )
                          ],
                        ),
                      ),
                    ),
                    //Views
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              height: 30,
                              child: Image.asset(
                                  'assets/icons/eye_rill_icon_light.png')),
                          Text(
                            '321',
                            style: heading_4,
                          )
                        ],
                      ),
                    ),
                    //Comments
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              height: 30,
                              child: Image.asset(
                                  'assets/icons/pop_rill_icon_light.png')),
                          Text(
                            '${commentProvider.length}',
                            style: heading_4,
                          )
                        ],
                      ),
                    )
                  ],
                ),
                backgroundColor: color_9,
              ),
              body: ListView(
                controller: _scrollController,
                children: [
                  //Video player widget
                  _videoPlayerBetter(),
                  //Like, and share
                  _description(),
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

  Widget _description() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          flex: 4,
          child: Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.all(12),
            child: TextButton(
              child: Text(
                '${widget.imageProvider?.description != null ? widget.imageProvider?.description.toString().capitalize() : ''}',
                style: textStyle_15,
                textAlign: TextAlign.left,
              ),
              onPressed: () async {},
            ),
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
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _videoPlayerBetter() {
    return SizedBox(
        height: MediaQuery.of(context).size.height - 100,
        child: BetterPlayer(controller: _betterPlayerController));
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
