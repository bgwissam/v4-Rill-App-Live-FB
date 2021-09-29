import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rillliveapp/authentication/register.dart';
import 'package:rillliveapp/authentication/security.dart';
import 'package:rillliveapp/authentication/signin.dart';
import 'package:rillliveapp/models/file_model.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/auth.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/services/storage_data.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/followers.dart';
import 'package:rillliveapp/shared/image_viewer.dart';
import 'package:rillliveapp/shared/parameters.dart';
import 'package:rillliveapp/wrapper.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;

class AccountProvider extends StatelessWidget {
  const AccountProvider({Key? key, this.userId}) : super(key: key);
  final String? userId;
  @override
  Widget build(BuildContext context) {
    DatabaseService db = DatabaseService();
    return MultiProvider(
      providers: [
        //All user feed provider
        StreamProvider<List<ImageVideoModel?>>.value(
          value: db.getUserImageVideoList(userId: userId),
          initialData: [],
          catchError: (context, error) {
            print('Error fetching user feed: $error');
            return [];
          },
        ),
        //All user feed live recording
        StreamProvider<List<StreamingModel?>>.value(
          value: db.getUserStreamingList(userId: userId),
          initialData: [],
          catchError: (context, error) {
            print('Error fetching user streaming data: $error');
            return [];
          },
        ),
        StreamProvider<List<UserModel>>.value(
          value: db.getFollowsPerUser(
              userId: userId, collection: FollowParameters.following!),
          initialData: [],
          catchError: (context, error) {
            print('An error fetching user: $error');
            return [];
          },
        ),
        StreamProvider<List<UsersFollowing?>>.value(
          value: db.getUsersBeingFollowed(
              userId: userId, collection: FollowParameters.followers!),
          initialData: [],
          catchError: (context, error) {
            print('An error fetching user: $error');
            return [];
          },
        ),
        StreamProvider<List<UsersFollowed?>>.value(
          value: db.getUsersFollowingUser(
              userId: userId, collection: FollowParameters.following!),
          initialData: [],
          catchError: (context, error) {
            print('An error fetching user: $error');
            return [];
          },
        ),
      ],
      child: AccountScreen(
        userId: userId,
      ),
    );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key, this.userId}) : super(key: key);
  final String? userId;

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  //Services
  DatabaseService db = DatabaseService();
  AuthService as = AuthService();
  StorageData storageData = StorageData();
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserModel>(context);
    feedProvider = Provider.of<List<ImageVideoModel?>>(context);
    //followersProvider = Provider.of<List<UserModel>>(context);
    following = Provider.of<List<UsersFollowing?>>(context);
    followers = Provider.of<List<UsersFollowed?>>(context);
    Size size = MediaQuery.of(context).size;
    return widget.userId != null
        ? SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //Profile photo, followers, and name
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
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
                                child: Image.asset("assets/images/g.png")),
                          ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      height: size.width / 3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text('UserName', style: textStyle_3),
                          ),
                          // userProvider.firstName != null
                          //     ? Expanded(
                          //         child: Text('${userProvider.userName!}',
                          //             style: textStyle_3),
                          //       )
                          //     : Text('Unknown User', style: textStyle_3),
                          userProvider.firstName != null
                              ? Expanded(
                                  child: Text(
                                      '${userProvider.firstName!} ${userProvider.lastName!}',
                                      style: textStyle_8),
                                )
                              : Text('Unknown User', style: textStyle_8),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(children: [
                                  Container(
                                    width: size.width / 4,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        color: color_9),
                                    child: InkWell(
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (builder) {
                                              return Followers(
                                                followers: true,
                                                userModel: userProvider,
                                                userFollowed: [],
                                                usersFollowing: following,
                                              );
                                            },
                                          ),
                                        );
                                      },
                                      child: Text(
                                        following != null &&
                                                following.length > 0
                                            ? '${following.length}'
                                            : '00',
                                        style: textStyle_3,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    child: Text('Followers',
                                        style: textStyle_9,
                                        textAlign: TextAlign.center),
                                  )
                                ]),
                                SizedBox(
                                  width: 5,
                                ),
                                Column(children: [
                                  Container(
                                    width: size.width / 4,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        color: color_9),
                                    child: InkWell(
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (builder) {
                                              return Followers(
                                                followers: false,
                                                userModel: userProvider,
                                                userFollowed: followers,
                                                usersFollowing: [],
                                              );
                                            },
                                          ),
                                        );
                                      },
                                      child: Text(
                                        followers != null &&
                                                followers.length > 0
                                            ? '${followers.length}'
                                            : '00',
                                        style: textStyle_3,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    child: Text('Following',
                                        style: textStyle_9,
                                        textAlign: TextAlign.center),
                                  )
                                ])
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  ]),
                ),
                //bio section
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  height: size.height / 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'bio section here...',
                        style: textStyle_8,
                      ),
                      Text(
                        'Hobbies | Music | Sport',
                        style: textStyle_8,
                      ),
                      Text(
                        'A message from the user to the followers',
                        style: textStyle_8,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // //Follow button
                    // Expanded(
                    //   flex: 1,
                    //   child: ElevatedButton(
                    //     onPressed: () async {
                    //       setState(() {
                    //         _buttonPressed[0] = true;
                    //         _buttonPressed[1] = false;
                    //         _buttonPressed[2] = false;
                    //       });
                    //     },
                    //     child: Text(
                    //       "Follow",
                    //       style: TextStyle(
                    //         fontSize: 14,
                    //         color: _buttonPressed[0] ? Colors.white : color_4,
                    //       ),
                    //     ),
                    //     style: ElevatedButton.styleFrom(
                    //       primary: _buttonPressed[0] ? color_4 : Colors.white,
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(25.0),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    //Subscribe button
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              _buttonPressed[0] = false;
                              _buttonPressed[1] = true;
                              _buttonPressed[2] = false;
                            });
                            _subscribeToPlan(context);
                          },
                          child: Text(
                            "Subscribe",
                            style: TextStyle(
                              fontSize: 14,
                              color: _buttonPressed[1] ? Colors.white : color_4,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: _buttonPressed[1] ? color_4 : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    //Message button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _buttonPressed[0] = false;
                            _buttonPressed[1] = false;
                            _buttonPressed[2] = true;
                          });
                        },
                        child: Text(
                          "Message",
                          style: TextStyle(
                            fontSize: 14,
                            color: _buttonPressed[2] ? Colors.white : color_4,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          primary: _buttonPressed[2] ? color_4 : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                //feeds and live streaming
                Container(
                  padding:
                      const EdgeInsets.only(left: 10, top: 10.0, bottom: 10.0),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: color_4,
                    unselectedLabelColor: color_12,
                    isScrollable: true,
                    indicator: const UnderlineTabIndicator(
                        insets: EdgeInsets.only(left: 0, right: 0, bottom: 4)),
                    tabs: [
                      Tab(
                        text: feedProvider != null && feedProvider.length > 0
                            ? 'Feed (${feedProvider.length})'
                            : 'Feed',
                      ),
                      Tab(
                          text: streamProvider != null &&
                                  streamProvider.length > 0
                              ? 'Live Recording (${streamProvider.length})'
                              : 'Live Recording'),
                      Tab(
                        icon: Container(
                          width: size.width / 3,
                          alignment: Alignment.centerRight,
                          child: Icon(
                            Icons.settings,
                            color: color_10,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                //All feed and subscribed channels
                SizedBox(
                  height: 120,
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
                      Container(child: _settings()),
                    ],
                  ),
                ),
              ],
            ),
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
                      builder: (builder) =>
                          ImageViewer(imageUrl: feedProvider[index]!.url!)),
                );
              },
              child: CachedNetworkImage(
                  imageUrl: feedProvider[index]!.url!,
                  progressIndicatorBuilder: (context, imageUrl, progress) {
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
          return InkWell(
            onTap: () async {
              // await Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (builder) => VideoPlayerPage(
              //         videoController: feedProvider[index].url!),
              //   ),
              // );
            },
            child: Container(
              alignment: Alignment.center,
              child: feedProvider[index]!.url != null
                  ? CachedNetworkImage(
                      imageUrl: feedProvider[index]!.videoThumbnailurl!,
                      progressIndicatorBuilder: (context, imageUrl, progress) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.0),
                          child: LinearProgressIndicator(
                            minHeight: 12.0,
                          ),
                        );
                      })
                  : const Text('Not initialized'),
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
                            children: [
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
                            children: [
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
