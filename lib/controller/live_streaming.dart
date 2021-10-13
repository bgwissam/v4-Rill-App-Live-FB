import 'dart:convert';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:rillliveapp/controller/recording_controller.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/loading_animation.dart';
import 'package:rillliveapp/shared/parameters.dart';

class LiveStreaming extends StatefulWidget {
  final String token;
  final String channelName;
  final String userId;
  final String userRole;
  final String? resourceId;
  final String? streamUserId;
  final String? sid;
  final String? mode;
  final String? streamModelId;
  final Function? loadingStateCallback;
  const LiveStreaming({
    required this.channelName,
    required this.userRole,
    required this.token,
    this.sid,
    this.mode,
    required this.userId,
    this.resourceId,
    this.streamUserId,
    this.loadingStateCallback,
    this.streamModelId,
    Key? key,
  }) : super(key: key);

  @override
  _LiveStreamingState createState() => _LiveStreamingState();
}

class _LiveStreamingState extends State<LiveStreaming> {
  final _users = <int>[];
  final _infoString = <String>[];
  final _messageList = <String>[];
  List<UserModel> _userList = [];
  //Agora Live and Video streaming
  late RtcEngine _engine;
  //Agora Messaging
  late AgoraRtmClient _client;
  late AgoraRtmChannel _channel;
  var userMap;

  //bool values
  bool _isLogin = false;
  bool _muted = false;
  bool anyPerson = false;
  bool tryingToEnd = false;
  bool _isInChannel = false;
  bool personBool = false;
  bool accepted = false;

  int userNo = 0;
  late String userRole;
  Parameters param = Parameters();
  //Controllers
  DatabaseService db = DatabaseService();
  RecordingController recordingController = RecordingController();
  final TextEditingController _channelMessageController =
      TextEditingController();
  //To dispose the agora engin and clear the user list
  @override
  void dispose() {
    _users.clear();
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
  }

  //Initialize the states of the class
  @override
  void initState() {
    super.initState();
    initializeAgore();
    createClient();
  }

  //Will initialize the agora channel, token and app id
  Future<void> initializeAgore() async {
    if (widget.token.isNotEmpty) {
      _infoString.add('Token: ${widget.token}');
      await _initializeRtcEngine();
      _addAgoraEventHandlers();
      await _engine.setParameters(
          '''{\"che.video.lowBitRateStreamParameter\":{\"width\":320,\"height\":180,\"frameRate\":15,\"bitRate\":140}} ''');
      //Join the channel
      await _engine.joinChannel(widget.token, widget.channelName, null, 0);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to connect')));
    }
  }

  void _addAgoraEventHandlers() {
    //The event handler will handle the functions after the Rtc engine has been
    //initialized
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
          print('Error Code: $errorCode');
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
              _users.clear();
            },
          );
        }, //Join Channel
        userJoined: (uid, elapsed) {
          setState(
            () {
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

        //     //userOffline
        //     streamMessage: (int uid, int streamId, String data) {
        //   setState(() {
        //     final info = 'Stream Message: $uid, $streamId, $data';
        //     _infoString.add(info);
        //   });
        //   //_showMyStreamMessageDialog(uid, streamId, data);
        // }, streamMessageError: (int uid, int streamId, ErrorCode error,
        //         int missed, int cached) {
        //   setState(() {
        //     final info =
        //         'Stream Error: $uid, $streamId, $error, $missed, $cached';
        //     _infoString.add(info);
        //   });
        // }
        // tokenPrivilegeWillExpire: (token) async {
        //   await _getToken();
        //   await _engine.renewToken(token);
        // },
      ),
    );
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

  //Will initialize the Rtc Engine
  Future<void> _initializeRtcEngine() async {
    if (param.app_ID.isNotEmpty) {
      _engine = await RtcEngine.create(param.app_ID);
      await _engine.enableVideo().catchError((err) {
        print('Error enableing video: $err');
      });
      await _engine.enableLocalAudio(true);
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

  Future<List<Widget>> _futureRenderViews() async {
    return _getRenderViews();
  }

  @override
  Widget build(BuildContext context) {
    print('the infoString: $_infoString');
    return Scaffold(
        body: FutureBuilder(
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
                    widget.userRole == 'publisher'
                        ? _toolBar()
                        : const SizedBox.shrink(),
                    //show messaging bar
                    widget.userRole == 'publisher'
                        ? const SizedBox.shrink()
                        : _bottomBar(),
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
            }));
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
    _users.forEach((int uid) {
      print('user adding remote view');
      list.add(
        RtcRemoteView.SurfaceView(uid: uid),
      );
    });
    print('the list of users: $list');
    return list;
  }

  Widget _infoPannel() {
    return Positioned(
      left: 0,
      top: 0,
      child: Container(
          height: 100,
          decoration: BoxDecoration(
              color: Colors.grey,
              border: Border.all(),
              borderRadius: BorderRadius.circular(20)),
          padding: EdgeInsets.all(10.0),
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.5,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(5.0),
                child: ListView.builder(
                    itemCount: _infoString.length,
                    itemBuilder: (context, index) {
                      if (_infoString.isEmpty) {
                        return Text('Empty');
                      }
                      return Padding(
                        padding: EdgeInsets.all(5.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(child: Text(_infoString[index].toString()))
                          ],
                        ),
                      );
                    }),
              ),
            ),
          )),
    );
  }

  Widget _broadCastView() {
    final views = _getRenderViews();
    print('the total views are: ${views.length}');

    switch (views.length) {
      case 1:
        return Container(
            child: Column(
          children: [
            _expandedViewWidget([views[0]])
          ],
        ));
      case 2:
        return Container(
            child: Column(
          children: [
            _expandedViewWidget([views[0]]),
            _expandedViewWidget([views[1]]),
          ],
        ));
      case 3:
        return Container(
            child: Column(
          children: [
            _expandedViewWidget(views.sublist(0, 2)),
            _expandedViewWidget(views.sublist(2, 3))
          ],
        ));
      case 4:
        return Container(
            child: Column(
          children: [
            _expandedViewWidget(views.sublist(0, 2)),
            _expandedViewWidget(views.sublist(2, 4))
          ],
        ));
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
                child: Container(
              child: view,
            )))
        .toList();
    return Expanded(
      child: Row(children: wrappedViews),
    );
  }

  //Info panel to show logs
  Widget messageList() {
    return Container(
      padding: const EdgeInsets.only(bottom: 15),
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
          heightFactor: 0.5,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: ListView.builder(
                reverse: true,
                itemCount: _infoString.length,
                itemBuilder: (context, index) {
                  if (_infoString.isEmpty) {
                    return Container();
                  }
                  return Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                      child: Text('${_infoString[index]}'));
                }),
          )),
    );
  }

  Widget _toolBar() {
    return widget.userRole == 'publisher'
        ? Container(
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.symmetric(vertical: 35.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RawMaterialButton(
                    onPressed: _onToggleMute,
                    child: Icon(
                      _muted ? Icons.mic_off : Icons.mic,
                      color: _muted ? Colors.white : Colors.redAccent,
                      size: 20.0,
                    ),
                    shape: const CircleBorder(),
                    elevation: 2.0,
                    fillColor: _muted ? Colors.redAccent : Colors.white,
                    padding: const EdgeInsets.all(12.0)),
                RawMaterialButton(
                  onPressed: () => _onCallEnd(context),
                  child: const Icon(Icons.call_end,
                      color: Colors.white, size: 30.0),
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.red,
                  padding: const EdgeInsets.all(15.0),
                ),
                RawMaterialButton(
                  onPressed: () => _onSwitchCamera(context),
                  child: const Icon(Icons.switch_camera,
                      color: Colors.white, size: 30.0),
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  fillColor: Colors.grey,
                  padding: const EdgeInsets.all(12.0),
                ),
              ],
            ))
        : const SizedBox.shrink();
  }

  //tool bar functions
  void _onCallEnd(BuildContext context) async {
    String streamingId =
        await db.fetchStreamingVideoUrl(uid: widget.streamModelId);
    if (streamingId == widget.streamUserId) {
      widget.loadingStateCallback!();

      //Stop the recording and save the stream to the bucket
      var stopRecordingResult = await recordingController.stopRecordingVideos(
        channelName: widget.channelName,
        userId: widget.userId,
        sid: widget.sid,
        resouceId: widget.resourceId,
        mode: widget.mode,
      );
      await db.deleteStreamingVideo(streamId: widget.streamModelId);
      var stopRecordResponse = await json.decode(stopRecordingResult.body);
      print('Stop response: $stopRecordResponse');
    }

    Navigator.pop(context);
  }

  void _onToggleMute() {
    setState(() {
      _muted = !_muted;
    });
    _engine.muteAllRemoteAudioStreams(_muted);
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
    // if (!_isLogin || !_isInChannel) {
    //   return Container();
    // }
    return Container(
        height: 100,
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(left: 8, top: 5, right: 8, bottom: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  cursorColor: Colors.blue,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                  style: textStyle_4,
                  controller: _channelMessageController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Comment',
                    hintStyle: textStyle_4,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50.0),
                        borderSide: const BorderSide(color: Colors.white)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50.0),
                        borderSide: const BorderSide(color: Colors.white)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4.0, 0, 0, 0),
                child: MaterialButton(
                  minWidth: 0,
                  onPressed: _toggleSendChannelMessage,
                  child: ImageIcon(AssetImage("assets/icons/send_rill.png"),
                      color: color_12, size: 20),
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  color: color_7,
                  padding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ));
  }

  void _addPerson() {
    setState(() {
      personBool = !personBool;
    });
  }

  void stopFunction() {
    setState(() {
      accepted = false;
    });
  }

  void _logout() async {
    try {
      await _client.logout();
    } catch (e) {
      _infoString.add('Error logging out: $e type: logout');
    }
  }

  void _leaveChannel() async {
    try {
      await _channel.leave();
      _client.releaseChannel(_channel.channelId!);
      _channelMessageController.text = '';
    } catch (e) {
      _infoString.add('Error leaving: $e type: leaving');
    }
  }

  void _toggleSendChannelMessage() async {
    String text = _channelMessageController.text;
    if (text.isEmpty) {
      return;
    }
    try {
      _channelMessageController.clear();
      await _channel.sendMessage(AgoraRtmMessage.fromText(text));
      setState(() {
        _infoString.add('${widget.userId}: $text');
        _log(info: text, type: 'message', user: widget.userId);
      });
    } catch (e) {
      setState(() {
        _log(info: e.toString(), type: 'message', user: widget.userId);
      });
    }
  }

  void _sendMessage(text) async {
    if (text.isEmpty) {
      return;
    }
    try {
      _channelMessageController.clear();
      await _channel.sendMessage(AgoraRtmMessage.fromText(text));
      setState(() {
        _infoString.add('${widget.userId}: $text');
        _log(info: text, type: 'message', user: widget.userId);
      });
    } catch (e) {
      setState(() {
        _log(info: e.toString(), type: 'message', user: widget.userId);
      });
    }
  }

  void createClient() async {
    _client = await AgoraRtmClient.createInstance(Parameters().app_ID);
    _client.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      print('message received: ${message.text}');
      _infoString.add('user: $peerId message: ${message.text}');
    };

    _client.onConnectionStateChanged = (int state, int reason) {
      if (state == 5) {
        _client.logout();
        setState(() {
          _isLogin = false;
        });
      }
    };
    await _client.login(widget.token, widget.channelName);
    _channel = await _createChannel(widget.channelName);

    await _channel.join();
  }

  Future<AgoraRtmChannel> _createChannel(String name) async {
    AgoraRtmChannel? channel = await _client.createChannel(name);
    channel!.onMemberJoined = (AgoraRtmMember member) async {
      _infoString.add('memeber joinded: ${member.userId}');

      setState(() {
        _userList.add(UserModel(userId: member.userId));
        if (_userList.isNotEmpty) {
          anyPerson = true;
        }
      });
      userMap.putIfAbsent(member.userId, () => 'usr img');
      var len;
      _channel.getMembers().then((value) {
        len = value.length;
        setState(() {
          userNo = len - 1;
        });
      });

      _infoString.add('info: Member Joined: ${member.userId} type: join ');
    };
    channel.onMemberLeft = (AgoraRtmMember member) {
      var len;
      setState(() {
        _userList.removeWhere((element) => element.userId == member.userId);
        if (_userList.isEmpty) {
          anyPerson = false;
        }
      });
      _channel.getMembers().then((value) {
        len = value.length;
        setState(() {
          userNo = len - 1;
        });
      });
    };

    channel.onMessageReceived =
        (AgoraRtmMessage message, AgoraRtmMember member) {
      _infoString
          .add('user: ${member.userId} message: ${message.text} type: message');
    };
    return channel;
  }

  //show message chat
  void _log({String? info, String? type, String? user}) {
    if (type == 'message') {
      _messageList.add('$user: $info');
    }
  }
}
