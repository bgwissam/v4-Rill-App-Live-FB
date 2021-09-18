import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:rillliveapp/authentication/signin.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/auth.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/services/storage_data.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/image_viewer.dart';
import 'package:rillliveapp/shared/loading_animation.dart';
import 'package:rillliveapp/shared/loading_view.dart';
import 'package:rillliveapp/shared/video_viewer.dart';
import 'package:rillliveapp/wrapper.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;

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

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);
    getAllBucketData = _getAllObjects();
    getSubscriptionFeed = _getSubscriptionChannels();
    _getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return widget.userId != null
        ? SizedBox(
            height: size.height - 100,
            width: size.width,
            child: Stack(
              children: <Widget>[
                Center(
                  child: Image.asset(
                    "assets/images/g.png",
                    fit: BoxFit.cover,
                    width: size.width,
                    height: size.height,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 2 * size.height / 3,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25),
                        )),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                //Followers
                                SizedBox(
                                  child: InkWell(
                                    onTap: () async {},
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text('00', style: textStyle_3),
                                        Text('Followers', style: textStyle_2)
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundImage:
                                        AssetImage("assets/images/g.png"),
                                  ),
                                ),
                                SizedBox(
                                  child: InkWell(
                                    onTap: () async {},
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('00', style: textStyle_3),
                                        Text('Following', style: textStyle_2)
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              //User name
                              firstName != null
                                  ? Expanded(
                                      child: Text('Hey $firstName',
                                          style: textStyle_3),
                                    )
                                  : Text('')
                            ],
                          ),
                          Divider(
                            color: Colors.grey[400],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              //Follow button
                              Expanded(
                                flex: 1,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    setState(() {
                                      _buttonPressed[0] = true;
                                      _buttonPressed[1] = false;
                                      _buttonPressed[2] = false;
                                    });
                                  },
                                  child: Text(
                                    "Follow",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _buttonPressed[0]
                                          ? Colors.white
                                          : color_4,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    primary: _buttonPressed[0]
                                        ? color_4
                                        : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25.0),
                                    ),
                                  ),
                                ),
                              ),
                              //Subscribe button
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 5),
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
                                        color: _buttonPressed[1]
                                            ? Colors.white
                                            : color_4,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      primary: _buttonPressed[1]
                                          ? color_4
                                          : Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(25.0),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              //Message button
                              Expanded(
                                flex: 1,
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
                                      color: _buttonPressed[2]
                                          ? Colors.white
                                          : color_4,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    primary: _buttonPressed[2]
                                        ? color_4
                                        : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25.0),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            color: Colors.grey[400],
                          ),
                          Container(
                            padding: const EdgeInsets.only(
                                left: 10, top: 10.0, bottom: 10.0),
                            child: TabBar(
                              controller: _tabController,
                              labelColor: color_4,
                              unselectedLabelColor: color_12,
                              isScrollable: true,
                              indicator: const UnderlineTabIndicator(
                                  insets: EdgeInsets.only(
                                      left: 0, right: 0, bottom: 4)),
                              tabs: [
                                Tab(
                                  text: 'Feed (42)',
                                ),
                                Tab(
                                  text: 'Live Recordings (42)',
                                ),
                                Tab(
                                  icon: Icon(
                                    Icons.settings,
                                    color: color_10,
                                  ),
                                )
                              ],
                            ),
                          ),
                          //All feed and subscribed channels
                          SizedBox(
                            height: size.height / 2,
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
                    ),
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
    return FutureBuilder(
        future: getAllBucketData,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData && snapshot.data.isNotEmpty) {
            if (snapshot.connectionState == ConnectionState.done) {
              late String extension;
              _isLoadingStream = false;
              late ChewieController _chewieController;
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                    childAspectRatio: 0.5),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  if (snapshot.data[index]['type'] == 'image') {
                    return Container(
                      alignment: Alignment.center,
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (builder) => ImageViewer(
                                    imageUrl: snapshot.data[index]['value'])),
                          );
                        },
                        child: CachedNetworkImage(
                            imageUrl: snapshot.data[index]['value'],
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
                    _chewieController = ChewieController(
                      videoPlayerController: snapshot.data[index]['value'],
                      autoInitialize: false,
                      autoPlay: false,
                      looping: false,
                      showControls: false,
                      allowMuting: true,
                    );
                    return InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (builder) => VideoPlayerPage(
                                videoController: snapshot.data[index]['value']),
                          ),
                        );
                      },
                      child: Container(
                        alignment: Alignment.center,
                        child: snapshot.data[index]['value'].value.isInitialized
                            ? Chewie(controller: _chewieController)
                            : const Text('Not initialized'),
                      ),
                    );
                  }
                },
              );
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: LoadingView(),
              );
            } else {
              return const Center(
                child: Text('Please wait...'),
              );
            }
          } else if (snapshot.hasError) {
            print('Error getting Stream: ${snapshot.error}');
            return Center(
              child: Text(
                'Error getting Stream: ${snapshot.error}',
              ),
            );
          } else {
            return const LoadingAmination(
              animationType: 'ThreeInOut',
            );
          }
        });
  }

  //Subscribed feed section
  Widget _liveFeed() {
    return FutureBuilder(
        future: getSubscriptionFeed,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData && snapshot.data.isNotEmpty) {
            if (snapshot.connectionState == ConnectionState.done) {
              return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    late String extension;
                    _isLoadingStream = false;
                    late ChewieController _chewieController;
                    _chewieController = ChewieController(
                      videoPlayerController: snapshot.data[index]['value'],
                      autoInitialize: false,
                      autoPlay: false,
                      looping: false,
                      showControls: false,
                      allowMuting: true,
                    );
                    return InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (builder) => VideoPlayerPage(
                                videoController: snapshot.data[index]['value']),
                          ),
                        );
                      },
                      child: Container(
                        alignment: Alignment.center,
                        child: snapshot.data[index]['value'].value.isInitialized
                            ? Chewie(controller: _chewieController)
                            : const Text('Not initialized'),
                      ),
                    );
                  });
            } else {
              return const LoadingAmination(
                animationType: 'ThreeInOut',
              );
            }
          } else {
            return const SizedBox(
                child: Center(
              child: Text('You have not subscribed to any channel'),
            ));
          }
        });
  }

  //Settings widget
  Widget _settings() {
    var size = MediaQuery.of(context).size;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //Account Settings
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
            child: Text('Account Settings', style: textStyle_1),
          ),
        ),
        //Analatics
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
            child: Text('Analatics', style: textStyle_1),
          ),
        ),
        //Privacy
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
            child: Text('Privacy', style: textStyle_1),
          ),
        ),
        //Security
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
          decoration: BoxDecoration(
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
    );
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

  //Get subscribed feeds
  Future<List<dynamic>> _getSubscriptionChannels() async {
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
    //     }
    //   }
    //   return listUrls;
    // }
    return listObjects;
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
