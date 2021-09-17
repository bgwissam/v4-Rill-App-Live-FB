import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/comment_add.dart';
import 'package:rillliveapp/shared/comment_view.dart';

class ImageViewer extends StatefulWidget {
  const ImageViewer({Key? key, required this.imageUrl}) : super(key: key);
  final String imageUrl;
  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late var _size;
  late String _newComment;

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
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Image'),
      ),
      resizeToAvoidBottomInset: true,
      body: SizedBox(height: _size.height, child: _buildImageViewer()),
      bottomNavigationBar: CommentAdd(),
    );
  }

  Widget _buildImageViewer() {
    return SingleChildScrollView(
      physics: ScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //Displays the image
            _imageContainer(),
            //Displays the comments
            CommentsView(immageComments: imageComments)
          ],
        ),
      ),
    );
  }

  Widget _imageContainer() {
    return SizedBox(
      height: _size.height - 90,
      child: CachedNetworkImage(
          imageUrl: widget.imageUrl,
          progressIndicatorBuilder: (context, imageUrl, progress) {
            return CircularProgressIndicator(
              backgroundColor: color_12,
            );
          }),
    );
  }
}
