import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FullPageFile extends StatefulWidget {
  const FullPageFile({Key? key, this.isImage, this.file}) : super(key: key);
  final bool? isImage;
  final dynamic file;
  @override
  _FullPageFileState createState() => _FullPageFileState();
}

class _FullPageFileState extends State<FullPageFile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildFilePage(),
    );
  }

  _buildFilePage() {
    return widget.isImage!
        ?
        //show image
        Image.network(widget.file.toString())
        :
        //show vieo
        BetterPlayer.network(
            widget.file,
            betterPlayerConfiguration: BetterPlayerConfiguration(
              aspectRatio: 9 / 16,
            ),
          );
  }
}
