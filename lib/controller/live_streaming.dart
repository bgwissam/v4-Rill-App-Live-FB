import 'dart:convert';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:rillliveapp/controller/recording_controller.dart';
import 'package:rillliveapp/services/database.dart';
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
    Key? key,
  }) : super(key: key);

  @override
  _LiveStreamingState createState() => _LiveStreamingState();
}

class _LiveStreamingState extends State<LiveStreaming> {
  final _users = <int>[];
  final _infoString = <String>[];
  late RtcEngine _engine;
  bool _muted = false;
  late String userRole;
  Parameters param = Parameters();
  //Controllers
  DatabaseService db = DatabaseService();
  RecordingController recordingController = RecordingController();
  //To dispose the agora engin and clear the user list
  @override
  void dispose() {
    _users.clear();
    _engine.destroy();
    super.dispose();
  }

  //Initialize the states of the class
  @override
  void initState() {
    initializeAgore();

    super.initState();
  }

  //Will initialize the agora channel, token and app id
  Future<void> initializeAgore() async {
    print('the token received: ${widget.token}');
    print('uid: ${widget.userId} channel: ${widget.channelName}');
    if (widget.token.isNotEmpty) {
      await _initializeRtcEngine();
      //The event handler will handle the functions after the Rtc engine has been
      //initialized
      _engine.setEventHandler(
        RtcEngineEventHandler(warning: (warningCode) {
          print('Warning codes: $warningCode');
        }, error: (errorCode) {
          print('Error Code: $errorCode');
        }, joinChannelSuccess: (channel, uid, elapsed) async {
          var queryResponse = await recordingController.queryRecoding(
              resourceId: widget.resourceId,
              sid: widget.sid,
              mode: widget.mode);
          print('Query response: ${queryResponse.body}');
          setState(
            () {
              final info = 'channe: $channel, uid: $uid';
              _infoString.add(info);
            },
          );
        }, //Leave Channel
            leaveChannel: (stats) {
          setState(
            () {
              print('Left channel successfully: $stats');
              _users.clear();
            },
          );
        }, //Join Channel
            userJoined: (uid, elapsed) {
          setState(
            () {
              print('User joined: $uid, time: $elapsed');
              _users.add(uid);
            },
          );
        }, //userJoined
            userOffline: (uid, elapsed) {
          setState(
            () {
              print('User offline: $uid, time: $elapsed');
              _users.remove(uid);
            },
          );
        }, //userOffline
            streamMessage: (int uid, int streamId, String data) {
          _showMyStreamMessageDialog(uid, streamId, data);
          print('Stream message: $uid, $streamId, $data');
        }, streamMessageError: (int uid, int streamId, ErrorCode error,
                int missed, int cached) {
          print(
              'Stream message error: $uid - $streamId - $error - $missed - $cached');
        }
            // tokenPrivilegeWillExpire: (token) async {
            //   await _getToken();
            //   await _engine.renewToken(token);
            // },
            ),
      );
      print('the users: $_users - info String: $_infoString');
      //Join the channel
      await _engine.joinChannel(
          widget.token, widget.channelName, null, int.parse(widget.userId));
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

  //Will initialize the Rtc Engine
  Future<void> _initializeRtcEngine() async {
    _engine = await RtcEngine.create(param.app_ID);
    await _engine.enableVideo().catchError((err) {
      print('Error enableing video: $err');
    });
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
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        //Show the video view
        _broadCastView(),
        //show the toolbar to control the view
        _toolBar()
      ],
    );
  }

  //this function will help the list of native views
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    //the broadcaster will access the local views
    if (widget.userRole == 'publisher') {
      list.add(RtcLocalView.SurfaceView());
    }
    //other broadCasters will access the remote view
    _users.forEach(
      (int uid) => list.add(
        RtcRemoteView.SurfaceView(uid: uid),
      ),
    );
    return list;
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
    // return Container();
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
    if (widget.streamUserId == widget.userId) {
      widget.loadingStateCallback!();

      //Stop the recording and save the stream to the bucket
      var stopRecordingResult = await recordingController.stopRecordingVideos(
        channelName: widget.channelName,
        userId: widget.userId,
        sid: widget.sid,
        resouceId: widget.resourceId,
        mode: widget.mode,
      );

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
}
