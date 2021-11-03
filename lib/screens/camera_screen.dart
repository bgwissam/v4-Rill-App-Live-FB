import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rillliveapp/controller/live_streaming.dart';
import 'package:rillliveapp/controller/recording_controller.dart';
import 'package:rillliveapp/controller/token_controller_rtc.dart';
import 'package:rillliveapp/controller/token_controller_rtm.dart';
import 'package:rillliveapp/main.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/services/storage_data.dart';
import 'package:rillliveapp/shared/aspect_ration_video.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/loading_animation.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key, this.userId}) : super(key: key);
  final String? userId;
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  //controllers
  CameraController? _controller;
  VideoPlayerController? _vcontroller;
  VideoPlayerController? _toBeDisposed;
  RecordingController _recordingController = RecordingController();
  StorageData storageData = StorageData();
  DatabaseService db = DatabaseService();
  RtcTokenGenerator rtctokenGenerator = RtcTokenGenerator();
  RtmTokenGenerator rtmTokenGenerator = RtmTokenGenerator();
  ImagePicker _imagePicker = ImagePicker();
  late ScrollController _scrollController;
  //variables
  ResolutionPreset currentResolutionPreset = ResolutionPreset.high;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  bool _isCameraInitialized = false;
  bool _isRearCameraSelected = true;
  bool _ismicOn = true;
  String? description;
  FlashMode? _currentFlashMode;
  final ImagePicker _picker = ImagePicker();
  int selectedButton = 0;
  late bool _isUploadingFile = false;
  late bool _isRecordingVideo = false;
  String? rtcToken;
  String? rtmToken;
  String? _channelName;
  int? uid;
  late bool _isLoadingStream = false;
  late bool _camButtonPressed = false;
  int? selectedIndex = 0;
  //Maps
  late Map acquireResponse;
  late Map startRecording;

  Widget textButton(String text, Function()? function, Color color) {
    return TextButton(
      onPressed: function,
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 15,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _channelName = 'testing';
    _getTokens();
    onNewCameraSelected(cameras[0]);

    _scrollController = ScrollController();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        onNewCameraSelected(_controller!.description);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();

    super.dispose();
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = _controller;

    final CameraController cameraController = CameraController(
      cameraDescription,
      currentResolutionPreset,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await previousCameraController?.dispose();
    if (mounted) {
      setState(() {
        _controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    try {
      await cameraController.initialize();
      await Future.wait([
        cameraController
            .getMinExposureOffset()
            .then((value) => _minAvailableExposureOffset = value),
        cameraController
            .getMaxExposureOffset()
            .then((value) => _maxAvailableExposureOffset = value),
      ]);

      _currentFlashMode = _controller!.value.flashMode;
    } on CameraException catch (e) {
      print('Error initializing camera: $e');
    }

    if (mounted) {
      setState(() {
        _isCameraInitialized = _controller!.value.isInitialized;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: _isCameraInitialized
            ? Column(
                children: [
                  SizedBox(
                    height: size.height - 25,
                    child: ClipRRect(
                      child: AspectRatio(
                        aspectRatio: 1 / _controller!.value.aspectRatio,
                        child: Stack(
                          children: [
                            _controller!.buildPreview(),
                            Positioned(
                                left: 0,
                                top: size.height - 170,
                                height: 120,
                                width: size.width / 2 + 50,
                                child: GestureDetector(
                                  onTap: () async {},
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: IconButton(
                                            iconSize: 30,
                                            onPressed: () {
                                              setState(() {
                                                _isCameraInitialized = false;
                                              });
                                              onNewCameraSelected(cameras[
                                                  _isRearCameraSelected
                                                      ? 1
                                                      : 0]);
                                              setState(() {
                                                _isRearCameraSelected =
                                                    !_isRearCameraSelected;
                                              });
                                            },
                                            icon: Image.asset(
                                              'assets/icons/two_arrow_rill.png',
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: IconButton(
                                            iconSize: 30,
                                            onPressed: () {
                                              setState(() {
                                                _ismicOn = !_ismicOn;
                                              });
                                            },
                                            icon: _ismicOn
                                                ? Image.asset(
                                                    'assets/icons/bolt_rill_icon_light.png',
                                                    color: Colors.white,
                                                  )
                                                : Image.asset(
                                                    'assets/icons/bolt_rill_icon_dark.png',
                                                    color: Colors.white,
                                                  ),
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 20),
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: IconButton(
                                            iconSize: 60,
                                            onPressed: () async {
                                              if (selectedButton == 2) {
                                                var result = await _controller
                                                    ?.takePicture();
                                                setState(() {
                                                  _camButtonPressed = true;
                                                  _previewImage(result);
                                                });
                                              }
                                              if (selectedButton == 1) {
                                                if (mounted) {
                                                  setState(() {
                                                    _camButtonPressed = true;
                                                  });
                                                }

                                                if (_controller == null ||
                                                    !_controller!
                                                        .value.isInitialized) {
                                                  print(
                                                      'error select camera first');
                                                }

                                                if (_controller!
                                                    .value.isRecordingVideo) {
                                                  setState(() {
                                                    _isRecordingVideo = true;
                                                  });
                                                }
                                                try {
                                                  if (!_isRecordingVideo) {
                                                    await _controller!
                                                        .startVideoRecording();
                                                    setState(() {
                                                      _isRecordingVideo = true;
                                                      print(
                                                          'is recordinging $_isRecordingVideo');
                                                    });
                                                  } else {
                                                    var result =
                                                        await _controller!
                                                            .stopVideoRecording()
                                                            .then((file) async {
                                                      print(
                                                          'video: ${file.path} - ${file.name} - ${file.length}');
                                                      if (mounted) {
                                                        setState(() {});
                                                      }

                                                      if (file != null) {
                                                        _previewVideo(file);
                                                      }
                                                    });

                                                    setState(() {
                                                      _isRecordingVideo = false;
                                                    });
                                                  }
                                                } on CameraException catch (e, stackTrace) {
                                                  print(
                                                      'An exception with the camera occured: $e - $stackTrace');
                                                }
                                              }
                                              if (selectedButton == 0) {
                                                //live streaming
                                                if (mounted) {
                                                  setState(() {
                                                    _camButtonPressed = true;
                                                    _isLoadingStream = true;
                                                  });
                                                }
                                                if (rtcToken == 'failed') {
                                                  return;
                                                }
                                                if (_controller == null ||
                                                    !_controller!
                                                        .value.isInitialized) {
                                                  print(
                                                      'error select camera first');
                                                  return;
                                                }

                                                if (_controller!
                                                    .value.isRecordingVideo) {
                                                  setState(() {
                                                    _isLoadingStream = true;
                                                  });
                                                }
                                                //Start live streaming
                                                try {
                                                  if (!_isRecordingVideo) {
                                                    setState(() {
                                                      _isLoadingStream = true;
                                                    });
                                                    //Check if recording could be started
                                                    var acquire =
                                                        await _recordingController
                                                            .getVideoRecordingRefId(
                                                                _channelName!,
                                                                '0',
                                                                rtcToken!);
                                                    acquireResponse = await json
                                                        .decode(acquire.body);

                                                    if (acquireResponse[
                                                            'resourceId'] !=
                                                        null) {
                                                      var start = await _recordingController
                                                          .startRecordingVideo(
                                                              acquireResponse[
                                                                  'resourceId'],
                                                              'mix',
                                                              _channelName!,
                                                              '0',
                                                              rtcToken!);
                                                      startRecording =
                                                          await json.decode(
                                                              start.body);
                                                    }
                                                    if (startRecording['sid'] !=
                                                        null) {
                                                      _startRecordingLiveStream();
                                                    } else {
                                                      //add code here to show the recording initiation failed

                                                    }
                                                  } else {
                                                    setState(() {
                                                      _isLoadingStream = false;
                                                      _camButtonPressed = false;
                                                    });
                                                  }
                                                } on CameraException catch (e, stackTrace) {
                                                  print(
                                                      'An exception with the camera occured: $e - $stackTrace');
                                                }
                                              }
                                              //Open phone gallery
                                              if (selectedButton == 3) {
                                                //open image gallery
                                                await _imagePicker.pickImage(
                                                    source: ImageSource.gallery,
                                                    preferredCameraDevice:
                                                        CameraDevice.front,
                                                    imageQuality: 25,
                                                    maxHeight: 400,
                                                    maxWidth: 400);
                                              }
                                            },
                                            icon: !_camButtonPressed
                                                ? Image.asset(
                                                    'assets/icons/target_rill_light.png',
                                                    color: Colors.white,
                                                  )
                                                : Image.asset(
                                                    'assets/icons/target_rill_dark.png',
                                                    color: Colors.white,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            Positioned(
                              top: size.height - 100,
                              width: size.width,
                              height: 100,
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: ListWheelScrollView.useDelegate(
                                  physics: FixedExtentScrollPhysics(),
                                  itemExtent: 80,
                                  diameterRatio: 80,
                                  onSelectedItemChanged: _onSelectedItem,
                                  childDelegate:
                                      ListWheelChildListDelegate(children: [
                                    RotatedBox(
                                        quarterTurns: 1,
                                        child: textButton('Live', () {
                                          setState(() {
                                            selectedButton = 0;
                                          });
                                        }, Colors.white)),
                                    RotatedBox(
                                      quarterTurns: 1,
                                      child: textButton('Video', () {
                                        setState(() {
                                          selectedButton = 1;

                                          _vcontroller?.initialize();
                                        });
                                      }, Colors.white),
                                    ),
                                    RotatedBox(
                                      quarterTurns: 1,
                                      child: textButton('Camera', () {
                                        setState(() {
                                          selectedButton = 2;
                                        });
                                      }, Colors.white),
                                    ),
                                    RotatedBox(
                                      quarterTurns: 1,
                                      child: textButton('Gallery', () {
                                        setState(() {
                                          selectedButton = 3;
                                        });
                                      }, Colors.white),
                                    ),
                                  ]),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Container(),
      ),
    );
  }

  _onSelectedItem(int index) {
    setState(() {
      selectedButton = index;
      print('the selected button: $selectedButton');
    });
  }

  //The following functions will start recording a live stream
  _startRecordingLiveStream() async {
    //save stream to your database in order for other users to view it
    var streamRec = await db.createNewDataStream(
        channelName: _channelName,
        rtcToken: rtcToken,
        rtmToken: rtmToken,
        userId: widget.userId,
        streamerId: uid.toString(),
        userName: 'Example',
        resourceId: acquireResponse['resourceId'],
        sid: startRecording['sid']);

    print('the stream rec: $streamRec');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (builder) => LiveStreaming(
          channelName: _channelName!,
          userRole: 'publisher',
          rtcToken: rtcToken!,
          rtmToken: rtmToken!,
          userId: widget.userId!,
          uid: uid!,
          sid: startRecording['sid'],
          resourceId: acquireResponse['resourceId'],
          mode: 'mix',
          streamModelId: streamRec,
          streamUserId: widget.userId,
          loadingStateCallback: callBackLoadingState,
        ),
      ),
    );
  }

  //Future to get token
  Future<void> _getTokens() async {
    var rtcResult = await rtctokenGenerator.createVideoAudioChannelToken(
        channelName: _channelName!, role: '1');

    rtcToken = rtcResult['token'];
    uid = rtcResult['uid'];
    var userAccount = 'testingOnly';

    var rtmResult = await rtmTokenGenerator.createMessagingToken(
        channelName: _channelName!, userAccount: userAccount, role: '1');

    rtmToken = rtmResult['token'];

    print('the rtc token: $rtcToken - $uid - rtm token: $rtmToken');
  }

  //stopping the loading state when stream ends
  void callBackLoadingState() {
    setState(() {
      print('we are turning off loading state');
      _isLoadingStream = false;
    });
  }

  //the following dialog will show up after the image has been captured
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
                content: Column(
                  children: [
                    Expanded(
                      child: Semantics(
                        child: Image.file(File(file.path)),
                      ),
                    ),
                    TextFormField(
                      initialValue: '',
                      decoration: const InputDecoration(
                          hintText: 'Say something..', filled: false),
                      onChanged: (val) {
                        description = val.trim();
                      },
                    )
                  ],
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
                            type: 'image',
                            description: description);
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
                      setState(() {
                        _camButtonPressed = false;
                      });

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
      VideoPlayerController vController =
          VideoPlayerController.file(File(file.path));
      showDialog(
          context: context,
          builder: (builder) {
            return StatefulBuilder(builder: (context, setState) {
              return Stack(alignment: Alignment.topCenter, children: [
                AlertDialog(
                  content: Semantics(
                    child: AspectRatioVideo(vController, null),
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
                        await _controller!.pausePreview();
                        //await vController.dispose();
                        // await _controller!.dispose();
                        Navigator.pop(context);
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

      _vcontroller = controller;
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
    _toBeDisposed = _vcontroller;
    // _controller!.dispose();
    //_controller = null;
  }
}
