import 'dart:convert';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:rillliveapp/controller/recording_controller.dart';
import 'package:rillliveapp/models/user_model.dart';
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
  }) : super(key: key);

  @override
  _LiveStreamingState createState() => _LiveStreamingState();
}

class _LiveStreamingState extends State<LiveStreaming> {
  final _users = <int>[];
  final _infoString = <String>[];
  late List<String> _messageList;
  List<UserModel> _userList = [];
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

  int userNo = 0;
  int _remoteId = 0;
  var size;
  late String userRole;
  Parameters param = Parameters();
  //Controllers
  DatabaseService db = DatabaseService();
  RecordingController recordingController = RecordingController();
  late TextEditingController _channelMessageController;
  late FirebaseStorage storageRef;
  AWSstorage awsStorage = AWSstorage();

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
    widget.userRole == 'publisher' ? _onCallEnd(context) : null;
    super.dispose();
  }

  //Initialize the states of the class
  @override
  void initState() {
    super.initState();
    // To keep the screen on:
    Wakelock.enable();
    _messageList = [];

    _channelMessageController = TextEditingController();
    initializeAgore();
    _createClient();
  }

  //Will initialize the Rtc Engine
  Future<void> _initializeRtcEngine() async {
    if (param.app_ID.isNotEmpty) {
      RtcEngineContext context = RtcEngineContext(param.app_ID);
      _engine = await RtcEngine.createWithContext(context);

      //set event handlers
      _engine.setEventHandler(
        RtcEngineEventHandler(
          warning: (warningCode) {
            setState(() {
              final info = 'warning: $warningCode';
              _infoString.add(info);
            });
          },
          error: (errorCode) {
            setState(() {
              final info = 'Error: $errorCode';
              _infoString.add(info);
            });
            print('Error Code: ${errorCode.index} - $errorCode');
            Sentry.captureException(errorCode);
          },
          joinChannelSuccess: (channel, uid, elapsed) async {
            var queryResponse = await recordingController.queryRecoding(
                resourceId: widget.resourceId,
                sid: widget.sid,
                mode: widget.mode);
            print(
                'Query response: ${queryResponse.body} Join Success: $channel - $uid - $elapsed');
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
            print('Added users: $_users');
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

      await _engine.enableVideo().catchError((err) {
        print('Error enableing video: $err');
      });
      await _engine.enableLocalAudio(true);
      if (widget.userRole == 'subscriber') {
        _engine.disableAudio();
      }

      await _engine
          .setChannelProfile(ChannelProfile.LiveBroadcasting)
          .catchError((err) {
        print('Error setting the channel Profile: $err');
      });
      if (widget.userRole == 'publisher') {
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
      _infoString
          .add('Rtc_Token: ${widget.rtcToken} - Rtm_Token: ${widget.rtmToken}');
      await _initializeRtcEngine();
      // await _engine.setParameters(
      //     '''{\"che.video.lowBitRateStreamParameter\":{\"width\":320,\"height\":180,\"frameRate\":15,\"bitRate\":140}} ''');
      //Join the channel
      await _engine.joinChannel(
          widget.rtcToken, widget.channelName, null, widget.uid!);
      //creat live messaging channel
      //_channel = await _createChannel(widget.channelName);

      //await _joinChannel(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to connect')));
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
    return Scaffold(
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
                    widget.userRole == 'publisher'
                        ? _broadCastView()
                        : _audienceView(),
                    //show the toolbar to control the view

                    //_toolBar(),

                    //show messaging bar
                    widget.userRole == 'publisher'
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
          _bottomBar()
        ],
      ),
      //bottomNavigationBar: _bottomBar(),
    );
  }

  //this function will help the list of native views
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    //the broadcaster will access the local views
    if (widget.userRole == 'publisher') {
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
      return Container(
        child: _expandedViewWidget(
          [views[0]],
        ),
      );
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
    return widget.userRole == 'publisher'
        ? Expanded(
            child: Row(children: wrappedViews),
          )
        : SizedBox(
            width: size.width,
            child: Row(children: wrappedViews),
          );
  }

  //Info panel to show logs
  Widget messageList() {
    print('the message List: $_messageList');
    return Container(
      padding: const EdgeInsets.only(bottom: 100),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
          heightFactor: 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: ListView.builder(
                  reverse: false,
                  itemCount: _messageList.length,
                  itemBuilder: (context, index) {
                    // _messageList.reversed;
                    if (_messageList.isEmpty) {
                      return Text('Empty messages');
                    }
                    return Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 3, horizontal: 10),
                        child: Text(
                          _messageList[index],
                        ),
                      ),
                    );
                  }),
            ),
          )),
    );
  }

  Widget _toolBar() {
    return Positioned(
      left: 0,
      top: size.height - 170,
      height: 130,
      width: size.width,
      child: Row(
        children: [
          Expanded(flex: 1, child: _bottomBar()),
        ],
      ),
    );

    // return Container(
    //   alignment: Alignment.bottomCenter,
    //   padding: const EdgeInsets.symmetric(vertical: 35.0),
    //   child: Row(
    //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //     children: [
    //       RawMaterialButton(
    //           onPressed: _onToggleMute,
    //           child: Icon(
    //             _muted ? Icons.mic_off : Icons.mic,
    //             color: _muted ? Colors.white : Colors.redAccent,
    //             size: 20.0,
    //           ),
    //           shape: const CircleBorder(),
    //           elevation: 2.0,
    //           fillColor: _muted ? Colors.redAccent : Colors.white,
    //           padding: const EdgeInsets.all(12.0)),
    //       RawMaterialButton(
    //         onPressed: () => _onCallEnd(context),
    //         child: const Icon(Icons.call_end, color: Colors.white, size: 30.0),
    //         shape: const CircleBorder(),
    //         elevation: 2.0,
    //         fillColor: Colors.red,
    //         padding: const EdgeInsets.all(15.0),
    //       ),
    //       RawMaterialButton(
    //         onPressed: () => _onSwitchCamera(context),
    //         child: const Icon(Icons.switch_camera,
    //             color: Colors.white, size: 30.0),
    //         shape: const CircleBorder(),
    //         elevation: 2.0,
    //         fillColor: Colors.grey,
    //         padding: const EdgeInsets.all(12.0),
    //       ),
    //     ],
    //   ),
    // );
  }

  Widget _requestJoin() {
    return Container(
      margin: EdgeInsets.only(right: 5, bottom: 5),
      decoration: BoxDecoration(
          border: Border.all(color: color_4),
          borderRadius: BorderRadius.circular(15)),
      child: TextButton(
        child: Text('Request to Join', style: textStyle_19),
        onPressed: () async {
          print('we shall add this later');
        },
      ),
    );
  }

  //tool bar functions
  void _onCallEnd(BuildContext context) async {
    String streamingId = '';
    if (widget.streamModelId != null) {
      streamingId = await db.fetchStreamingVideoUrl(uid: widget.streamModelId);
      if (streamingId == widget.streamUserId) {
        //widget.loadingStateCallback!();
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

        print('the result stop: $stopRecordResponse');
        //save the live stream to firebase
        _saveLiveStream(stopRecordResponse);
      }
    } else {
      print('An error occured: streamModelId is null');
      await Sentry.captureException('streamModelId is null');
      Navigator.pop(context);
    }
  }

  void _saveLiveStream(var data) async {
    String thumbnailUrl = '';
    var streamFile;
    var streamKey;
    if (data['serverResponse'] != null &&
        data['serverResponse']['uploadingStatus'] == 'uploaded') {
      streamKey = data['serverResponse']['fileList'];
      print('the stream key: $streamKey');
      if (streamKey != null) {
        // await awsStorage.list();
      }

      //generate streaming thumbnail
      StorageData sd = StorageData();
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

        if (data['serverResponse']['uploadingStatus'] == 'uploaded') {
          var streamUrl =
              'https://videos165240-dev.s3.us-west-2.amazonaws.com/${data['serverResponse']['fileList']}';

          var result = await db.saveEndedLiveStream(
              userId: widget.userId,
              thumbnailUrl: thumbnailUrl,
              streamUrl: streamUrl,
              description: 'We will create that later');

          if (result.isNotEmpty) {
            print('The video stream was uploaded properly');
          } else {
            print(
                'An error occured uploading stream, check with customer support');
          }
        }
      } else {
        print('stream file is null');
      }
    } else {
      await Sentry.captureException('Error obtaining server response aws');
    }
    Navigator.pop(context);
  }

  void _onToggleMute() {
    setState(() {
      _muted = !_muted;
    });
    print('muted: $_muted');
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
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(left: 6, right: 6, bottom: 5),
                width: size.width / 2 + 40,
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

                  // InputDecoration(
                  //   suffix: Padding(
                  //     padding: EdgeInsets.fromLTRB(0, 15, 0, 0),
                  //     child: MaterialButton(
                  //       minWidth: 0,
                  //       onPressed: () async {
                  //         await _toggleSendChannelMessage();
                  //         setState(() {
                  //           _channelMessageController.clear();
                  //         });
                  //       },
                  //       child: ImageIcon(AssetImage("assets/icons/send_rill.png"),
                  //           color: color_12, size: 20),
                  //       shape: const CircleBorder(),
                  //       elevation: 1.0,
                  //       color: color_7,
                  //       padding: const EdgeInsets.all(10),
                  //     ),
                  //   ),
                  //   isDense: false,
                  //   hintText: 'Comment',
                  //   hintStyle: textStyle_22,
                  //   enabledBorder: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(10.0),
                  //       borderSide: const BorderSide(color: Colors.white)),
                  //   focusedBorder: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(10.0),
                  //       borderSide: const BorderSide(color: Colors.white)),
                  // ),
                ),
              ),
              _requestJoin()
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
        setState(() {
          _isLogin = false;
        });
      }
    };

    _client.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      _log(
          info: message.text,
          type: 'message',
          user: peerId,
          fullName:
              '${widget.currentUser?.firstName} ${widget.currentUser?.lastName}');
    };

    _client.onLocalInvitationReceivedByPeer = (AgoraRtmLocalInvitation invite) {
      _log(
          type: 'invite',
          info: 'invitation received Local',
          user: invite.calleeId,
          fullName:
              '${widget.currentUser?.firstName} ${widget.currentUser?.lastName}');
    };

    _client.onRemoteInvitationReceivedByPeer =
        (AgoraRtmRemoteInvitation invite) {
      _log(
          type: 'invite',
          info: 'invitation received Remote',
          user: invite.callerId,
          fullName:
              '${widget.currentUser?.firstName} ${widget.currentUser?.lastName}');
    };

    await _toggleLogin();
    await _toggleJoinChannel();
  }

  Future<AgoraRtmChannel?> _createChannel(String name) async {
    AgoraRtmChannel? channel = await _client.createChannel(name);
    if (channel != null) {
      channel.onMemberJoined = (AgoraRtmMember member) {
        print('memeber joined: ${member.userId}');
        _log(
            type: 'joined',
            user: member.userId,
            info: 'Joined',
            fullName:
                '${widget.currentUser?.firstName} ${widget.currentUser?.lastName}');
      };
      channel.onMemberLeft = (AgoraRtmMember member) {
        _log(
            type: 'joined',
            user: member.userId,
            info: 'Left',
            fullName:
                '${widget.currentUser?.firstName} ${widget.currentUser?.lastName}');
      };
      channel.onMessageReceived =
          (AgoraRtmMessage message, AgoraRtmMember memeber) {
        setState(() {
          _log(
              type: 'message',
              user: memeber.userId,
              info: message.text,
              fullName:
                  '${widget.currentUser?.firstName} ${widget.currentUser?.lastName}');
        });
      };
    }
    return channel;
  }

  Future<void> _toggleLogin() async {
    print('client is logging in: $_isLogin');
    if (_isLogin) {
      try {
        await _client.logout();
        _log(type: 'login', info: 'LogedOut');
        setState(() {
          _isLogin = false;
          _isInChannel = false;
        });
      } catch (e) {
        _log(type: 'error', info: 'failed logout: $e', user: widget.userId);
      }
    } else {
      print('client user id: ${widget.userId}');
      if (widget.userId.isEmpty) {
        _log(type: 'message', info: 'please input userId', user: widget.userId);
        return;
      }
      try {
        await _client.login(widget.rtmToken, widget.userId);
        _log(type: 'login', user: widget.userId);
        setState(() {
          _isLogin = true;
        });
      } catch (e) {
        _log(type: 'error', info: 'Login error: $e', user: widget.userId);
        print('Failed to login: $e');
      }
    }
  }

  Future<void> _toggleQuery() async {
    String peerUid = _peerUserIdController.text;
    if (peerUid.isEmpty) {
      _log(type: 'message', info: 'Enter peer id', user: widget.userId);
      return;
    }
    try {
      Map<dynamic, dynamic> result =
          await _client.queryPeersOnlineStatus([peerUid]);
      _log(type: 'message', info: result.toString(), user: peerUid);
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
    String text = _channelMessageController.text;
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

  void _toggleSendLocalInvitation() async {
    String peerUid = _peerUserIdController.text;
    if (peerUid.isEmpty) {
      _log(type: 'message', info: 'Enter peer id', user: widget.userId);
      return;
    }
    String text = 'Woud you like to join';
    try {
      AgoraRtmLocalInvitation invitation =
          AgoraRtmLocalInvitation(peerUid, content: text);
      _log(
          type: 'message',
          info: 'Invitation: $invitation',
          user: widget.userId,
          fullName:
              '${widget.currentUser?.firstName} ${widget.currentUser?.lastName}');
      await _client.sendLocalInvitation(invitation.toJson());
      print('Invititation sent successfully');
    } catch (e) {
      _log(
          type: 'error',
          info: 'Send Invitation Error: $e',
          user: widget.userId,
          fullName:
              '${widget.currentUser?.firstName} ${widget.currentUser?.lastName}');
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
        // _channelMessageController.clear();
        setState(() {
          _isInChannel = false;
        });
      } catch (e) {
        _log(
            type: 'error',
            info: 'Joined Channel Error: $e',
            user: widget.userId,
            fullName:
                '${widget.currentUser?.firstName} ${widget.currentUser?.lastName}');
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

        setState(() {
          _isInChannel = true;
        });
      } catch (e) {
        _log(
            type: 'error',
            info: 'Join Channel Error: $e',
            user: widget.userId,
            fullName:
                '${widget.currentUser?.firstName} ${widget.currentUser?.lastName}');
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

  void _sendMessage() async {
    await _toggleSendChannelMessage();
  }

  Future<void> _toggleSendChannelMessage() async {
    String text = _channelMessageController.text;
    if (text.isEmpty) {
      return;
    }
    try {
      await _channel?.sendMessage(AgoraRtmMessage.fromText(text));
      print('the channel message: $text');
      _log(
          type: 'message',
          info: text,
          user: widget.userId,
          fullName:
              '${widget.currentUser?.firstName} ${widget.currentUser?.lastName}');
      print('message channel sent successfully');
    } catch (e) {
      _log(
          type: 'error',
          info: 'Send Channel Message Error: $e',
          user: widget.userId,
          fullName:
              '${widget.currentUser?.firstName} ${widget.currentUser?.lastName}');
    }
  }

  // void stopFunction() {
  //   setState(() {
  //     accepted = false;
  //   });
  // }

  // void _logout() async {
  //   try {
  //     await _client.logout();
  //   } catch (e) {
  //     _infoString.add('Error logging out: $e type: logout');
  //   }
  // }

  // void _leaveChannel() async {
  //   try {
  //     await _channel.leave();
  //     _client.releaseChannel(_channel.channelId!);
  //     _channelMessageController.text = '';
  //   } catch (e) {
  //     _infoString.add('Error leaving: $e type: leaving');
  //   }
  // }

  // void _toggleSendChannelMessage() async {
  //   String text = _channelMessageController.text;
  //   if (text.isEmpty) {
  //     return;
  //   }
  //   try {
  //     _channelMessageController.clear();
  //     await _channel.sendMessage(AgoraRtmMessage.fromText(text));
  //     print('the message: $text');
  //     setState(() {
  //       //_infoString.add('${widget.userId}: $text');
  //       _log(info: text, type: 'message', user: widget.userId);
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _log(info: e.toString(), type: 'message', user: widget.userId);
  //     });
  //   }
  // }

  // //send message to other users
  // void _sendMessage(text) async {
  //   print('the text being sent: $text');
  //   if (text.isEmpty) {
  //     return;
  //   }
  //   try {
  //     _channelMessageController.clear();

  //     await _channel.sendMessage(AgoraRtmMessage.fromText(text));
  //     setState(() {
  //       _infoString.add('${widget.userId}: $text');
  //       _log(info: text, type: 'message', user: widget.userId);
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _log(info: e.toString(), type: 'message', user: widget.userId);
  //     });
  //   }
  // }

  // void createClient() async {
  //   _client = await AgoraRtmClient.createInstance(Parameters().app_ID);

  //   _client.onConnectionStateChanged = (int state, int reason) {
  //     print('Connection state changed: $state - reasong: $reason');
  //     if (state == 5) {
  //       _client.logout();
  //       setState(() {
  //         _isLogin = false;
  //       });
  //       return;
  //     }
  //   };

  //   await _login(context);

  //   _client.onMessageReceived = (AgoraRtmMessage message, String peerId) {
  //     setState(() {
  //       print('a message received: $message - $peerId');
  //       _log(type: 'message', user: peerId, info: message.text);
  //     });
  //   };

  //   _channel = await _createChannel(widget.channelName);
  //   await _channel.join();
  //   _client.onConnectionStateChanged = (int state, int reason) {
  //     print('Connection state changed: $state - reasong: $reason');
  //     if (state == 5) {
  //       _client.logout();
  //       setState(() {
  //         _isLogin = false;
  //       });
  //       return;
  //     }
  //   };
  // }

  // //will login current user
  // Future _login(BuildContext context) async {
  //   print('im before: loging');
  //   if (widget.userId.isEmpty) {
  //     print('user id is empty');
  //     setState(() {
  //       _isLogin = false;
  //     });

  //     return;
  //   }
  //   try {
  //     print(
  //         'The rtm loging: ${widget.rtmToken} - ${widget.channelName} - ${widget.userId}');
  //     await _client.login(widget.rtmToken, widget.channelName);
  //     _log(type: 'login', user: widget.userId);
  //     setState(() {
  //       _isLogin = true;
  //     });
  //     //_joinChannel(context);
  //   } catch (e, stackTrace) {
  //     print('An error login in rtm service: $e - $stackTrace');
  //   }
  // }

  // //will query online users
  // void _queryOnlineUsers(BuildContext context) async {
  //   String? peerId = widget.streamUserId;
  //   if (peerId!.isEmpty) {
  //     _log(type: 'login', user: 'empty', info: 'user id is null');
  //   }
  //   try {
  //     Map<dynamic, dynamic> result =
  //         await _client.queryPeersOnlineStatus([peerId]);
  //     _log(type: 'login', user: peerId, info: '$result');
  //   } catch (e, stackTrace) {
  //     print('query peers error: $e - $stackTrace');
  //     _log(type: 'error', user: peerId, info: '$e');
  //   }
  // }

  // Future _joinChannel(BuildContext context) async {
  //   String channelId = widget.channelName;
  //   if (channelId.isEmpty) {
  //     _log(type: 'joined', info: 'no channel Id', user: widget.userId);
  //     return;
  //   }
  //   _channel = await _createChannel(channelId);

  //   await _channel.join().catchError((err) {
  //     print('an error joining: $err');
  //     _log(type: 'error', info: 'error joining', user: widget.userId);
  //   }).then((value) {
  //     print('joined channel successfully');
  //     _log(type: 'joined', info: 'user joined', user: widget.userId);
  //   });
  //   // _log(type: 'joined', user: widget.userId, info: 'joined');
  // }

  // Future<AgoraRtmChannel> _createChannel(String name) async {
  //   AgoraRtmChannel? channel = await _client.createChannel(name);

  //   //on member joined
  //   channel!.onMemberJoined = (AgoraRtmMember member) async {
  //     print('new member joined: ${member.userId}');
  //     _log(type: 'joined', user: member.userId, info: 'joined');

  //     setState(() {
  //       _userList.add(UserModel(userId: member.userId));
  //       if (_userList.isNotEmpty) {
  //         anyPerson = true;
  //       }
  //     });
  //     userMap.putIfAbsent(member.userId, () => 'usr img');
  //     var len;
  //     _channel.getMembers().then((value) {
  //       len = value.length;
  //       setState(() {
  //         userNo = len - 1;
  //       });
  //     });
  //   };
  //   //on member left
  //   channel.onMemberLeft = (AgoraRtmMember member) {
  //     var len;
  //     _log(type: 'joined', user: member.userId, info: 'left');
  //     setState(() {
  //       _userList.removeWhere((element) => element.userId == member.userId);
  //       if (_userList.isEmpty) {
  //         anyPerson = false;
  //       }
  //       _leaveChannel();
  //     });
  //     _channel.getMembers().then((value) {
  //       len = value.length;
  //       setState(() {
  //         userNo = len - 1;
  //       });
  //     });
  //   };
  //   //on message received
  //   channel.onMessageReceived =
  //       (AgoraRtmMessage message, AgoraRtmMember member) {
  //     print('message sent: $message');
  //     _log(type: 'message', user: member.userId, info: message.text);
  //   };
  //   return channel;
  // }

  //show message chat
  void _log({String? info, String? type, String? user, String? fullName}) {
    if (type == 'message') {
      _messageList.add('$fullName: $info');
    }
    if (type == 'login') {
      _messageList.add('$fullName : logged in');
    }
    if (type == 'joined') {
      _messageList.add('$fullName: $info');
    }
    if (type == 'error') {
      _messageList.add('$fullName: $info');
    }
    // if (type == 'state') {
    //   _messageList.add('changed: $info');
    // }
    if (type == 'invite') {
      _messageList.add('Invited: $info by $fullName');
    }
  }
}
