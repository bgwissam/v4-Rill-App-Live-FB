import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rillliveapp/models/file_model.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/screens/account_screen.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/services/storage_data.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/image_viewer.dart';
import 'package:rillliveapp/shared/loading_animation.dart';
import 'package:rillliveapp/shared/message_service.dart';
import 'package:rillliveapp/shared/video_viewer.dart';
import 'package:video_player/video_player.dart';

class SearchScreenProviders extends StatelessWidget {
  const SearchScreenProviders({Key? key, this.userId, this.userModel})
      : super(key: key);
  final String? userId;
  final UserModel? userModel;
  @override
  Widget build(BuildContext context) {
    DatabaseService db = DatabaseService();
    return MultiProvider(
      providers: [
        StreamProvider<List<UserModel>>.value(
            value: db.userData,
            initialData: [],
            catchError: (context, error) => []),
        StreamProvider<List<UsersFollowed?>>.value(
            value: db.getUsersFollowingUser(
                userId: userId, collection: 'followers'),
            initialData: [],
            catchError: (context, error) => []),
      ],
      child: SearchScreen(userId: userId, userModel: userModel),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key, this.userId, this.userModel}) : super(key: key);
  final String? userId;
  final UserModel? userModel;
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  //Lists
  List<Map<String, dynamic>> filterItems = [
    {'category': 'Popular', 'isPressed': false},
    {'category': 'Free', 'isPressed': false},
    {'category': 'Nearby', 'isPressed': false},
    {'category': 'Fashion', 'isPressed': false}
  ];
  late List<String> followed;
  //Controllers
  FocusNode _focus = FocusNode();
  TextEditingController _searchController = TextEditingController();

  //Booleans
  late bool loadingComplete = false;
  late bool _isLoadingStream = false;
  late bool _searchSelected = false;
  late String searchWord;
  var _size;
  //Futures
  late Future getAllBucketData;

  //Controller
  StorageData storageData = StorageData();
  DatabaseService db = DatabaseService();
  MessaginService ms = MessaginService();
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;
  //Providers
  var imageVideoProvider;
  var userListProvider;
  var userProvider;
  var followedUsers;
  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
    getAllBucketData = _getAllObjects();
    _checkUsersFollowed();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _searchSelected = !_searchSelected;
    });
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    imageVideoProvider = Provider.of<List<ImageVideoModel?>>(context);
    userListProvider = Provider.of<List<UserModel>>(context);
    userProvider = Provider.of<UserModel?>(context);
    followedUsers = Provider.of<List<UsersFollowed?>>(context);
    return SizedBox(
      height: _size.height - 105,
      width: _size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //List view for the video filters
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
                height: 140, width: _size.width, child: _buildFilterListView()),
          ),
          //Grid view for search result
          _searchSelected ? _buildUsersGridView() : _buildFeedGridView(),
        ],
      ),
    );
  }

  //List view filter
  Widget _buildFilterListView() {
    return Column(
      children: [
        Container(
          height: 70,
          padding: EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filterItems.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.all(6),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      filterItems[index]['isPressed'] = true;
                      for (var i = 0; i < filterItems.length; i++) {
                        if (i != index) {
                          filterItems[i]['isPressed'] = false;
                        }
                      }
                    });
                  },
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color:
                          filterItems[index]['isPressed'] ? color_4 : color_7,
                    ),
                    child: Center(
                      child: Text(
                        '${filterItems[index]['category']}',
                        style: filterItems[index]['isPressed']
                            ? textStyle_14
                            : errorText,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          height: 70,
          padding: EdgeInsets.symmetric(vertical: 10),
          child: TextFormField(
            focusNode: _focus,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
              ),
              hintText: 'search...',
              hintStyle: textStyle_13,
            ),
            onChanged: (val) {
              setState(() {
                searchWord = val;
              });
            },
          ),
        ),
      ],
    );
  }

  //Build feed grid view
  Widget _buildFeedGridView() {
    _size = MediaQuery.of(context).size;
    return Container(
      height: _size.height - 275,
      child: RefreshIndicator(
        onRefresh: _pullRefresh,
        child: GridView.builder(
          cacheExtent: 1000,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 0.5),
          itemCount: imageVideoProvider.length,
          itemBuilder: (context, index) {
            if (imageVideoProvider[index]!.uid != null) {
              if (imageVideoProvider[index]!.type == 'image') {
                return Container(
                  alignment: Alignment.center,
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (builder) => ImageViewerProvider(
                                userModel: widget.userModel,
                                fileId: imageVideoProvider[index]!.uid,
                                imageOwnerId: imageVideoProvider[index]!.userId,
                                collection: 'comments',
                                imageUrl:
                                    imageVideoProvider[index]!.url.toString())),
                      );
                    },
                    child: CachedNetworkImage(
                        imageUrl: imageVideoProvider[index]!.url!,
                        progressIndicatorBuilder:
                            (context, imageUrl, progress) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.0),
                            child: LinearProgressIndicator(
                              minHeight: 12.0,
                            ),
                          );
                        }),
                  ),
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10.0)),
                );
              } else {
                return Container(
                  alignment: Alignment.center,
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (builder) => VideoPlayerProvider(
                            userModel: widget.userModel,
                            fileId: imageVideoProvider[index]!.uid,
                            collection: 'comments',
                            videoOwnerId: imageVideoProvider[index]!.userId,
                            playerUrl: imageVideoProvider[index]!.url,
                          ),
                        ),
                      );
                    },
                    child: Stack(children: [
                      Center(
                        child: CachedNetworkImage(
                            imageUrl:
                                imageVideoProvider[index]!.videoThumbnailurl!,
                            progressIndicatorBuilder:
                                (context, imageUrl, progress) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10.0),
                                child: LinearProgressIndicator(
                                  minHeight: 12.0,
                                ),
                              );
                            }),
                      ),
                      Center(
                        child: Icon(
                          Icons.play_arrow_sharp,
                          size: 50,
                          color: color_4,
                        ),
                      )
                    ]),
                  ),
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10.0)),
                );

                // return FutureBuilder(
                //     future: initializeVideo(
                //         imageVideoProvider[index]!.url.toString()),
                //     builder: (context, AsyncSnapshot snapshot) {
                //       if (snapshot.hasData) {
                //         return GestureDetector(
                //             onTap: () async {
                //               print('tapping tapping');
                //               await Navigator.push(
                //                 context,
                //                 MaterialPageRoute(
                //                   builder: (builder) => VideoPlayerPage(
                //                       videoController:
                //                           VideoPlayerController.network(
                //                               imageVideoProvider[index]!
                //                                   .url
                //                                   .toString())),
                //                 ),
                //               );
                //             },
                //             child: Chewie(
                //               controller: snapshot.data,
                //             ));
                //       } else if (snapshot.hasError) {
                //         print('Error playing video: ${snapshot.error}');
                //         return Center(child: Text(snapshot.error.toString()));
                //       } else {
                //         return const Center(
                //           child: CircularProgressIndicator(),
                //         );
                //       }
                //     });
              }
            }
            return const Center(
              child: LoadingAmination(
                animationType: 'ThreeInOut',
              ),
            );
          },
        ),
      ),
    );
  }

  //Pull refresh
  Future<void> _pullRefresh() async {}

  //Build Grid View
  Widget _buildUsersGridView() {
    _size = MediaQuery.of(context).size;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: SizedBox(
        width: _size.width,
        height: _size.height - 275,
        child: ListView.builder(
          itemCount: userListProvider.length,
          itemBuilder: (context, index) {
            return userListProvider[index].userId != widget.userId
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (builder) => Scaffold(
                              body: AccountProvider(
                                userId: userListProvider[index].userId,
                                myProfile: false,
                                userModel: userListProvider[index],
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 80,
                        alignment: Alignment.center,
                        child: ListTile(
                          leading: userListProvider[index].avatarUrl != null
                              ? SizedBox(
                                  height: 50,
                                  width: 75,
                                  child: FittedBox(
                                    child: Image.network(
                                        userListProvider[index].avatarUrl),
                                    fit: BoxFit.fill,
                                  ),
                                )
                              : Container(
                                  height: 50,
                                  width: 75,
                                  decoration: BoxDecoration(
                                      border: Border.all(),
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                          title: Text(
                              '${userListProvider[index].firstName} ${userListProvider[index].lastName}'),
                          subtitle: Row(
                            children: [
                              Text('User details'),
                              TextButton(
                                child: followed.isNotEmpty &&
                                        followed.contains(
                                            userListProvider[index].userId)
                                    ? Text('Followed', style: textStyle_10)
                                    : Text('Follow',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline6),
                                onPressed: () async {
                                  if (followed.isNotEmpty &&
                                      followed.contains(
                                          userListProvider[index].userId)) {
                                    await db.deleteFollowing(
                                      userId: widget.userId,
                                      followerId:
                                          userListProvider[index].userId,
                                    );
                                    setState(() {
                                      followed.remove(
                                          userListProvider[index].userId);
                                    });
                                  } else {
                                    await db.addFollowing(
                                        userId: widget.userId,
                                        followerId:
                                            userListProvider[index].userId,
                                        followerFirstName:
                                            userListProvider[index].firstName,
                                        followerLastName:
                                            userListProvider[index].lastName,
                                        avatarUrl:
                                            userListProvider[index].avatarUrl);
                                    //Notify the person being followed of the user following
                                    try {
                                      ms.token =
                                          userListProvider[index]?.fcmToken;
                                      ms.senderId = widget.userModel?.userId;
                                      ms.senderName =
                                          '${widget.userModel?.firstName} ${widget.userModel?.lastName}';
                                      ms.receiverId =
                                          userListProvider[index]?.userId;
                                      ms.messageType = 'follow';
                                      ms.messageTitle = 'New Follower';
                                      ms.messageBody = 'started following you';
                                      ms.sendPushMessage();
                                    } catch (e) {
                                      print(
                                          'an error occured try to send push message');
                                    }

                                    setState(() {
                                      followed
                                          .add(userListProvider[index].userId);
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10.0)),
                      ),
                    ),
                  )
                : SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Future<void> _checkUsersFollowed() async {
    var result = await db.checkUserFollowed(
        userId: widget.userId, collection: 'following');
    setState(() {
      followed = result;
    });
  }

  //Get all object from bucket
  Future<List<dynamic>> _getAllObjects() async {
    late String extension;
    var listObjects = [];
    List<Map<String, dynamic>> listUrls = [];
    var result = await storageData.listAllItems();

    // result.items.forEach((e) {
    //   listObjects.add(e.key);
    // });
    // if (listObjects.isNotEmpty) {
    //   for (var key in listObjects) {
    //     var file = await storageData.getFileUrl(key);

    //     extension = p.extension(key, 2);

    //     if (extension == '.mp4' || extension == '.3gp' || extension == '.mkv') {
    //       _videoPlayerController = VideoPlayerController.network(file!);
    //       await _videoPlayerController.initialize();
    //       listUrls.add({'value': _videoPlayerController, 'type': 'video'});
    //     } else {
    //       listUrls.add({'value': file, 'type': 'image'});
    //     }
    //   }
    //   return listUrls;
    // }
    return listObjects;
  }
}
