import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  VideoPlayerController? _vcontroller;
  VideoPlayerController? _toBeDisposed;
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

  //Controllers
  StorageData storageData = StorageData();
  DatabaseService db = DatabaseService();
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
    onNewCameraSelected(cameras[0]);
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
        backgroundColor: Colors.black,
        body: _isCameraInitialized
            ? Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: AspectRatio(
                        aspectRatio: 1.02 / _controller!.value.aspectRatio,
                        child: Stack(
                          children: [
                            _controller!.buildPreview(),
                            if (selectedButton == 0)
                              GestureDetector(
                                onTap: () async {
                                  // var result =
                                  //     await storageData.uploadImageFile(
                                  //         fileType: 'imageCamera');
                                  var result = await _controller?.takePicture();
                                  setState(() {
                                    _previewImage(result);
                                  });
                                },
                                child: const Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.grey,
                                      child: CircleAvatar(
                                        radius: 25,
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (selectedButton == 1)
                              GestureDetector(
                                onTap: () async {
                                  if (mounted) {
                                    setState(() {});
                                  }

                                  if (_controller == null ||
                                      !_controller!.value.isInitialized) {
                                    print('error select camera first');
                                  }

                                  if (_controller!.value.isRecordingVideo) {
                                    setState(() {
                                      _isRecordingVideo = true;
                                    });
                                  }
                                  try {
                                    if (!_isRecordingVideo) {
                                      await _controller!.startVideoRecording();
                                      setState(() {
                                        _isRecordingVideo = true;
                                        print(
                                            'is recordinging $_isRecordingVideo');
                                      });
                                    } else {
                                      var result = await _controller!
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
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.grey,
                                      child: !_isRecordingVideo
                                          ? const CircleAvatar(
                                              radius: 25,
                                              backgroundColor: Colors.red,
                                            )
                                          : const CircleAvatar(
                                              radius: 15,
                                              backgroundColor: Colors.redAccent,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            if (selectedButton == 2)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 20),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.grey,
                                    child: CircleAvatar(
                                      radius: 25,
                                      backgroundColor: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            if (selectedButton == 2)
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Align(
                                  alignment: Alignment.bottomLeft,
                                  child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _ismicOn = !_ismicOn;
                                      });
                                    },
                                    icon: _ismicOn
                                        ? Icon(Icons.mic_none_rounded)
                                        : Icon(Icons.mic_off_rounded),
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isCameraInitialized = false;
                                    });
                                    onNewCameraSelected(
                                        cameras[_isRearCameraSelected ? 1 : 0]);
                                    setState(() {
                                      _isRearCameraSelected =
                                          !_isRearCameraSelected;
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.cameraswitch_outlined,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        textButton(
                          'Camera',
                          () {
                            setState(() {
                              selectedButton = 0;
                            });
                          },
                          selectedButton == 0 ? Colors.yellow : Colors.white,
                        ),
                        textButton(
                          'Video',
                          () {
                            setState(() {
                              selectedButton = 1;
                              _vcontroller?.initialize();
                            });
                          },
                          selectedButton == 1 ? Colors.yellow : Colors.white,
                        ),
                        textButton(
                          'Live',
                          () {
                            setState(() {
                              selectedButton = 2;
                            });
                          },
                          selectedButton == 2 ? Colors.yellow : Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : Container(),
      ),
    );
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
                        // await vController.dispose();
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
