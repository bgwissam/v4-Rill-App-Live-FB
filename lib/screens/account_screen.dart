import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rillliveapp/authentication/register.dart';
import 'package:rillliveapp/authentication/security.dart';
import 'package:rillliveapp/authentication/signin.dart';
import 'package:rillliveapp/messaging/conversation_screen.dart';
import 'package:rillliveapp/models/file_model.dart';
import 'package:rillliveapp/models/message_model.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/auth.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/services/storage_data.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/followers.dart';
import 'package:rillliveapp/shared/image_viewer.dart';
import 'package:rillliveapp/shared/parameters.dart';
import 'package:rillliveapp/shared/video_viewer.dart';
import 'package:rillliveapp/wrapper.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;

class AccountProvider extends StatelessWidget {
  const AccountProvider({Key? key, this.userId, this.myProfile, this.userModel})
      : super(key: key);
  final String? userId;
  final UserModel? userModel;
  final bool? myProfile;
  @override
  Widget build(BuildContext context) {
    DatabaseService db = DatabaseService();
    return MultiProvider(
      providers: [
        //All user feed provider
        StreamProvider<List<ImageVideoModel?>>.value(
          value: db.streamUserImageVideoList(userId: userModel?.userId),
          initialData: [],
          catchError: (context, error) {
            print('Error fetching user feed: $error');
            return [];
          },
        ),
        //All user feed live recording
        StreamProvider<List<StreamingModel?>>.value(
          value: db.getUserStreamingList(userId: userModel?.userId),
          initialData: [],
          catchError: (context, error) {
            print('Error fetching user streaming data: $error');
            return [];
          },
        ),
        StreamProvider<List<UserModel>>.value(
          value: db.streamFollowsPerUser(
              userId: userId, collection: FollowParameters.following!),
          initialData: [],
          catchError: (context, error) {
            print('An error fetching user: $error');
            return [];
          },
        ),
        StreamProvider<List<UsersFollowing?>>.value(
          value: db.getUsersBeingFollowed(
              userId: userModel?.userId,
              collection: FollowParameters.following!),
          initialData: [],
          catchError: (context, error) {
            print('An error fetching user: $error');
            return [];
          },
        ),
        StreamProvider<List<UsersFollowed?>>.value(
          value: db.getUsersFollowingUser(
              userId: userModel?.userId,
              collection: FollowParameters.followers!),
          initialData: [],
          catchError: (context, error) {
            print('An error fetching user: $error');
            return [];
          },
        ),
      ],
      child: AccountScreen(
        userId: userId,
        myProfile: myProfile,
        userModel: userModel,
      ),
    );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key, this.userId, this.myProfile, this.userModel})
      : super(key: key);
  final String? userId;
  final bool? myProfile;
  final UserModel? userModel;
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  //Services
  DatabaseService db = DatabaseService();
  AuthService as = AuthService();
  StorageData storageData = StorageData();
  ChatRoomModel chatRoomMap = ChatRoomModel();
  //Controllers
  late TabController _tabController;
  late VideoPlayerController _videoPlayerController;

  //Other variables
  late bool _isLoadingStream = false;
  late List<bool> _buttonPressed = [false, false, false];
  late Future getAllBucketData;
  late Future getSubscriptionFeed;
  //User data
  late UserModel currentUser;
  late String userId;
  late String firstName = '';
  late String lastName = '';
  late String emailAddress = '';
  late String phoneNumber;
  late String avatarUrl;
  late DateTime dob;
  //Stream provider
  var userProvider;
  var feedProvider;
  var streamProvider;
  var followersProvider;
  var followers;
  var following;

  @override
  void initState() {
    super.initState();
    print('interest: ${widget.userModel?.interest}');
    _tabController = TabController(length: 2, vsync: this);
    chatRoomMap = ChatRoomModel(userId: '', users: []);
    _getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    userProvider =
        widget.myProfile! ? Provider.of<UserModel>(context) : widget.userModel;
    feedProvider = Provider.of<List<ImageVideoModel?>>(context);
    //followersProvider = Provider.of<List<UserModel>>(context);
    following = Provider.of<List<UsersFollowing?>>(context);
    followers = Provider.of<List<UsersFollowed?>>(context);
    Size size = MediaQuery.of(context).size;

    return widget.userId != null
        ? SizedBox(
            height: size.height - 100,
            width: size.width,
            child: ListView(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(children: [
                  userProvider.avatarUrl != null
                      ? Container(
                          height: size.width / 3,
                          width: size.width / 3,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all()),
                          child: FittedBox(
                              fit: BoxFit.fill,
                              child: Image.network(userProvider.avatarUrl)),
                        )
                      : Container(
                          height: size.width / 3,
                          width: size.width / 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FittedBox(
                              fit: BoxFit.fill,
                              child: Image.asset(
                                  "assets/images/empty_profile_photo.png")),
                        ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    height: size.width / 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 1,
                          child: userProvider.userName != null
                              ? Text(
                                  userProvider.userName,
                                  style: Theme.of(context).textTheme.headline1,
                                )
                              : Text('Invalid User', style: textStyle_8),
                        ),
                        Expanded(
                          flex: 1,
                          child: userProvider.firstName != null
                              ? Text(
                                  '${userProvider.firstName!} ${userProvider.lastName!}',
                                  style: textStyle_8)
                              : Text('Unknown User', style: textStyle_8),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              //Column follower for this current user
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Column(children: [
                                  InkWell(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (builder) {
                                            return Followers(
                                              followers: true,
                                              userModel: userProvider,
                                              userFollowed: followers,
                                              usersFollowing: [],
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: size.width / 6,
                                      height: 30,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          color: color_9),
                                      child: Text(
                                        followers != null &&
                                                followers.length > 0
                                            ? '${followers.length}'
                                            : '00',
                                        style: heading_3,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: SizedBox(
                                      child: Text('Followers',
                                          style: heading_2,
                                          textAlign: TextAlign.center),
                                    ),
                                  )
                                ]),
                              ),
                              //Column for users being followed by this user
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Column(children: [
                                  InkWell(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (builder) {
                                            return Followers(
                                              followers: false,
                                              userModel: userProvider,
                                              userFollowed: [],
                                              usersFollowing: following,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: size.width / 6,
                                      height: 30,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          color: color_9),
                                      child: Text(
                                        following != null &&
                                                following.length > 0
                                            ? '${following.length}'
                                            : '00',
                                        style: heading_3,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: SizedBox(
                                      child: Text('Following',
                                          style: heading_2,
                                          textAlign: TextAlign.center),
                                    ),
                                  )
                                ]),
                              ),
                              //Column for coins sections
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Column(children: [
                                  Container(
                                    width: size.width / 6,
                                    height: 30,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        color: color_9),
                                    child: InkWell(
                                      onTap: () async {},
                                      child: Text(
                                        '100',
                                        style: heading_3,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: SizedBox(
                                      child: Text('Coins balance',
                                          style: heading_2,
                                          textAlign: TextAlign.center),
                                    ),
                                  )
                                ]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              //bio section
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: SizedBox(
                  height: size.height / 4,
                  width: size.width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.userModel?.bioDescription == null
                          ? Text('Bio section here...', style: textStyle_22)
                          : Text(
                              '${widget.userModel!.bioDescription}',
                              style: textStyle_22,
                            ),
                      widget.userModel!.interest == null
                          ? Text('Hobbies | Music | Sport', style: textStyle_22)
                          : SizedBox(
                              height: 30,
                              width: size.width - 30,
                              child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: widget.userModel!.interest!.length,
                                  itemBuilder: (context, index) {
                                    return Text(
                                        '${widget.userModel!.interest![index]} |',
                                        style: textStyle_22);
                                  }),
                            ),
                      Text(
                        '"Follow me for some amazing content"',
                        style: textStyle_22,
                      ),
                    ],
                  ),
                ),
              ),
              widget.myProfile == false
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Subscribe button
                        Container(
                          width: (size.width / 2) - 12,
                          decoration: BoxDecoration(
                              color: _buttonPressed[1] ? color_4 : Colors.white,
                              border: Border.all(
                                color: color_4,
                              ),
                              borderRadius: BorderRadius.circular(5)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: TextButton(
                              onPressed: () async {
                                setState(() {
                                  _buttonPressed[0] = false;
                                  _buttonPressed[1] = true;
                                  _buttonPressed[2] = false;
                                });
                                _subscribeToPlan(context);
                              },
                              child: Text("Subscribe",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: "Poppins",
                                    color: _buttonPressed[1]
                                        ? Colors.white
                                        : color_4,
                                  )),
                            ),
                          ),
                        ),
                        //Message button
                        Container(
                          width: (size.width / 2) - 12,
                          decoration: BoxDecoration(
                              color: _buttonPressed[2] ? color_4 : Colors.white,
                              border: Border.all(
                                color: color_4,
                              ),
                              borderRadius: BorderRadius.circular(5)),
                          child: TextButton(
                            onPressed: () async {
                              setState(() {
                                _buttonPressed[0] = false;
                                _buttonPressed[1] = false;
                                _buttonPressed[2] = true;
                              });
                              await _openMessageConversation();
                            },
                            child: Text(
                              "Message",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: "Poppins",
                                color:
                                    _buttonPressed[2] ? Colors.white : color_4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          //Edit profile
                          Container(
                            width: size.width - 25,
                            decoration: BoxDecoration(
                                border: Border.all(
                                  color: color_4,
                                ),
                                borderRadius: BorderRadius.circular(5)),
                            child: TextButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (builder) => Register(
                                      userModel: userProvider,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                "Edit Profile",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "Poppins",
                                  color: _buttonPressed[2]
                                      ? Colors.white
                                      : color_4,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                primary:
                                    _buttonPressed[2] ? color_4 : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              //feeds and live streaming
              Container(
                padding:
                    const EdgeInsets.only(left: 10, top: 10.0, bottom: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: color_4,
                        unselectedLabelColor: color_12,
                        isScrollable: true,
                        unselectedLabelStyle:
                            Theme.of(context).textTheme.headline6,
                        labelStyle: Theme.of(context).textTheme.headline6,
                        indicator: const UnderlineTabIndicator(
                            insets:
                                EdgeInsets.only(left: 0, right: 0, bottom: 4)),
                        tabs: [
                          Tab(
                            text:
                                feedProvider != null && feedProvider.length > 0
                                    ? 'Feed (${feedProvider.length})'
                                    : 'Feed',
                          ),
                          Tab(
                              text: streamProvider != null &&
                                      streamProvider.length > 0
                                  ? 'Live Recording (${streamProvider.length})'
                                  : 'Live Recording'),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: IconButton(
                          icon: Image.asset('assets/icons/settings_rill.png',
                              color: color_4),
                          onPressed: () {
                            Scaffold.of(context).openEndDrawer();
                          }),
                    ),
                  ],
                ),
              ),
              //All feed and subscribed channels
              SizedBox(
                height: size.height - 200,
                width: size.width,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    //All Feed channels list
                    Container(
                      child: _allFeeds(),
                    ),
                    //Subscribed channels
                    Container(
                      child: _liveFeed(),
                    ),
                    //settings button
                    // Container(child: _settings()),
                  ],
                ),
              ),
            ]),
          )
        : SizedBox(
            height: size.height - 100,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: color_4),
                onPressed: () async {
                  Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (builder) {
                    return SignInSignUp();
                  }), (route) => false);
                },
                child: Text('Sign In', style: button_1),
              ),
            ),
          );
  }

  Future _openMessageConversation() async {
    if (chatRoomMap.users!.isNotEmpty) {
      chatRoomMap.users!.clear();
    }

    var chatRoomId = '${widget.userId}${widget.userModel?.userId}';

    chatRoomMap.users!.add(widget.userId!);
    chatRoomMap.users!.add(widget.userModel!.userId!);
    //check if chatroom exists
    var result = await db.getChatRoom(
        chattingWith: widget.userModel!.userId!, userId: widget.userId);

    if (result.isEmpty) {
      await db.createChatRoom(
          userOneId: currentUser.userId,
          userNameOne: currentUser.userName ?? '',
          firstNameOne: currentUser.firstName,
          lastNameOne: currentUser.lastName,
          avatarUrlOne: currentUser.avatarUrl,
          userTwoId: widget.userModel!.userId,
          userNameTwo: widget.userModel!.userName ?? '',
          firstNameTwo: widget.userModel!.firstName,
          lastNameTwo: widget.userModel!.lastName,
          avatarUrlTwo: widget.userModel!.avatarUrl,
          chatRoomId: chatRoomId,
          chatRoomMap: chatRoomMap);
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (builder) => ConversationScreen(
          otherUser: widget.userModel?.userId,
          currentUser: currentUser,
          chatRoomId: result.isEmpty ? chatRoomId : result,
        ),
      ),
    );
  }

  Widget _allFeeds() {
    late String extension;
    _isLoadingStream = false;
    late ChewieController _chewieController;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          childAspectRatio: 0.5),
      itemCount: feedProvider.length,
      itemBuilder: (context, index) {
        if (feedProvider[index]?.type == 'image') {
          return Container(
            alignment: Alignment.center,
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (builder) => ImageViewerProvider(
                      userModel: userProvider,
                      imageUrl: feedProvider[index]!.url!,
                      collection: 'comments',
                      fileId: feedProvider[index]!.uid,
                      imageOwnerId: feedProvider[index]!.userId,
                      imageProvider: feedProvider[index],
                    ),
                  ),
                );
              },
              // child: CachedNetworkImage(
              //     imageUrl: feedProvider[index]!.url!,
              //     progressIndicatorBuilder: (context, imageUrl, progress) {
              //       return const Padding(
              //         padding: EdgeInsets.symmetric(horizontal: 5.0),
              //         child: LinearProgressIndicator(
              //           minHeight: 12.0,
              //         ),
              //       );
              //     }),
            ),
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: NetworkImage(feedProvider[index]!.url!),
                    fit: BoxFit.fill),
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10.0)),
          );
        } else {
          return InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (builder) => VideoPlayerProvider(
                    userModel: userProvider,
                    fileId: feedProvider[index]!.uid,
                    collection: 'comments',
                    playerUrl: feedProvider[index]!.url,
                    videoOwnerId: feedProvider[index]!.userId,
                    imageProvider: feedProvider[index],
                  ),
                ),
              );
            },
            child: Container(
              alignment: Alignment.center,
              // child: feedProvider[index]!.url != null
              //     ? CachedNetworkImage(
              //         imageUrl: feedProvider[index]!.videoThumbnailurl!,
              //         progressIndicatorBuilder: (context, imageUrl, progress) {
              //           return const Padding(
              //             padding: EdgeInsets.symmetric(horizontal: 10.0),
              //             child: LinearProgressIndicator(
              //               minHeight: 12.0,
              //             ),
              //           );
              //         })
              //     : const Text('Not initialized'),

              decoration: BoxDecoration(
                  image: DecorationImage(
                      image:
                          NetworkImage(feedProvider[index]!.videoThumbnailurl!),
                      fit: BoxFit.fill),
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10.0)),
            ),
          );
        }
      },
    );
  }

  //Subscribed feed section
  Widget _liveFeed() {
    return streamProvider != null
        ? GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1),
            itemCount: streamProvider?.length,
            itemBuilder: (context, index) {
              late String extension;
              _isLoadingStream = false;

              return InkWell(
                onTap: () async {
                  // await Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (builder) => VideoPlayerPage(
                  //         videoController: snapshot.data[index]['value']),
                  //   ),
                  // );
                },
                child: Container(
                  alignment: Alignment.center,
                  child: CachedNetworkImage(
                      imageUrl: streamProvider[index]!.videoThumbnailurl!,
                      progressIndicatorBuilder: (context, imageUrl, progress) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: LinearProgressIndicator(
                            minHeight: 12.0,
                          ),
                        );
                      }),
                ),
              );
            })
        : Center(
            child:
                Text('There are no available live streams', style: textStyle_3),
          );
  }

  //Settings widget
  Widget _settings() {
    var size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Account Settings
          Container(
            width: size.width,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 0.5),
              ),
            ),
            padding: EdgeInsets.all(12),
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (builder) => Register(
                      userModel: userProvider,
                    ),
                  ),
                );
              },
              child: Text('Account Settings', style: textStyle_1),
            ),
          ),
          //Analatics
          Container(
            width: size.width,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 0.5),
              ),
            ),
            padding: EdgeInsets.all(12),
            child: InkWell(
              onTap: () async {},
              child: Text('Analatics', style: textStyle_1),
            ),
          ),
          //Privacy
          Container(
            width: size.width,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 0.5),
              ),
            ),
            padding: EdgeInsets.all(12),
            child: InkWell(
              onTap: () async {},
              child: Text('Privacy', style: textStyle_1),
            ),
          ),
          //Security
          Container(
            width: size.width,
            decoration: const BoxDecoration(
              border: const Border(
                bottom: BorderSide(width: 0.5),
              ),
            ),
            padding: EdgeInsets.all(12),
            child: InkWell(
              onTap: () async {
                print('the user model: ${userProvider.emailAddress}');
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (builder) => SecurityPage(
                      userModel: userProvider,
                    ),
                  ),
                );
              },
              child: Text('Security', style: textStyle_1),
            ),
          ),
          //Payment
          Container(
            width: size.width,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 0.5),
              ),
            ),
            padding: EdgeInsets.all(12),
            child: InkWell(
              onTap: () async {},
              child: Text('Payment', style: textStyle_1),
            ),
          ),
          //Ads
          Container(
            width: size.width,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 0.5),
              ),
            ),
            padding: EdgeInsets.all(12),
            child: InkWell(
              onTap: () async {},
              child: Text('Ads', style: textStyle_1),
            ),
          ),

          //Sign Out
          Container(
            width: size.width,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 0.5),
              ),
            ),
            padding: EdgeInsets.all(12),
            child: InkWell(
              onTap: () async {
                await as.signOut();
                await Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (builder) => const Wrapper(),
                    ),
                    (route) => false);
              },
              child: Text('Sign Out', style: textStyle_1),
            ),
          ),
        ],
      ),
    );
  }

  //Get user details
  Future<UserModel> _getCurrentUser() async {
    currentUser = await db.getUserByUserId(userId: widget.userId);
    print('the currentUser: $currentUser');

    setState(() {
      firstName = currentUser.firstName!;
      lastName = currentUser.lastName!;
      emailAddress = currentUser.emailAddress!;
      avatarUrl = currentUser.avatarUrl!;
    });

    return currentUser;
  }

  //Subscribe dialog box
  void _subscribeToPlan(BuildContext context) {
    showDialog(
        context: context,
        builder: (builder) {
          return AlertDialog(
              backgroundColor: color_6,
              content: SizedBox(
                height: 2 * MediaQuery.of(context).size.height / 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    //Basic Plan
                    Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: color_4),
                          borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Basic Plan'),
                              Text('\$20/Annually'),
                              Text('Get Now')
                            ]),
                      ),
                    ),
                    //Premium Plan
                    Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: color_4),
                          borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Premium Plan'),
                              Text('\$50/Annually'),
                              Text('Get Now')
                            ]),
                      ),
                    ),
                    //No Plan
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: color_4),
                      child: InkWell(
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Center(
                              child: Text('Continue without plan',
                                  style: textStyle_4)),
                        ),
                        onTap: () {},
                      ),
                    )
                  ],
                ),
              ));
        });
  }
}
