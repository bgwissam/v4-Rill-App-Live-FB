import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rillliveapp/controller/live_streaming.dart';
import 'package:rillliveapp/controller/recording_controller.dart';
import 'package:rillliveapp/controller/token_controller.dart';
import 'package:rillliveapp/screens/account_screen.dart';
import 'package:rillliveapp/screens/message_screen.dart';
import 'package:rillliveapp/screens/search_screen.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/services/storage_data.dart';
import 'package:rillliveapp/shared/aspect_ration_video.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/image_viewer.dart';
import 'package:rillliveapp/shared/loading_animation.dart';
import 'package:rillliveapp/shared/loading_view.dart';
import 'package:rillliveapp/shared/parameters.dart';
import 'package:rillliveapp/shared/video_viewer.dart';
import 'package:video_player/video_player.dart';

/*
 * Main Screen will be the first screen loaded after authentication
 * It will hold the bottom navigation bar that should allow users to navigate
 * into other screens
 */

class MainScreen extends StatefulWidget {
  const MainScreen({
    Key? key,
    this.userId,
  }) : super(key: key);
  final String? userId;
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
  var _userRole;
  final _userId = '45678';
  late String token = '';
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
  late Future getStreamingVideos;
  late Future getAllBucketData;
  late Future getSubscriptionFeed;
  //Define controller
  RecordingController recordingController = RecordingController();
  TokenGenerator tokenGenerator = TokenGenerator();
  StorageData storageData = StorageData();
  Parameters params = Parameters();
  DatabaseService db = DatabaseService();

  late bool _isLoadingStream = false;
  late bool _isUploadingFile = false;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    //listenToStreamingVideos();
    getStreamingVideos = _getStreamingVideos();
    getAllBucketData = _getAllObjects();
    getSubscriptionFeed = _getSubscriptionChannels();
    _getCameraMicPermission();
  }

  @override
  void dispose() {
    super.dispose();
    _disposeVideoController();
  }

  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;
    _buildMainScreenWidget();
    return Container(
      height: _size.height,
      width: _size.width,
      decoration: const BoxDecoration(
        image: DecorationImage(
            image: AssetImage('assets/images/bg1.png'), fit: BoxFit.cover),
      ),
      child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.transparent,
          bottomNavigationBar: _bottomNavigationWidget(),
          body: Column(
            children: [
              Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: _bodyWidget[_selectedIndex]),
              _isLoadingStream
                  ? Container(
                      height: 100,
                      width: 100,
                      child: LoadingView(),
                    )
                  : SizedBox.shrink(),
            ],
          )),
    );
  }

  //Main screen widgets
  List<Widget> _buildMainScreenWidget() {
    return _bodyWidget = [
      _mainFeed(),
      SearchScreen(),
      MessagesScreen(userId: widget.userId),
      AccountScreen(userId: widget.userId),
    ];
  }

  //Main feed widget
  Widget _mainFeed() {
    return Column(
      //causing renderFlex error, need to be fixed
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      //Column will hold top level heading text for live streaming
      //and a horizontal list view for live streaming videos
      children: [
        Container(
          padding: const EdgeInsets.only(left: 20, top: 10.0, bottom: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Latest', style: textStyle_1),
              Text('Live Stream', style: textStyle_1)
            ],
          ),
        ),
        //Horizontal list view to show latest live stream
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: FutureBuilder(
            future: getStreamingVideos,
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return SizedBox(
                    height: 100,
                    width: _size.width - 30,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: snapshot.data.length,
                      itemBuilder: (context, index) {
                        var record = snapshot.data[index];

                        if (record['_deleted'] == null) {
                          return InkWell(
                            onTap: () async {
                              setState(() {
                                print(
                                    'the version: ${record['id']} - ${record['_version']} - ${record['_lastChangedAt']}}');
                              });

                              // await amplifyDS.deleteStreamingVideo(
                              //     record['id'], record['_version']);
                              // await amplifyDS
                              //     .fetchStreamingVideoUrlPerId(
                              //         record['id']);

                              // await db.updateStreamingVideo(
                              //   record['id'],
                              //   record['streamerId'],
                              //   record['token'],
                              // );
                              await db.fetchStreamingVideoUrl();
                            },
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Channel: ${record['streamName']}'),
                                    Text('User: ${record['streamerName']}'),
                                    Text('Version: ${record['_version']}'),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  );
                }
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return const Text('No data was found');
              }
              return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(border: Border.all()),
                  height: 100,
                  width: _size.width,
                  child: const Text('nothing'));
            },
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
        SizedBox(
          height: _size.height / 2,
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

  //Pull refresh
  Future<void> _pullRefresh() async {
    var result = await _getAllObjects();

    print('the result: $result');
  }

  //Bottom navigation bar
  Widget _bottomNavigationWidget() {
    return SizedBox(
      width: _size.width,
      height: 60,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(_size.width, 80),
            painter: BottomNavigatorPainter(),
          ),
          Center(
            heightFactor: 0.6,
            child: FloatingActionButton(
              onPressed: () {
                widget.userId != null
                    ? showBottomNavigationMenu()
                    : errorDialog('Guest Account',
                        'You need to login in order to use this feature');
              },
              backgroundColor: Colors.orange,
              child: const Icon(Icons.video_call),
              elevation: 0.1,
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
                    icon: const Icon(Icons.home),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                    icon: const Icon(Icons.search),
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
                    icon: const Icon(Icons.message),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (builder) =>
                      //         AccountScreen(userId: widget.userId),
                      //   ),
                      // );
                    },
                    icon: const Icon(Icons.person),
                  ),
                ],
              ))
        ],
      ),
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

                                                    token = await tokenGenerator
                                                        .createVideoAudioChannelToken(
                                                            channelName:
                                                                _channelName,
                                                            role: _userRole,
                                                            userId: _userId);

                                                    var acquireResult =
                                                        await recordingController
                                                            .getVideoRecordingRefId(
                                                                _channelName,
                                                                _userId,
                                                                token);
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
                                                                  token);
                                                      startRecordingResponse =
                                                          await json.decode(
                                                              startResult.body);

                                                      print(
                                                          'Start response: ${startResult.body}');
                                                    }

                                                    //check if recording could be started
                                                    if (startRecordingResponse[
                                                            'sid'] !=
                                                        null) {
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => LiveStreaming(
                                                              token: token,
                                                              channelName:
                                                                  _channelName,
                                                              userRole:
                                                                  _userRole,
                                                              resourceId:
                                                                  acquireResponse[
                                                                      'resourceId'],
                                                              sid:
                                                                  startRecordingResponse[
                                                                      'sid'],
                                                              mode: 'mix',
                                                              userId: _userId,
                                                              loadingStateCallback:
                                                                  callBackLoadingState),
                                                        ),
                                                      );
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

                              // DecoratedBox(
                              //   decoration: buttonStyle5,
                              //   child: ElevatedButton(
                              //       onPressed: () async {
                              //         if (_formKey.currentState!.validate()) {
                              //           if (_channelName != null) {
                              //             _userRole = 'subscriber';
                              //             //await _getToken();
                              //             await Navigator.push(
                              //               context,
                              //               MaterialPageRoute(
                              //                 builder: (context) => LiveStreaming(
                              //                   token: token,
                              //                   channelName: _channelName,
                              //                   userRole: _userRole,
                              //                   userId: _userId,
                              //                 ),
                              //               ),
                              //             );
                              //           }
                              //         }
                              //       },
                              //       style: ElevatedButton.styleFrom(
                              //         primary: Colors.transparent,
                              //         shape: RoundedRectangleBorder(
                              //           borderRadius: BorderRadius.circular(10),
                              //         ),
                              //       ),
                              //       child: const Text('Join')),
                              // ),
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
                onPressed: () {
                  _getCameraMicPermission();
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
                      var result = await storageData.uploadFile(file, 'images');
                      if (result.isNotEmpty) {
                        await db.uploadImage(
                            imageName: 'example',
                            imageUrl: result,
                            tags: ['cat', 'cute']);
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
            return AlertDialog(
              content: Semantics(
                child: AspectRatioVideo(_controller),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await storageData.uploadFile(file, 'videos');
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
            );
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
    return FutureBuilder(
      future: getAllBucketData,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.hasData && snapshot.data.isNotEmpty) {
          if (snapshot.connectionState == ConnectionState.done) {
            late String extension;
            _isLoadingStream = false;
            late ChewieController _chewieController;
            return RefreshIndicator(
              onRefresh: _pullRefresh,
              child: GridView.builder(
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
              ),
            );
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: LoadingAmination(
                animationType: 'ThreeInOut',
              ),
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
      },
    );
  }

  //Subscribed feed section
  Widget _subscribedFeed() {
    return FutureBuilder(
        future: getSubscriptionFeed,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData && snapshot.data.isNotEmpty) {
            if (snapshot.connectionState == ConnectionState.done) {
              return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
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
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (builder) => VideoPlayerPage(
                                  videoController: snapshot.data[index]
                                      ['value']),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          alignment: Alignment.center,
                          child:
                              snapshot.data[index]['value'].value.isInitialized
                                  ? Chewie(controller: _chewieController)
                                  : const Text('Not initialized'),
                        ),
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

  //Listen to streaming videos
  // Future<String> listenToStreamingVideos() async {
  //   var streamResponse = await db.subscribeToStreamingModel();
  //   print('The stream response: $streamResponse');
  //   return streamResponse;
  // }

  //Get streaming videos
  Future<List<dynamic>> _getStreamingVideos() async {
    List<String> videos = [];

    var response = await db.fetchStreamingVideoUrl();
    Map result = json.decode(response);
    var liveStreamVideos = result['listStreamingModels'];

    return liveStreamVideos['items'];
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
    //     print('the keys: $key');
    //     var file = await storageData.getFileUrl(key);

    //     extension = p.extension(key, 2);

    //     if (extension == '.mp4' || extension == '.3gp' || extension == '.mkv') {
    //       _videoPlayerController = VideoPlayerController.network(file!);
    //       await _videoPlayerController.initialize();
    //       listUrls.add({'value': _videoPlayerController, 'type': 'video'});
    //     } else {
    //       listUrls.add({'value': file, 'type': 'image'});
    //       print('list url: $listUrls');
    //     }
    //   }

    //   return listUrls;
    // }
    // print('the List of objects: $listObjects');
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

  //if camera and mic permission aren't granted than we will get them here
  _getCameraMicPermission() async {
    await [Permission.camera, Permission.microphone].request();
    if (await Permission.camera.status == PermissionStatus.granted) {
      cameraPermission = true;
    }

    if (await Permission.microphone.status == PermissionStatus.granted) {
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
