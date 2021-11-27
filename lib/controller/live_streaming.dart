import 'dart:convert';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:rillliveapp/controller/recording_controller.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/screens/main_screen.dart';
import 'package:rillliveapp/services/amplify_storage.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/services/storage_data.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/loading_animation.dart';
import 'package:rillliveapp/shared/parameters.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wakelock/wakelock.dart';
import 'package:path/path.dart' as Path;

class LiveStreaming extends StatefulWidget {
  final String rtcToken;
  final String rtmToken;
  final int? uid;
  final String channelName;
  final String userId;
  final String userRole;
  final String? resourceId;
  final String? streamUserId;
  final String? sid;
  final String? mode;
  final String? streamModelId;
  final Function? loadingStateCallback;
  final String? recordingId;
  final UserModel? currentUser;
  final bool? allowJoining;
  const LiveStreaming({
    required this.channelName,
    required this.userRole,
    required this.rtcToken,
    required this.rtmToken,
    this.sid,
    this.mode,
    required this.userId,
    this.resourceId,
    this.streamUserId,
    this.loadingStateCallback,
    this.streamModelId,
    Key? key,
    this.uid,
    this.recordingId,
    this.currentUser,
    this.allowJoining,
  }) : super(key: key);

  @override
  _LiveStreamingState createState() => _LiveStreamingState();
}

class _LiveStreamingState extends State<LiveStreaming> {
  final _users = <int>[];
  final _infoString = <String>[];
  late List<Widget> _messageList;
  Map<String, UserModel> _userList = {};
  List<String> _members = [];
  UserModel _userData = UserModel();
  //Agora Live and Video streaming
  late RtcEngine _engine;

  //Agora Messaging
  late AgoraRtmClient _client;
  late AgoraRtmChannel? _channel;
  var userMap;

  //bool values
  bool _isLogin = false;
  bool _joined = false;
  bool _switch = false;
  bool _muted = false;
  bool anyPerson = false;
  bool tryingToEnd = false;
  bool _isInChannel = false;
  bool personBool = false;
  bool accepted = false;
  bool _isLoading = false;
  int userNo = 0;
  int _remoteId = 0;
  double _chatItemHeight = 60;
  var size;
  late String userRole;
  Parameters param = Parameters();
  //Controllers
  DatabaseService db = DatabaseService();
  RecordingController recordingController = RecordingController();
  late TextEditingController _channelMessageController;
  late FirebaseStorage storageRef;
  AWSstorage awsStorage = AWSstorage();
  final _scrollController = ScrollController();
  late RtcEngineContext rtcContext;

  //Live messaging controllers
  final _userNameController = TextEditingController();
  final _peerUserIdController = TextEditingController();
  final _peerMessageController = TextEditingController();
  final _invitationController = TextEditingController();
  final _channelNameController = TextEditingController();

  //To dispose the agora engin and clear the user list
  @override
  void dispose() {
    Wakelock.disable();
    _users.clear();
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
  }

  //Initialize the states of the class
  @override
  void initState() {
    super.initState();
    userRole = widget.userRole;
    // To keep the screen on:
    Wakelock.enable();
    _messageList = [];

    _channelMessageController = TextEditingController();
    initializeAgore();
    _createClient();
  }

  //The scroll to index will allow the listview to scroll to the last index
  void _scrollToIndex(lastIndex) {
    _scrollController.animateTo(_chatItemHeight * lastIndex,
        duration: const Duration(milliseconds: 600), curve: Curves.easeIn);
  }

  //Will initialize the Rtc Engine
  Future<void> _initializeRtcEngine(String userRole) async {
    if (param.app_ID.isNotEmpty) {
      rtcContext = RtcEngineContext(param.app_ID);
      _engine = await RtcEngine.createWithContext(rtcContext)
          .catchError((err, stackTrace) async {
        await Sentry.captureException(err, stackTrace: stackTrace);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text('Error created RTC engine context: $err'),
          ),
        );
      });

      //set event handlers
      _engine.setEventHandler(
        RtcEngineEventHandler(
          warning: (warningCode) {
            print('the warning codes: $warningCode');
            setState(() {
              final info = 'Warning error: $warningCode';
              _infoString.add(info);
            });
          },
          error: (errorCode) {
            if (errorCode.index > 0) {
              print('Error happending when setting event handlers: $errorCode');
              //will show if an error showed up
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 2),
                  content: Text('${errorCode.index} - $errorCode'),
                ),
              );
              return;
            }
          },
          joinChannelSuccess: (channel, uid, elapsed) async {
            await recordingController
                .queryRecoding(
                    resourceId: widget.resourceId,
                    sid: widget.sid,
                    mode: widget.mode)
                .catchError((error) {
              print('Error joining channel: $error');
            });
            setState(
              () {
                _joined = true;
                final info = 'channel: $channel, uid: $uid';
                _infoString.add(info);
              },
            );
          }, //Leave Channel
          leaveChannel: (stats) {
            setState(
              () {
                final info = 'Left Channel: $stats';
                _infoString.add(info);
                //_leaveChannel();
                _users.clear();
              },
            );
          }, //Join Channel
          userJoined: (uid, elapsed) {
            setState(
              () {
                _remoteId = uid;
                final info = 'Joined Channel: $uid';
                _infoString.add(info);
                _users.add(uid);
              },
            );
          }, //userJoined
          userOffline: (uid, elapsed) {
            setState(
              () {
                _remoteId = 0;
                final info = 'User Offline: $uid - $elapsed';
                _users.remove(uid);
              },
            );
            print('removed users: $_users');
          },
          firstRemoteVideoFrame: (uid, width, height, elapsed) {
            setState(() {
              final info = 'First Remote video: $uid, ${width}x$height';
              _infoString.add(info);
            });
          },
        ),
      );

      await _engine.enableVideo().catchError((err) async {
        print('Error enableing video: $err');
        await Sentry.captureException('Enabling video failed: $err');
      });

      await _engine.setEnableSpeakerphone(true).catchError((err) {
        print('Error setting phone speaker: $err');
      }).then((value) {
        print('Speaker phone has been enabled');
      });

      await _engine.enableLocalAudio(true).catchError((err) async {
        print('Error enabling audio: $err');
        await Sentry.captureException('Enabling audio failed: $err');
      }).then((value) {
        print('Local audio has been enabled');
      });

      await _engine
          .setChannelProfile(ChannelProfile.LiveBroadcasting)
          .catchError((err) async {
        print('Error setting the channel Profile: $err');
        await Sentry.captureException(
            'Error setting the channel Profile: $err');
      });
      if (userRole == 'publisher') {
        await _engine.setClientRole(ClientRole.Broadcaster);
      } else {
        await _engine.setClientRole(ClientRole.Audience);
      }
    } else {
      _infoString.add('App Id is empty');
      return;
    }
  }

  //Will initialize the agora channel, token and app id
  Future<void> initializeAgore() async {
    if (widget.rtcToken.isNotEmpty) {
      try {
        await _initializeRtcEngine(userRole);

        //Join the channel
        await _engine
            .joinChannel(widget.rtcToken, widget.channelName, null, widget.uid!)
            .catchError((err) async {
          await Sentry.captureException(err);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to joinChannel: $err'),
            ),
          );
        });
      } catch (e, stackTrace) {
        await Sentry.captureException(e, stackTrace: stackTrace);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize Rtc Engine: $e'),
          ),
        );
      }
    } else {
      await Sentry.captureException('RTC token is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('RTC token is empty'),
        ),
      );
    }
  }

  Future<void> _showMyStreamMessageDialog(
      int uid, int streamId, String data) async {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Received from $uid'),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text('Stream Id: $streamId: $data'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Ok'),
              ),
            ],
          );
        });
  }

  Future<List<Widget>> _futureRenderViews() async {
    return _getRenderViews();
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        if (widget.userId == widget.streamUserId) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You need to end call first'),
              duration: Duration(milliseconds: 900),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            FutureBuilder(
              future: _futureRenderViews(),
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  return Stack(
                    children: [
                      //Show the video view
                      userRole == 'publisher'
                          ? _broadCastView()
                          : _audienceView(),
                      //show messaging bar
                      userRole == 'publisher'
                          ? const SizedBox.shrink()
                          : SizedBox(
                              width: size.width,
                              child: _bottomBar(),
                            ),
                      //will list the messages for this stream
                      messageList(),
                    ],
                  );
                } else {
                  return const Center(
                    child: LoadingAmination(
                      animationType: 'ThreeInOut',
                    ),
                  );
                }
              },
            ),
            userRole == 'publisher' ? _streamerToolBar() : _bottomBar(),
            _isLoading
                ? const Center(
                    child: LoadingAmination(
                      animationType: 'ThreeInOut',
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  //this function will help the list of native views
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    //the broadcaster will access the local views
    if (userRole == 'publisher') {
      print('user adding local view');
      list.add(RtcLocalView.SurfaceView());
    }
    //other broadCasters will access the remote view
    for (var uid in _users) {
      print('user adding remote view');
      list.add(
        RtcRemoteView.SurfaceView(uid: uid),
      );
    }
    print('the list of users: $list');
    return list;
  }

  Widget _broadCastView() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return Column(
          children: [
            _expandedViewWidget([views[0]])
          ],
        );
      case 2:
        return Column(
          children: [
            _expandedViewWidget([views[0]]),
            _expandedViewWidget([views[1]]),
          ],
        );
      case 3:
        return Column(
          children: [
            _expandedViewWidget(views.sublist(0, 2)),
            _expandedViewWidget(views.sublist(2, 3))
          ],
        );
      case 4:
        return Column(
          children: [
            _expandedViewWidget(views.sublist(0, 2)),
            _expandedViewWidget(views.sublist(2, 4))
          ],
        );
      default:
        return Container(
          child: _exceededBroadCasters(),
        );
    }
  }

  //exceed broadcaster maximum allowed users
  _exceededBroadCasters() {
    showDialog(
        context: context,
        builder: (builder) {
          return const AlertDialog(
            title: Text('Warning'),
            content:
                Text('The channel has reached the maximum number of users'),
          );
        });
  }

  //Create view for audience
  Widget _audienceView() {
    final views = _getRenderViews();

    if (views.isNotEmpty) {
      switch (views.length) {
        case 1:
          return Column(
            children: [
              _expandedViewWidget([views[0]])
            ],
          );
        case 2:
          return Column(
            children: [
              _expandedViewWidget([views[0]]),
              _expandedViewWidget([views[1]]),
            ],
          );
        case 3:
          return Column(
            children: [
              _expandedViewWidget(views.sublist(0, 2)),
              _expandedViewWidget(views.sublist(2, 3))
            ],
          );
        case 4:
          return Column(
            children: [
              _expandedViewWidget(views.sublist(0, 2)),
              _expandedViewWidget(views.sublist(2, 4))
            ],
          );
        default:
          return Container(
            child: _exceededBroadCasters(),
          );
      }
    }
    return const Center(
      child: LoadingAmination(
        animationType: 'ThreeInOut',
      ),
    );
  }

  //Video view widget
  Widget _expandedViewWidget(List<Widget> views) {
    final wrappedViews = views
        .map<Widget>((view) => Expanded(
              child: view,
            ))
        .toList();
    return Expanded(
      child: Row(children: wrappedViews),
    );
  }

  //Info panel to show logs
  Widget messageList() {
    return Container(
      padding: const EdgeInsets.only(bottom: 120),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
          heightFactor: 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  itemCount: _messageList.length,
                  itemBuilder: (context, index) {
                    //_messageList.reversed;
                    if (_messageList.isEmpty) {
                      return Text('Empty messages');
                    }
                    return SizedBox(
                      width: size.width - 10,
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 3, horizontal: 10),
                            child: _messageList[index]),
                      ),
                    );
                  }),
            ),
          )),
    );
  }

  Widget _streamerToolBar() {
    return Stack(children: [
      Positioned(
        left: size.width / 12,
        top: size.height / 14,
        child: Container(
          alignment: Alignment.center,
          height: 30,
          width: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: color_5,
          ),
          child: Text('Live', style: textStyle_15),
        ),
      ),
      Positioned(
        left: size.width / 3,
        top: size.height / 14,
        child: Container(
          height: 30,
          width: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: color_11,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 30,
                height: 30,
                child: Image.asset('assets/icons/eye_rill_icon_light.png',
                    color: color_13),
              ),
              Text(
                '${_members.length}',
                style: textStyle_20,
              ),
            ],
          ),
        ),
      ),
      Positioned(
        left: 0,
        bottom: size.height / 20,
        height: 50,
        width: size.width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  margin: EdgeInsets.only(left: 6, right: 6, bottom: 5),
                  width: size.width / 2,
                  height: 40,
                  child: TextField(
                    cursorColor: Colors.blue,
                    textInputAction: TextInputAction.send,
                    style: textStyle_22,
                    controller: _channelMessageController,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (val) async {
                      await _toggleSendChannelMessage();
                      setState(() {
                        _channelMessageController.clear();
                      });
                    },
                    decoration: InputDecoration(
                        hintText: 'Say something..',
                        hintStyle: textStyle_20,
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: color_13)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: color_13))),
                  ),
                ),
                Container(
                  height: 45,
                  margin: EdgeInsets.only(right: 5, bottom: 5),
                  decoration: BoxDecoration(
                      border: Border.all(color: color_5),
                      borderRadius: BorderRadius.circular(15)),
                  child: TextButton(
                      child: Text('End Recording', style: textStyle_25),
                      onPressed: () async =>
                          !_isLoading ? _onCallEnd(context) : null),
                ),
              ],
            ),
          ],
        ),
      ),
      Positioned(
        right: 0,
        bottom: size.height / 20,
        child: SizedBox(
          height: 100,
          width: 40,
          child: Column(
            children: [
              RawMaterialButton(
                  onPressed: _onToggleMute,
                  child: Icon(
                    _muted ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                    size: 20.0,
                  ),
                  elevation: 2.0,
                  padding: const EdgeInsets.all(12.0)),
              RawMaterialButton(
                onPressed: () => _onSwitchCamera(context),
                child: const Icon(Icons.switch_camera,
                    color: Colors.white, size: 20.0),
                elevation: 2.0,
                padding: const EdgeInsets.all(12.0),
              ),
            ],
          ),
        ),
      )
    ]);
  }

  Widget _requestJoin() {
    return Container(
      height: 45,
      margin: EdgeInsets.only(right: 5, bottom: 5),
      decoration: BoxDecoration(
          border: Border.all(color: widget.allowJoining! ? color_4 : color_11),
          borderRadius: BorderRadius.circular(15)),
      child: TextButton(
        child: Text('Request to Join',
            style: widget.allowJoining! ? textStyle_19 : textStyle_24),
        onPressed: widget.allowJoining!
            ? () async {
                var views = _getRenderViews();
                if (views.length < 4) {
                  _toggleSendRemoteInivitaion();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      duration: Duration(seconds: 2),
                      content: Text(
                          'The channel has reached maximum number of hosts'),
                    ),
                  );
                }
              }
            : null,
      ),
    );
  }

  //tool bar functions
  void _onCallEnd(BuildContext context) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    print('Loading: $_isLoading');
    String streamingId = '';
    print('fetchStreamVideoUrl counter: ${DateTime.now().second}');
    //send a message to kick out all users
    await _channel
        ?.sendMessage(AgoraRtmMessage.fromText('callEnded'))
        .catchError((err) async {
      print('Could not send the end stream text');
      await Sentry.captureException(err);
    });

    if (widget.streamModelId != null && widget.streamUserId == widget.userId) {
      streamingId = await db.fetchStreamingVideoUrl(uid: widget.streamModelId);

      //Stop the recording and save the stream to the bucket
      var stopRecordingResult = await recordingController.stopRecordingVideos(
        channelName: widget.channelName,
        userId: widget.recordingId!,
        sid: widget.sid,
        resouceId: widget.resourceId,
        mode: widget.mode,
      );
      await db.deleteStreamingVideo(streamId: widget.streamModelId);
      var stopRecordResponse = await json.decode(stopRecordingResult.body);
      print('the stop response: $stopRecordResponse');
      //save the live stream to firebase
      await _saveLiveStream(stopRecordResponse);
    } else {
      print('Ended the video, the streamer is not the video creator');
      // await Sentry.captureException('streamModelId is null');
      Navigator.pop(context);
    }
  }

  Future<void> _saveLiveStream(var data) async {
    String thumbnailUrl = '';
    var streamFile;
    var streamKey;

    if (data['serverResponse'] != null &&
        data['serverResponse']['uploadingStatus'] == 'uploaded') {
      streamKey = data['serverResponse']['fileList'];

      //Get the url for the live streaming
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child(streamKey);

      String url = (await ref.getDownloadURL()).toString();

      print('this is the url: $url');
      if (url.isNotEmpty) {
        var result = await db.saveEndedLiveStream(
            userId: widget.userId,
            thumbnailUrl: thumbnailUrl,
            streamUrl: url,
            description: 'We will create that later');

        if (result.isNotEmpty) {
          print('The video stream was uploaded properly');
        } else {
          print(
              'An error occured uploading stream, check with customer support');
        }
      }

      //generate streaming thumbnail
      // StorageData sd = StorageData();
      if (streamKey != null) {
        // var key = await sd.generateThumbnailUrl(streamFile);
        // print('data streaming: $key');
        // //create streaming thumbnail
        // if (key != null) {
        //   storageRef = FirebaseStorage.instance;
        //   Reference ref =
        //       storageRef.ref().child('thumbnails/${Path.basename(key.path)}');

        //   UploadTask uploadTask = ref.putFile(File(key.path));
        //   var downloadUrlThumbnail =
        //       await (await uploadTask).ref.getDownloadURL();
        //   thumbnailUrl = downloadUrlThumbnail.toString();
        //   print('data streaming thumbnail: $thumbnailUrl');
        // }

      } else {
        print('stream file is null');
      }
    } else {
      await Sentry.captureException('Error obtaining server response aws');
    }
    Navigator.pop(context);
    Navigator.pop(context);
  }

  void _onToggleMute() {
    if (mounted) {
      setState(() {
        _muted = !_muted;
      });
    }

    // _engine.muteAllRemoteAudioStreams(_muted);
    _engine.muteLocalAudioStream(_muted);
  }

  void _onSwitchCamera(BuildContext context) {
    // if (streamId != null) {
    //   _engine?.sendStreamMessage(streamId, 'mute user blet');
    // }
    _engine.switchCamera();
  }

  /*
   * This section will handle sending and showing message in a live stream using Agora_RTM service
   * createClient & _createChannel will monitor the status of signed in users and messages sent
   * the function below are to send and read message
   */

  Widget _bottomBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
        child: SizedBox(
          height: 90,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                children: [
                  //The row represents the icons and views
                  SizedBox(
                    width: size.width / 2 + 40,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 40,
                            child: IconButton(
                              icon: Image.asset(
                                'assets/icons/heart_rill_icon_light.png',
                                color: color_13,
                              ),
                              onPressed: () async {},
                            ),
                          ),
                          SizedBox(
                            height: 40,
                            child: IconButton(
                              icon: Image.asset(
                                'assets/icons/pop_rill_icon_light.png',
                                color: color_13,
                              ),
                              onPressed: () async {},
                            ),
                          ),
                          SizedBox(
                            height: 40,
                            child: IconButton(
                              icon: Image.asset(
                                'assets/icons/sticker_rill_icon.png',
                                color: color_13,
                              ),
                              onPressed: () async {},
                            ),
                          ),
                        ]),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 6, right: 6, bottom: 5),
                    width: size.width / 2 + 40,
                    height: 40,
                    child: TextField(
                      cursorColor: Colors.blue,
                      textInputAction: TextInputAction.send,
                      style: textStyle_22,
                      controller: _channelMessageController,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (val) async {
                        await _toggleSendChannelMessage();
                        setState(() {
                          _channelMessageController.clear();
                        });
                      },
                      decoration: InputDecoration(
                          hintText: 'Say something..',
                          hintStyle: textStyle_20,
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: color_13)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: color_13))),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: size.width / 2 - 55,
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: 25,
                            height: 40,
                            child: Image.asset(
                                'assets/icons/eye_rill_icon_light.png',
                                color: color_13)),
                        Text(
                          '${_members.length}',
                          style: textStyle_20,
                        ),
                        SizedBox(
                            width: 25,
                            height: 40,
                            child: Image.asset(
                                'assets/icons/pop_rill_icon_light.png',
                                color: color_13)),
                        Text(
                          '${_messageList.length}',
                          style: textStyle_20,
                        )
                      ],
                    ),
                  ),
                  _requestJoin(),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _createClient() async {
    _client = await AgoraRtmClient.createInstance(param.app_ID);

    _client.onConnectionStateChanged = (int state, int reason) {
      _log(
          type: 'state',
          info: 'State: $state, $reason',
          fullName:
              '${widget.currentUser?.firstName} - ${widget.currentUser?.lastName}');
      if (state == 5) {
        _client.logout();
        if (mounted) {
          setState(() {
            _isLogin = false;
          });
        }
      }
    };

    _client.onMessageReceived = (AgoraRtmMessage message, String peerId) async {
      if (message.text.isNotEmpty && _userList[peerId] != null) {
        setState(() {
          showDialog(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                    title: Text('Joining Live'),
                    content: Text(
                        '${_userList[peerId]!.firstName} ${_userList[peerId]!.lastName} ${message.text}'),
                    actions: [
                      TextButton(
                          onPressed: () {
                            _toggleSendLocalInvitation(peerId, 'accept');
                            Navigator.pop(context);
                          },
                          child: Text('Accept')),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Reject')),
                    ],
                  ));
        });
      }
    };

    _client.onLocalInvitationReceivedByPeer = (AgoraRtmLocalInvitation invite) {
      //At the moment we have nothing to do with local invitations
    };

    _client.onRemoteInvitationReceivedByPeer =
        (AgoraRtmRemoteInvitation invite) async {
      if (invite.content == 'accept') {
        if (mounted) {
          setState(() {
            userRole = 'publisher';
            _initializeRtcEngine(userRole);
          });
        }
      } else {
        showDialog(
            context: context,
            builder: (builder) => const AlertDialog(
                  content: Text('You request was rejected'),
                ));
      }
    };

    await _toggleLogin();
    await _toggleJoinChannel();
  }

  Future<AgoraRtmChannel?> _createChannel(String name) async {
    AgoraRtmChannel? channel = await _client.createChannel(name);
    if (channel != null) {
      channel.onMemberJoined = (AgoraRtmMember member) async {
        print('A member joined: ${member.userId}');
        _toggleQuery();
        if (!_userList.containsKey(member.userId)) {
          _userData = await db.getUserByUserId(userId: member.userId);
          if (mounted) {
            setState(() {
              _members.add(member.userId);
              _userList = {
                member.userId: _userData,
              };
              _log(
                  type: 'joined',
                  user: member.userId,
                  info: 'Joined',
                  fullName: _userList[member.userId]!.firstName);
            });
          }
        }
      };
      channel.onMemberLeft = (AgoraRtmMember member) async {
        print('a member left: ${member.userId}');
        _toggleQuery();
        if (_userList.containsKey(member.userId) &&
            _members.contains(member.userId)) {
          if (mounted) {
            setState(() {
              _members.remove(member.userId);
              _userList.remove(member.userId);
              _log(
                  type: 'joined',
                  info: 'Left',
                  user: member.userId,
                  fullName: _userList[member.userId]!.firstName);
            });
          }
        }
      };
      channel.onMessageReceived =
          (AgoraRtmMessage message, AgoraRtmMember member) async {
        if (mounted) {
          setState(() {
            _log(
                type: 'message',
                user: member.userId,
                info: message.text,
                fullName: _userList[member.userId]!.firstName);
          });
        }
        print(
            'End call: member: ${member.userId} - Streamer: ${widget.streamUserId}');
        //kick out users if call ended
        if (member.userId == widget.streamUserId &&
            message.text == 'callEnded') {
          print('time to kick you out');
          await Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (builder) => MainScreen(
                      currenUser: widget.currentUser, userId: widget.userId)),
              (route) => false);
        }
      };
    }
    return channel;
  }

  Future<void> _toggleLogin() async {
    print('client is logging in: $_isLogin');
    if (_isLogin) {
      try {
        await _client.logout();
        _log(
            type: 'login',
            info: 'LogedOut',
            user: userRole,
            fullName: _userList[widget.userId]?.firstName);
        if (mounted) {
          setState(() {
            _isLogin = false;
            _isInChannel = false;
          });
        }
      } catch (e) {
        _log(type: 'error', info: 'failed logout: $e', user: widget.userId);
      }
    } else {
      if (widget.userId.isEmpty) {
        print('User id is empty.');
        return;
      }
      try {
        await _client.login(widget.rtmToken, widget.userId);
        _userData = await db.getUserByUserId(userId: widget.userId);
        if (!_userList.containsKey(widget.userId) &&
            !_members.contains(widget.userId)) {
          _members.add(widget.userId);
          _userList = {widget.userId: _userData};
        }
        if (mounted) {
          setState(() {
            _isLogin = true;
            _log(
                type: 'login',
                user: widget.userId,
                fullName: _userList[widget.userId]?.firstName);
          });
        }
      } catch (e) {
        print('Failed to login: $e');
      }
    }
  }

  Future<void> _toggleQuery() async {
    try {
      var result = await _client.queryPeersOnlineStatus(_members);
      print('the result of query: $result');
    } catch (e) {
      _log(type: 'error', info: 'Query Error: $e', user: widget.userId);
    }
  }

  Future<void> _toggleSendPeerMessage() async {
    String peerUid = widget.userId;
    if (peerUid.isEmpty) {
      _log(type: 'message', info: 'Enter peer id', user: widget.userId);
      return;
    }
    String text = 'I would like to join your stream!';
    if (text.isEmpty) {
      return;
    }

    try {
      AgoraRtmMessage message = AgoraRtmMessage.fromText(text);
      _log(type: 'message', info: message.text, user: peerUid);
      await _client.sendMessageToPeer(peerUid, message, false);
      print('message send successfully');
    } catch (e) {
      _log(type: 'error', info: 'Send Message Error: $e', user: widget.userId);
    }
  }

  void _toggleSendRemoteInivitaion() async {
    String peerUid = widget.streamUserId!;
    AgoraRtmMessage message =
        AgoraRtmMessage.fromText('would like to join your stream');
    try {
      await _client.sendMessageToPeer(peerUid, message, false);
    } catch (e, stackTrace) {
      print('An error sending invitation to Remote user: $e');
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  void _toggleSendLocalInvitation(String peerId, String text) async {
    if (peerId.isEmpty) {
      _log(type: 'message', info: 'Enter peer id', user: widget.userId);
      return;
    }
    AgoraRtmLocalInvitation invitation =
        AgoraRtmLocalInvitation(peerId, content: text);

    try {
      await _client.sendLocalInvitation(invitation.toJson());
    } catch (e, stackTrace) {
      print('error sending local invitation: $e');
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  Future<void> _toggleJoinChannel() async {
    if (_isInChannel) {
      try {
        await _channel?.leave();
        print('left channel');
        if (_channel != null) {
          _client.releaseChannel(_channel!.channelId!);
        }
        if (mounted) {
          setState(() {
            _isInChannel = false;
          });
        }
      } catch (e) {
        _log(
            type: 'error',
            info: 'Joined Channel Error: $e',
            user: widget.userId,
            fullName: _userList[widget.userId]?.firstName);
      }
    } else {
      String channelId = widget.channelName;
      if (channelId.isEmpty) {
        print('channel Id is empty');
        return;
      }
      try {
        print('the channel id: $channelId');

        _channel = await _createChannel(channelId);
        await _channel?.join();
        if (mounted) {
          setState(() {
            _isInChannel = true;
          });
        }
      } catch (e) {
        _log(
            type: 'error',
            info: 'Join Channel Error: $e',
            user: widget.userId,
            fullName: _userList[widget.userId]?.firstName);
      }
    }
  }

  Future<void> _toggleGetMembers() async {
    try {
      List<AgoraRtmMember>? members = await _channel?.getMembers();
      print('the members: $members');
    } catch (e) {
      _log(type: 'error', info: 'Get Memebers Error: $e', user: widget.userId);
    }
  }

  Future<void> _toggleSendChannelMessage() async {
    String text = _channelMessageController.text;
    if (text.isEmpty) {
      return;
    }
    try {
      await _channel?.sendMessage(AgoraRtmMessage.fromText(text));
      _log(
          type: 'message',
          info: text,
          user: widget.userId,
          fullName: _userList[widget.userId]?.firstName);
    } catch (e) {
      _log(
          type: 'error',
          info: 'Send Channel Message Error: $e',
          user: widget.userId,
          fullName: _userList[widget.userId]?.firstName);
    }
  }

  //show message chat
  void _log({String? info, String? type, String? user, String? fullName}) {
    if (type == 'message') {
      _messageList.add(Container(
        padding: EdgeInsets.only(bottom: 5),
        height: _chatItemHeight,
        width: size.width - 50,
        child: ListTile(
          leading: ClipRRect(
            child: CircleAvatar(
              radius: 20,
              backgroundImage: _userList[user]?.avatarUrl == null
                  ? Image.asset('assets/images/empty_profile_photo.png').image
                  : NetworkImage(
                      '${_userList[user]?.avatarUrl}',
                    ),
              backgroundColor: Colors.transparent,
            ),
          ),
          title: Text(
              '${_userList[user]?.firstName} ${_userList[user]?.lastName}',
              style: textStyle_23),
          subtitle: Text('$info', style: textStyle_23),
        ),
      ));
      if (_messageList.isNotEmpty) {
        print('the message list: ${_messageList.length}');
        _scrollToIndex(_messageList.length - 1);
      }
    }
    if (type == 'login') {
      _messageList.add(Container(
        padding: EdgeInsets.only(bottom: 5),
        height: _chatItemHeight,
        width: size.width - 50,
        child: ListTile(
          leading: ClipRRect(
            child: CircleAvatar(
              radius: 20,
              backgroundImage: _userList[user]?.avatarUrl == null
                  ? Image.asset('assets/images/empty_profile_photo.png').image
                  : NetworkImage(
                      '${_userList[user]?.avatarUrl}',
                    ),
              backgroundColor: Colors.transparent,
            ),
          ),
          title: Text(
              '${_userList[user]?.firstName} ${_userList[user]?.lastName}',
              style: textStyle_23),
          subtitle: Text('Logged In!', style: textStyle_23),
        ),
      ));
      if (_messageList.isNotEmpty) {
        _scrollToIndex(_messageList.length - 1);
      }
    }
    if (type == 'joined') {
      _messageList.add(Container(
        padding: EdgeInsets.only(bottom: 5),
        height: _chatItemHeight,
        width: size.width - 50,
        child: ListTile(
          leading: ClipRRect(
            child: CircleAvatar(
              radius: 20,
              backgroundImage: _userList[user]?.avatarUrl == null
                  ? Image.asset('assets/images/empty_profile_photo.png').image
                  : NetworkImage(
                      '${_userList[user]?.avatarUrl}',
                    ),
              backgroundColor: Colors.transparent,
            ),
          ),
          title: Text(
              '${_userList[user]?.firstName} ${_userList[user]?.lastName}',
              style: textStyle_23),
          subtitle: Text('$info', style: textStyle_23),
        ),
      ));
      if (_messageList.isNotEmpty) {
        _scrollToIndex(_messageList.length - 1);
      }
    }
    // if (type == 'error') {
    //   _messageList.add('$fullName: $info');
    // }
    // if (type == 'invite') {
    //   _messageList.add('Invited: $info by $fullName');
    // }
  }
}
