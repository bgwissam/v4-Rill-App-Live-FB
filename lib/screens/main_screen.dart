import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:chewie/chewie.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:rillliveapp/authentication/register.dart';
import 'package:rillliveapp/authentication/security.dart';
import 'package:rillliveapp/controller/live_streaming.dart';
import 'package:rillliveapp/controller/recording_controller.dart';
import 'package:rillliveapp/controller/token_controller_rtc.dart';
import 'package:rillliveapp/models/file_model.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/screens/account_screen.dart';
import 'package:rillliveapp/screens/camera_screen.dart';
import 'package:rillliveapp/screens/message_screen.dart';
import 'package:rillliveapp/screens/notification_screen.dart';
import 'package:rillliveapp/screens/search_screen.dart';
import 'package:rillliveapp/services/amplify_storage.dart';
import 'package:rillliveapp/services/auth.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/services/storage_data.dart';
import 'package:rillliveapp/shared/aspect_ration_video.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/image_viewer.dart';
import 'package:rillliveapp/shared/loading_animation.dart';
import 'package:rillliveapp/shared/loading_view.dart';
import 'package:rillliveapp/shared/parameters.dart';
import 'package:rillliveapp/shared/video_viewer.dart';
import 'package:rillliveapp/wallet/wallet_view.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import '../main.dart';
import '../wrapper.dart';

/*
 * Main Screen will be the first screen loaded after authentication
 * It will hold the bottom navigation bar that should allow users to navigate
 * into other screens
 */

class MainScreen extends StatefulWidget {
  const MainScreen({
    Key? key,
    this.userId,
    this.currenUser,
  }) : super(key: key);
  final String? userId;
  final UserModel? currenUser;
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  var _channelName;
  bool _isBroadCaster = false;
  var _size;
  var cameraPermission = false;
  var micPermission = false;
  var _userRole = 'subscriber';
  final _userId = '45678';
  final _userId_2 = '34343';
  late String rtcToken = '';
  late String rtmToken = '';
  late List<String> videoStreams = [];
  late List<Widget> _bodyWidget = [];
  late int _selectedIndex = 0;
  // AmplifyDataService as = AmplifyDataService();
  late Map apiToken;
  late Map acquireResponse;
  late Map startRecordingResponse;
  //Controllers
  late VideoPlayerController _videoPlayerController;
  late TabController _tabController;
  VideoPlayerController? _controller;
  VideoPlayerController? _toBeDisposed;
  //Futures
  late Future getSubscriptionFeed;
  //Define controller
  RecordingController recordingController = RecordingController();
  RtcTokenGenerator tokenGenerator = RtcTokenGenerator();
  StorageData storageData = StorageData();
  AWSstorage awsStorage = AWSstorage();
  Parameters params = Parameters();
  DatabaseService db = DatabaseService();
  AuthService as = AuthService();
  late List<ImageVideoModel?> imageVideoProvider;
  late List<EndedStreamsModel?> endedStreamModels;
  late UserModel userProvider;
  late bool _isLoadingStream = false;
  late bool _isUploadingFile = false;
  late CameraController controller;
  List<CameraDescription> cameras = [
    CameraDescription(
        name: 'front',
        lensDirection: CameraLensDirection.front,
        sensorOrientation: 1)
  ];
  //get as => null;

  //Services
  FirebaseMessaging _fcm = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin? fltNotifications;
  late String fcmToken;
  NotificationSettings? notSettings;
  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    controller = CameraController(cameras[0], ResolutionPreset.max);
    getSubscriptionFeed = _getSubscriptionChannels();
    _getCurrentUser(userId: widget.currenUser?.userId);
    _getFcmToken();
    awsStorage.list();
  }

  @override
  void dispose() {
    super.dispose();
    _disposeVideoController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    imageVideoProvider = Provider.of<List<ImageVideoModel?>>(context);
    endedStreamModels = Provider.of<List<EndedStreamsModel?>>(context);
    userProvider = Provider.of<UserModel>(context);
    _size = MediaQuery.of(context).size;
    _buildMainScreenWidget();
    return Container(
      height: _size.height,
      width: _size.width,
      decoration: const BoxDecoration(
        image: DecorationImage(
            image: AssetImage('assets/images/bg1.png'), fit: BoxFit.cover),
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.transparent,
            bottomNavigationBar: _bottomNavigationWidget(),
            endDrawer: SizedBox(
              width: 2 * _size.width / 3,
              child: Drawer(
                child: ListView(
                  children: [
                    SizedBox(
                      height: 120,
                      child: ListTile(
                        title: Text('Settings', style: heading_1),
                      ),
                    ),
                    ListTile(
                      title: Text('Account Settings',
                          style: Theme.of(context).textTheme.headline6),
                      leading: ImageIcon(
                        AssetImage('assets/icons/settings_rill.png'),
                        color: color_4,
                      ),
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
                    ),
                    ListTile(
                      title: Text('Wallet',
                          style: Theme.of(context).textTheme.headline6),
                      leading: ImageIcon(
                        AssetImage('assets/icons/money_rill_icon.png'),
                        color: color_4,
                      ),
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (builder) => WalletView()));
                      },
                    ),
                    ListTile(
                      title: Text('Analytics',
                          style: Theme.of(context).textTheme.headline6),
                      onTap: () async {},
                      leading: ImageIcon(
                        AssetImage("assets/icons/Graphs_Rill_Icon.png"),
                        color: color_4,
                      ),
                    ),
                    ListTile(
                      title: Text('Privacy',
                          style: Theme.of(context).textTheme.headline6),
                      onTap: () async {},
                      leading: ImageIcon(
                          AssetImage('assets/icons/Lock_Rill_Icon.png'),
                          color: color_4),
                    ),
                    ListTile(
                      title: Text('Security',
                          style: Theme.of(context).textTheme.headline6),
                      leading: ImageIcon(
                        AssetImage("assets/icons/Notice_Rill_Icon.png"),
                        color: color_4,
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (builder) => SecurityPage(
                              userModel: userProvider,
                            ),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      title: Text('Payment',
                          style: Theme.of(context).textTheme.headline6),
                      onTap: () async {},
                      leading: ImageIcon(
                        AssetImage("assets/icons/Square_Money_Rill.png"),
                        color: color_4,
                      ),
                    ),
                    ListTile(
                      title: Text('Ads',
                          style: Theme.of(context).textTheme.headline6),
                      onTap: () async {},
                      leading: ImageIcon(
                          AssetImage('assets/icons/Grid_Rill_Icon.png'),
                          color: color_4),
                    ),
                    ListTile(
                      title: Text('Help',
                          style: Theme.of(context).textTheme.headline6),
                      onTap: () async {},
                      leading: ImageIcon(
                          AssetImage('assets/icons/info_rill_icon.png'),
                          color: color_4),
                    ),
                    const Divider(),
                    ListTile(
                      title: Text('Sign Out',
                          style: Theme.of(context).textTheme.headline6),
                      leading: Icon(Icons.logout, color: color_4),
                      onTap: () async {
                        await as.signOut();
                        await Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (builder) => const Wrapper(
                                guestUser: false,
                              ),
                            ),
                            (route) => false);
                      },
                    ),
                  ],
                ),
              ),
            ),
            body: ListView(
              children: [
                Padding(
                    padding: const EdgeInsets.only(top: 15.0),
                    child: _bodyWidget[_selectedIndex]),
                _isLoadingStream
                    ? const SizedBox(
                        height: 100,
                        width: 100,
                        child: LoadingView(),
                      )
                    : const SizedBox.shrink(),
              ],
            )),
      ),
    );
  }

  //Get firebase messaging token and save it to the user
  _getFcmToken() async {
    await _fcm.getInitialMessage().then((message) async {
      if (message?.notification != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (builder) => NotificationScreen(
                title: message?.notification!.title,
                content: message?.notification!.body),
          ),
        );
      }
    });

    notSettings = await _fcm.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (notSettings!.authorizationStatus == AuthorizationStatus.authorized ||
        Platform.isAndroid) {
      await _fcm.getToken().then((token) {
        fcmToken = token.toString();
        return token;
      });

      //Handle the received notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        var notification = message.notification;
        var androidNotification = message.notification!.android;
        print('Notification: ${notification?.title} - ${notification?.body}');
        if (notification!.title != null) {
          flutterLocalNotificationsPlugin!.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel!.id,
                channel!.name,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
      });

      FirebaseMessaging.onBackgroundMessage((message) async {
        print('A background message exists: ${message.messageType}');
        switch (message.data['type']) {
          case 'message':
            MessagesScreen(
              userId: message.data['userId'],
              userModel: message.data['userModel'],
            );
            break;

          default:
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (builder) => NotificationScreen(
                    title: message.notification?.title,
                    content: message.notification?.body),
              ),
            );
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('message opened main_screen: ${message.data['type']}');
        switch (message.data['type']) {
          case 'message':
            MessagesScreen(
              userId: message.data['userId'],
              userModel: message.data['userModel'],
            );
            break;

          default:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (builder) => NotificationScreen(
                    title: message.notification?.title,
                    content: message.notification?.body),
              ),
            );
        }
      });
    } else {
      return showDialog(
          context: context,
          builder: (builder) => AlertDialog(
                title: Text('Notification Permission'),
                content: Text(
                    'Notification permission is needed to provide you with necessary updates'),
                actions: [
                  TextButton(
                      onPressed: () async {
                        await _getFcmToken();
                      },
                      child: Text('Grant Permission'))
                ],
              ));
    }
  }

  //Main screen widgets
  List<Widget> _buildMainScreenWidget() {
    return _bodyWidget = [
      _mainFeed(),
      SearchScreenProviders(userId: widget.userId, userModel: userProvider),
      MessagesScreen(
        userId: widget.userId,
        userModel: userProvider,
      ),
      AccountProvider(
        userId: widget.userId,
        myProfile: true,
        userModel: userProvider,
      ),
    ];
  }

  Future<String> _joiningStreamAlertDialog(BuildContext context) async {
    await showDialog(
        barrierDismissible: true,
        context: context,
        builder: (builder) {
          return AlertDialog(
              title: Text('Join as?'),
              content: Text('Choose to join as a streamer or viewer'),
              actions: [
                TextButton(
                  onPressed: () {
                    _userRole = 'publisher';
                    Navigator.pop(context, _userRole);
                  },
                  child: Text(
                    'Streamer',
                    style: textStyle_1,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _userRole = 'subscriber';
                    Navigator.pop(context, _userRole);
                  },
                  child: Text(
                    'Viewer',
                    style: textStyle_1,
                  ),
                ),
              ]);
        });
    return _userRole;
  }

  //Main feed widget
  Widget _mainFeed() {
    var streamingProvider = Provider.of<List<StreamingModel?>>(context);
    return Column(
      //causing renderFlex error, need to be fixed
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      //Column will hold top level heading text for live streaming
      //and a horizontal list view for live streaming videos
      children: [
        Container(
          padding: const EdgeInsets.only(left: 20, top: 20.0, bottom: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Latest', style: Theme.of(context).textTheme.headline6),
              Text('Live Stream', style: Theme.of(context).textTheme.headline6)
            ],
          ),
        ),
        //Horizontal list view to show latest live stream
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: streamingProvider.isNotEmpty
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: streamingProvider.length,
                  itemBuilder: (context, index) {
                    print(
                        'the stream provider: ${streamingProvider[index]!.userId}');
                    return FutureBuilder(
                        future: getStreamerDetails(
                            userId:
                                streamingProvider[index]!.userId.toString()),
                        builder: (context, AsyncSnapshot snapshot) {
                          if (snapshot.hasData) {
                            return GestureDetector(
                              onTap: () async {
                                print(
                                    'the rtm: ${streamingProvider[index]!.rtmToken.toString()}');
                                var userType =
                                    await _joiningStreamAlertDialog(context);
                                print('the user role: $userType');
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (builder) {
                                      return LiveStreaming(
                                        channelName: streamingProvider[index]!
                                            .channelName
                                            .toString(),
                                        streamUserId: streamingProvider[index]!
                                            .streamerId,
                                        userRole: userType,
                                        rtcToken: streamingProvider[index]!
                                            .rtcToken
                                            .toString(),
                                        rtmToken: streamingProvider[index]!
                                            .rtmToken
                                            .toString(),
                                        userId: widget.userId!,
                                        resourceId: streamingProvider[index]!
                                            .resourceId
                                            .toString(),
                                        uid: int.parse(streamingProvider[index]!
                                            .streamerId!),
                                        sid: streamingProvider[index]!
                                            .sid
                                            .toString(),
                                        mode: 'mix',
                                      );
                                    },
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                height: 100,
                                child: Container(
                                  width: _size.width / 2,
                                  decoration: BoxDecoration(
                                    border: Border.all(),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Stack(
                                    alignment: AlignmentDirectional.center,
                                    children: [
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: snapshot.data.avatarUrl != null
                                              ? Image.network(
                                                  snapshot.data.avatarUrl,
                                                  fit: BoxFit.fill)
                                              : Image.asset(
                                                  'assets/images/logo_type.png',
                                                  fit: BoxFit.contain),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: Align(
                                          alignment: Alignment.bottomRight,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 15, vertical: 5),
                                            child: Text(
                                                streamingProvider[index]!
                                                    .channelName
                                                    .toString(),
                                                style: textStyle_1),
                                          ),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: Align(
                                          alignment: Alignment.topLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 15, vertical: 5),
                                            child: Text('Live...',
                                                style: textStyle_12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          } else if (snapshot.hasError) {
                            print(
                                'Error establishing stream: ${snapshot.error}');
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          } else {
                            return const Center(
                                child: LoadingAmination(
                              animationType: 'ThreeInOut',
                            ));
                          }
                        });
                  })
              : Center(
                  child: Text('No Streams available', style: textStyle_12),
                ),
        ),
        //end of live streaming section view
        //Popular videos
        Container(
          padding: const EdgeInsets.only(left: 10, top: 10.0, bottom: 10.0),
          child: TabBar(
            controller: _tabController,
            labelColor: color_4,
            unselectedLabelColor: color_12,
            unselectedLabelStyle: Theme.of(context).textTheme.headline6,
            labelStyle: Theme.of(context).textTheme.headline6,
            isScrollable: true,
            indicator: const UnderlineTabIndicator(
                insets: EdgeInsets.only(left: 0, right: 0, bottom: 4)),
            tabs: const [
              Tab(
                text: 'All Feed',
              ),
              Tab(
                text: 'Subscribed Channels',
              )
            ],
          ),
        ),
        //All feed and subscribed channels
        Container(
          height: 2 * _size.height / 3,
          width: _size.width,
          child: TabBarView(
            controller: _tabController,
            children: [
              //All Feed channels list
              Container(
                child: _allFeeds(),
              ),
              //Subscribed channels
              Container(
                child: _subscribedFeed(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  //Get streamer details
  Future<UserModel> getStreamerDetails({String? userId}) async {
    var result = await db.getUserByUserId(userId: userId);

    return result;
  }

  //Get current user
  Future<UserModel> _getCurrentUser({String? userId}) async {
    var result = await db.getUserByUserId(userId: userId);
    if (result.fcmToken != null) {
      if (result.fcmToken != fcmToken) {
        await db.userModelCollection
            .doc(userId)
            .update({UserParams.FCM_TOKEN: fcmToken});
      }
    } else {
      await db.userModelCollection
          .doc(userId)
          .update({UserParams.FCM_TOKEN: fcmToken});
    }
    return result;
  }

  //Pull refresh
  Future<void> _pullRefresh() async {}

  //Bottom navigation bar
  Widget _bottomNavigationWidget() {
    return SizedBox(
      width: _size.width,
      height: 65,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(_size.width, 80),
            painter: BottomNavigatorPainter(),
          ),
          Center(
            heightFactor: 0.3,
            child: SizedBox(
              height: 150,
              width: 150,
              child: FloatingActionButton(
                onPressed: () {
                  widget.userId != null
                      ? Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (builder) =>
                                  CameraScreen(userId: widget.userId)),
                        )
                      //showBottomNavigationMenu()
                      : errorDialog('Guest Account',
                          'You need to login in order to use this feature');
                },
                backgroundColor: color_3,
                child: Image.asset('assets/icons/app_stream_button.png'),
                elevation: 0.8,
              ),
            ),
          ),
          SizedBox(
              width: _size.width,
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                    icon: Image.asset('assets/icons/Home_Light_Rill.png'),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                    icon: Image.asset('assets/icons/Search_rill_icon.png'),
                  ),
                  SizedBox(
                    width: _size.width * 0.2,
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                    icon: Image.asset('assets/icons/Messages_Rill_light.png'),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                    },
                    icon:
                        Image.asset('assets/icons/Person_Rill_Icon_light.png'),
                  ),
                ],
              ))
        ],
      ),
    );
  }

  //different style button navigation
  showCameraModeNavigation() async {
    await _getCameraMicPermission();
    return Stack(
      alignment: FractionalOffset.center,
      children: [
        Positioned.fill(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0.3,
            child: Text(
              'Live',
              style: textStyle_12,
            ),
          ),
        ),
      ],
    );
  }

  //Show the bottom menu for broadcasting
  showBottomNavigationMenu() async {
    await _getCameraMicPermission();
    cameraPermission && micPermission
        ? showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Stack(children: [
                Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Form(
                    key: _formKey,
                    child: Container(
                        height: _size.height / 4,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25.0),
                            topRight: Radius.circular(25.0),
                          ),
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 15),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  initialValue: _channelName ?? '',
                                  decoration: const InputDecoration(
                                    hintText: 'Stream Name',
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(15.0)),
                                        borderSide:
                                            BorderSide(color: Colors.grey)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(15.0)),
                                        borderSide:
                                            BorderSide(color: Colors.blue)),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'Name is required';
                                    }
                                    return null;
                                  },
                                  onChanged: (val) {
                                    _channelName = val;
                                  },
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: TextButton.icon(
                                        label: const Text('Live'),
                                        style: TextButton.styleFrom(
                                          primary: color_4,
                                        ),
                                        onPressed: _isLoadingStream
                                            ? null
                                            : () async {
                                                if (_formKey.currentState!
                                                    .validate()) {
                                                  if (_channelName != null) {
                                                    setState(() {
                                                      _isLoadingStream = true;
                                                    });
                                                    //Get token
                                                    _userRole = 'publisher';
                                                    print(
                                                        'the client Role: $_userRole');

                                                    // rtcToken = await tokenGenerator
                                                    //     .createVideoAudioChannelToken(
                                                    //         channelName:
                                                    //             _channelName,
                                                    //         role: _userRole,
                                                    //         userId: _userId);
                                                    var acquireResult =
                                                        await recordingController
                                                            .getVideoRecordingRefId(
                                                                _channelName,
                                                                _userId,
                                                                rtcToken);
                                                    acquireResponse =
                                                        await json.decode(
                                                            acquireResult.body);

                                                    //check if acquire id has returned a value
                                                    if (acquireResponse[
                                                            'resourceId'] !=
                                                        null) {
                                                      var startResult =
                                                          await recordingController
                                                              .startRecordingVideo(
                                                                  acquireResponse[
                                                                      'resourceId'],
                                                                  'mix',
                                                                  _channelName,
                                                                  _userId,
                                                                  rtcToken);
                                                      startRecordingResponse =
                                                          await json.decode(
                                                              startResult.body);
                                                    }

                                                    //check if recording could be started
                                                    if (startRecordingResponse[
                                                            'sid'] !=
                                                        null) {
                                                      //Save stream data to firebase
                                                      // var streamModel = await db
                                                      //     .createNewDataStream(
                                                      //         channelName:
                                                      //             _channelName,
                                                      //         rtcToken:
                                                      //             rtcToken,
                                                      //         userId:
                                                      //             widget.userId,
                                                      //         userName:
                                                      //             'Example',
                                                      //         resourceId:
                                                      //             acquireResponse[
                                                      //                 'resourceId'],
                                                      //         sid:
                                                      //             startRecordingResponse[
                                                      //                 'sid']);

                                                      // await Navigator.push(
                                                      //   context,
                                                      //   MaterialPageRoute(
                                                      //     builder: (context) => LiveStreaming(
                                                      //         rtcToken:
                                                      //             rtcToken,
                                                      //         rtmToken:
                                                      //             rtmToken,
                                                      //         streamUserId:
                                                      //             widget.userId,
                                                      //         channelName:
                                                      //             _channelName,
                                                      //         userRole:
                                                      //             _userRole,
                                                      //         resourceId:
                                                      //             acquireResponse[
                                                      //                 'resourceId'],
                                                      //         sid:
                                                      //             startRecordingResponse[
                                                      //                 'sid'],
                                                      //         mode: 'mix',
                                                      //         streamModelId:
                                                      //             streamModel,
                                                      //         userId: _userId,
                                                      //         loadingStateCallback:
                                                      //             callBackLoadingState),
                                                      //   ),
                                                      // );
                                                    } else {
                                                      print(
                                                          'Recording could not be started');
                                                    }
                                                  }
                                                }
                                              },
                                        icon: const Icon(Icons.stream),
                                      ),
                                    ),

                                    //Image Gallery
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: TextButton.icon(
                                        label: const Text('Image'),
                                        style: TextButton.styleFrom(
                                          primary: color_4,
                                        ),
                                        onPressed: () async {
                                          var result =
                                              await storageData.uploadImageFile(
                                                  fileType: 'imageGallery');
                                          setState(() {
                                            _previewImage(result);
                                          });
                                        },
                                        icon: const Icon(Icons.image),
                                      ),
                                    ),
                                    //Image camera
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: TextButton.icon(
                                        label: const Text('Camera'),
                                        style: TextButton.styleFrom(
                                          primary: color_4,
                                        ),
                                        onPressed: () async {
                                          var result =
                                              await storageData.uploadImageFile(
                                                  fileType: 'imageCamera');

                                          setState(() {
                                            _previewImage(result);
                                          });
                                        },
                                        icon: const Icon(Icons.camera),
                                      ),
                                    ),
                                    //Video gallery
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: TextButton.icon(
                                        label: const Text('Videos'),
                                        style: TextButton.styleFrom(
                                          primary: color_4,
                                        ),
                                        onPressed: () async {
                                          var result =
                                              await storageData.uploadImageFile(
                                                  fileType: 'videoGallery');
                                          await _playVideo(result);

                                          setState(() {
                                            _previewVideo(result);
                                          });
                                        },
                                        icon:
                                            const Icon(Icons.video_collection),
                                      ),
                                    ),
                                    //Video Camera
                                    Container(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 10),
                                      child: TextButton.icon(
                                        label: const Text('Video Cam'),
                                        style: TextButton.styleFrom(
                                          primary: color_4,
                                        ),
                                        onPressed: () async {
                                          var result =
                                              await storageData.uploadImageFile(
                                                  fileType: 'videoCamera');

                                          await _playVideo(result);

                                          setState(() {
                                            _previewVideo(result);
                                          });
                                        },
                                        icon: Icon(Icons.video_call),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  ),
                ),
              ]);
            })
        : ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('You need to enable camera and mic'),
              action: SnackBarAction(
                label: 'Grant',
                onPressed: () async {
                  await _getCameraMicPermission();
                },
              ),
            ),
          );
  }

  Widget _previewImage(XFile? file) {
    if (file != null) {
      showDialog(
          context: context,
          builder: (builder) {
            return Stack(children: [
              _isUploadingFile
                  ? const Center(
                      child: LoadingAmination(
                      animationType: 'ThreeInOut',
                    ))
                  : const SizedBox.shrink(),
              AlertDialog(
                content: Semantics(
                  child: Image.file(File(file.path)),
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      setState(() {
                        _isUploadingFile = true;
                      });
                      var result = await storageData.uploadFile(
                          xfile: file, folderName: 'images', mfile: null);
                      if (result.isNotEmpty) {
                        await db.createImageVideo(
                            name: 'example',
                            userId: widget.userId,
                            url: result['imageUrl'],
                            tags: ['cat', 'cute'],
                            type: 'image');
                      }
                      setState(() {
                        _isUploadingFile = false;
                      });
                      Navigator.pop(context);
                    },
                    child: Text('Upload', style: textStyle_3),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancel', style: textStyle_3),
                  )
                ],
              ),
            ]);
          });
      return const Center(
        child: Text('Error retreiving image'),
      );
    } else {
      return const Center(child: Text('You have not picked an Image!'));
    }
  }

  Widget _previewVideo(XFile? file) {
    if (file != null) {
      showDialog(
          context: context,
          builder: (builder) {
            return StatefulBuilder(builder: (context, setState) {
              return Stack(alignment: Alignment.topCenter, children: [
                AlertDialog(
                  content: Semantics(
                    child: AspectRatioVideo(_controller, null),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        setState(() {
                          _isUploadingFile = true;
                        });
                        //compress selected video
                        await VideoCompress.setLogLevel(0);
                        final MediaInfo? info =
                            await VideoCompress.compressVideo(
                                File(file.path).path,
                                quality: VideoQuality.LowQuality,
                                deleteOrigin: true,
                                includeAudio: true);
                        if (info != null) {
                          print('Info Path: ${info.path}');
                        }
                        //upload compressed video
                        var result = await storageData.uploadFile(
                            mfile: info, folderName: 'videos', xfile: null);
                        if (result.isNotEmpty) {
                          //save video file url
                          await db.createImageVideo(
                              name: 'example name',
                              userId: widget.userId,
                              url: result['videoUrl'],
                              tags: ['awsome', 'creative'],
                              type: 'video',
                              thumbnailUrl: result['imageUrl']);
                        }
                        setState(() {
                          _isUploadingFile = false;
                        });
                        Navigator.pop(context);
                      },
                      child: Text('Upload', style: textStyle_3),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _controller!.pause();
                        // await _controller!.dispose();
                        Navigator.pop(context);
                      },
                      child: Text('Cancel', style: textStyle_3),
                    )
                  ],
                ),
                _isUploadingFile
                    ? const Center(
                        child: LoadingAmination(
                          animationType: 'ThreeInOut',
                        ),
                      )
                    : const SizedBox.shrink()
              ]);
            });
          });
      return const Center(
        child: Text('Error retreiving Video'),
      );
    } else {
      return const Center(child: Text('No video was selected'));
    }
  }

  //Play picked video
  Future<void> _playVideo(XFile? file) async {
    if (file != null) {
      await _disposeVideoController();
      late VideoPlayerController controller;

      controller = VideoPlayerController.file(File(file.path));

      _controller = controller;
      await controller.setVolume(10);
      await controller.initialize();
      await controller.setLooping(false);
      await controller.play();
    }
  }

  Future<void> _disposeVideoController() async {
    if (_toBeDisposed != null) {
      await _toBeDisposed!.dispose();
    }
    _toBeDisposed = _controller;
    // _controller!.dispose();
    _controller = null;
  }

  //All Feed section
  Widget _allFeeds() {
    _isLoadingStream = false;

    return RefreshIndicator(
      onRefresh: _pullRefresh,
      child: GridView.builder(
        cacheExtent: 1000,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
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
                          userModel: userProvider,
                          fileId: imageVideoProvider[index]!.uid,
                          collection: 'comments',
                          imageOwnerId: imageVideoProvider[index]!.userId,
                          imageUrl: imageVideoProvider[index]!.url.toString(),
                          imageProvider: imageVideoProvider[index],
                        ),
                      ),
                    );
                  },
                  // child: CachedNetworkImage(
                  //     imageUrl: imageVideoProvider[index]!.url!,
                  //     progressIndicatorBuilder: (context, imageUrl, progress) {
                  //       return const Padding(
                  //         padding: EdgeInsets.symmetric(horizontal: 10.0),
                  //         child: LinearProgressIndicator(
                  //           minHeight: 12.0,
                  //         ),
                  //       );
                  //     }),
                ),
                decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(imageVideoProvider[index]!.url!),
                      fit: BoxFit.fill,
                    ),
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
                          userModel: userProvider,
                          fileId: imageVideoProvider[index]!.uid,
                          collection: 'comments',
                          playerUrl: imageVideoProvider[index]!.url,
                          videoOwnerId: imageVideoProvider[index]!.userId,
                          imageProvider: imageVideoProvider[index],
                        ),
                      ),
                    );
                  },
                  child: Stack(children: [
                    // Center(
                    //   child: CachedNetworkImage(
                    //       imageUrl:
                    //           imageVideoProvider[index]!.videoThumbnailurl!,
                    //       progressIndicatorBuilder:
                    //           (context, imageUrl, progress) {
                    //         return const Padding(
                    //           padding: EdgeInsets.symmetric(horizontal: 10.0),
                    //           child: LinearProgressIndicator(
                    //             minHeight: 12.0,
                    //           ),
                    //         );
                    //       }),
                    // ),
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
                    image: DecorationImage(
                        image: NetworkImage(
                          imageVideoProvider[index]!.videoThumbnailurl!,
                        ),
                        fit: BoxFit.fill),
                    borderRadius: BorderRadius.circular(10.0)),
              );
            }
          }
          return const Center(
            child: LoadingAmination(
              animationType: 'ThreeInOut',
            ),
          );
        },
      ),
    );
  }

  //Subscribed feed section
  Widget _subscribedFeed() {
    VideoPlayerController _videoPlayerController;

    return RefreshIndicator(
      onRefresh: _pullRefresh,
      child: GridView.builder(
        cacheExtent: 1000,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 0.7),
        itemCount: endedStreamModels.length,
        itemBuilder: (context, index) {
          print('stream url: ${endedStreamModels[index]!.streamUrl!}');
          if (endedStreamModels[index]!.uid != null) {
            _videoPlayerController = VideoPlayerController.network(
                endedStreamModels[index]!.streamUrl!)
              ..initialize().then((_) {
                setState(() {});
              });
            return Container(
              alignment: Alignment.center,
              child: InkWell(
                onTap: () async {
                  // await Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (builder) => ImageViewerProvider(
                  //       userModel: userProvider,
                  //       fileId: imageVideoProvider[index]!.uid,
                  //       collection: 'comments',
                  //       imageOwnerId: imageVideoProvider[index]!.userId,
                  //       imageUrl: imageVideoProvider[index]!.url.toString(),
                  //       imageProvider: imageVideoProvider[index],
                  //     ),
                  //   ),
                  // );
                },
                child: _videoPlayerController.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoPlayerController.value.aspectRatio,
                        child: VideoPlayer(_videoPlayerController),
                      )
                    : Center(
                        child: CircularProgressIndicator(),
                      ),
              ),
            );
          }
          return const Center(
            child: LoadingAmination(
              animationType: 'ThreeInOut',
            ),
          );
        },
      ),
    );
    // return FutureBuilder(
    //     future: getSubscriptionFeed,
    //     builder: (context, AsyncSnapshot snapshot) {
    //       if (snapshot.hasData && snapshot.data.isNotEmpty) {
    //         if (snapshot.connectionState == ConnectionState.done) {
    //           return GridView.builder(
    //               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    //                   crossAxisCount: 2,
    //                   mainAxisSpacing: 10,
    //                   crossAxisSpacing: 10,
    //                   childAspectRatio: 1),
    //               itemCount: snapshot.data!.length,
    //               itemBuilder: (context, index) {
    //                 late String extension;
    //                 _isLoadingStream = false;
    //                 late ChewieController _chewieController;
    //                 _chewieController = ChewieController(
    //                   videoPlayerController: snapshot.data[index]['value'],
    //                   autoInitialize: false,
    //                   autoPlay: false,
    //                   looping: false,
    //                   showControls: false,
    //                   allowMuting: true,
    //                 );
    //                 return Padding(
    //                   padding: const EdgeInsets.all(8.0),
    //                   child: InkWell(
    //                     onTap: () async {
    //                       await Navigator.push(
    //                         context,
    //                         MaterialPageRoute(
    //                           builder: (builder) => VideoPlayerPage(),
    //                         ),
    //                       );
    //                     },
    //                     child: Container(
    //                       decoration: BoxDecoration(
    //                         border: Border.all(),
    //                         borderRadius: BorderRadius.circular(15),
    //                       ),
    //                       alignment: Alignment.center,
    //                       child:
    //                           snapshot.data[index]['value'].value.isInitialized
    //                               ? Chewie(controller: _chewieController)
    //                               : const Text('Not initialized'),
    //                     ),
    //                   ),
    //                 );
    //               });
    //         } else {
    //           return const LoadingAmination(
    //             animationType: 'ThreeInOut',
    //           );
    //         }
    //       } else {
    //         return SizedBox(
    //             child: Center(
    //           child: Text('You have not subscribed to any channel',
    //               style: textStyle_12),
    //         ));
    //       }
    //     });
  }

  //Listen to streaming videos
  // Future<String> listenToStreamingVideos() async {
  //   var streamResponse = await db.subscribeToStreamingModel();
  //   print('The stream response: $streamResponse');
  //   return streamResponse;
  // }

  //Get streaming videos
  // Future<List<dynamic>> _getStreamingVideos() async {
  //   List<String> videos = [];

  //   var response = await db.fetchStreamingVideoUrl();
  //   Map result = json.decode(response);
  //   var liveStreamVideos = result['listStreamingModels'];

  //   return liveStreamVideos['items'];
  // }

  //Get all object from bucket
  Future<List<dynamic>> _getAllObjects() async {
    late String extension;
    var listObjects = [];
    List<Map<String, dynamic>> listUrls = [];
    var result = await storageData.listAllItems();

    return listObjects;
  }

  //Get subscribed feeds
  Future<List<dynamic>> _getSubscriptionChannels() async {
    late String extension;
    var listObjects = [];
    List<Map<String, dynamic>> listUrls = [];
    var result = await storageData.listAllItems();

    return listObjects;
  }

  //if camera and mic permission aren't granted than we will get them here
  _getCameraMicPermission() async {
    await [Permission.camera, Permission.microphone].request();

    var cameraStatus = await Permission.camera.status;
    var micStatus = await Permission.microphone.status;
    print('Camera: $cameraStatus - Mic $micStatus');
    if (cameraStatus == PermissionStatus.granted) {
      cameraPermission = true;
    }

    if (micStatus == PermissionStatus.granted) {
      micPermission = true;
    }

    cameraPermission = true;
    micPermission = true;
  }

  //Call back function to stop loading
  void callBackLoadingState() {
    setState(() {
      print('we are turning off loading state');
      _isLoadingStream = false;
    });
  }

  //Error dialog
  errorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (builder) => AlertDialog(
        title: Text(title, style: textStyle_3),
        content: Text(content, style: textStyle_1),
      ),
    );
  }
}

//This class will draw the bottom navigator shape
class BottomNavigatorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color_9
      ..style = PaintingStyle.fill;
    Path path = Path()..moveTo(0, 0);
    path.quadraticBezierTo(size.width * 0.20, 0, size.width * 0.35, 0);
    path.quadraticBezierTo(size.width * 0.40, 0, size.width * 0.40, 20);
    path.arcToPoint(Offset(size.width * 0.60, 20),
        radius: const Radius.circular(10.0), clockwise: false);
    path.quadraticBezierTo(size.width * 0.60, 0, size.width * 0.65, 0);
    path.quadraticBezierTo(size.width * 0.70, 0, size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawShadow(path, Colors.black, 5.0, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
