import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rillliveapp/models/file_model.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/comment_add.dart';
import 'package:rillliveapp/shared/comment_view.dart';
import 'package:rillliveapp/shared/extensions.dart';
import 'package:rillliveapp/shared/loading_animation.dart';

class ImageViewerProvider extends StatelessWidget {
  const ImageViewerProvider(
      {Key? key,
      this.userModel,
      this.fileId,
      this.collection,
      this.imageUrl,
      this.imageOwnerId})
      : super(key: key);
  final UserModel? userModel;
  final String? imageOwnerId;
  final String? fileId;
  final String? collection;
  final String? imageUrl;
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
      child: ImageViewer(
        userModel: userModel,
        fileId: fileId,
        imageUrl: imageUrl!,
        imageOwnerId: imageOwnerId,
      ),
    );
  }
}

class ImageViewer extends StatefulWidget {
  const ImageViewer(
      {Key? key,
      required this.imageUrl,
      this.userModel,
      this.fileId,
      this.imageOwnerId})
      : super(key: key);
  final String imageUrl;
  final String? imageOwnerId;
  final UserModel? userModel;
  final String? fileId;
  @override
  _ImageViewerState createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late var _size;
  late String _newComment;
  var commentProvider;
  DatabaseService db = DatabaseService();
  var getUser;
  @override
  void initState() {
    super.initState();
    getUser = _detailsForImageOwner(uid: widget.imageOwnerId);
  }

  @override
  Widget build(BuildContext context) {
    commentProvider = Provider.of<List<CommentModel?>>(context);
    _size = MediaQuery.of(context).size;
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
                    child: Image.network(
                        snapshot.data.avatarUrl ?? 'assets/images/g.png'),
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
              resizeToAvoidBottomInset: true,
              body: SizedBox(height: _size.height, child: _buildImageViewer()),
              bottomNavigationBar: CommentAdd(
                  userModel: widget.userModel,
                  fileId: widget.fileId,
                  collection: 'comments'),
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

  Widget _buildImageViewer() {
    return SingleChildScrollView(
      // physics: ScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //Displays the image
          _imageContainer(),
          //Like share widget
          _description(),
          //Displays the comments
          CommentsView(imageComments: commentProvider, fileId: widget.fileId)
        ],
      ),
    );
  }

  Widget _description() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          flex: 4,
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

  Widget _imageContainer() {
    return SizedBox(
      height: _size.height - 90,
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl,
        // progressIndicatorBuilder: (context, imageUrl, progress) {
        //   return CircularProgressIndicator(
        //     backgroundColor: color_12,
        //   );
        // },
      ),
    );
  }

  //get the details for the image owner
  Future<UserModel> _detailsForImageOwner({String? uid}) async {
    return db.getSelectedUserById(uid: uid);
  }
}
