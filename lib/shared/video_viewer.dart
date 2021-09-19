import 'package:flutter/material.dart';
import 'package:rillliveapp/shared/comment_add.dart';
import 'package:rillliveapp/shared/comment_view.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({Key? key, required this.videoController})
      : super(key: key);
  final VideoPlayerController videoController;

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late ChewieController chewieController;
  late Future _initializeController;

  List<Map<String, dynamic>> imageComments = [
    {'name': 'Paul', 'comment': 'Very beautiful'},
    {'name': 'Veronica', 'comment': 'Amazing brand'},
    {'name': 'Tom', 'comment': 'What a nice day'}
  ];
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    //widget.videoController.dispose();
    chewieController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: ScrollPhysics(),
        child: Column(
          children: [
            //Video player widget
            _videoPlayerWidget(),
            //Comements widget
            CommentsView(immageComments: imageComments)
          ],
        ),
      ),
      bottomNavigationBar: CommentAdd(),
    );
  }

  Widget _videoPlayerWidget() {
    return FutureBuilder(
        future: initializeController(),
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Center(child: Chewie(controller: snapshot.data));
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }

  Future<ChewieController> initializeController() async {
    if (widget.videoController.value.isInitialized) {
      await widget.videoController.initialize();
    }
    chewieController = ChewieController(
        videoPlayerController: widget.videoController,
        autoPlay: false,
        allowMuting: true,
        autoInitialize: false,
        aspectRatio: widget.videoController.value.aspectRatio,
        looping: false);
    return chewieController;
  }
}
