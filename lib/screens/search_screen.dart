import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:rillliveapp/services/storage_data.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/image_viewer.dart';
import 'package:rillliveapp/shared/loading_animation.dart';
import 'package:rillliveapp/shared/video_viewer.dart';
import 'package:video_player/video_player.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  //Filter items List
  List<Map<String, dynamic>> filterItems = [
    {'category': 'Popular', 'isPressed': false},
    {'category': 'Free', 'isPressed': false},
    {'category': 'Nearby', 'isPressed': false},
    {'category': 'Fashion', 'isPressed': false}
  ];

  late bool loadingComplete = false;
  late String searchWord;
  //Futures
  late Future getAllBucketData;

  //Controller
  StorageData storageData = StorageData();
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    getAllBucketData = _getAllObjects();
  }

  @override
  Widget build(BuildContext context) {
    var _size = MediaQuery.of(context).size;
    return Container(
      height: _size.height,
      width: _size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //List view for the video filters
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
                height: 140, width: _size.width, child: _buildFilterListView()),
          ),
          //Grid view for search result
          _buildGridView(),
        ],
      ),
    );
  }

  //List view filter
  Widget _buildFilterListView() {
    return Column(
      children: [
        Container(
          height: 70,
          padding: EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: filterItems.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.all(6),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      filterItems[index]['isPressed'] = true;
                      for (var i = 0; i < filterItems.length; i++) {
                        if (i != index) {
                          filterItems[i]['isPressed'] = false;
                        }
                      }
                    });
                  },
                  child: Container(
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color:
                          filterItems[index]['isPressed'] ? color_4 : color_7,
                    ),
                    child: Center(
                      child: Text(
                        '${filterItems[index]['category']}',
                        style: filterItems[index]['isPressed']
                            ? textStyle_4
                            : errorText,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Container(
          height: 70,
          padding: EdgeInsets.symmetric(vertical: 10),
          child: TextFormField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
              ),
              hintText: 'search...',
            ),
            onChanged: (val) {
              setState(() {
                searchWord = val;
              });
            },
          ),
        ),
      ],
    );
  }

  //Build Grid View
  Widget _buildGridView() {
    var _size = MediaQuery.of(context).size;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: FutureBuilder(
          future: getAllBucketData,
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              if (snapshot.connectionState == ConnectionState.done) {
                return SizedBox(
                  height: _size.height - 200,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.5),
                    itemCount: snapshot.data.length,
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
                                        imageUrl: snapshot.data[index]
                                            ['value'])),
                              );
                            },
                            child: CachedNetworkImage(
                                imageUrl: snapshot.data[index]['value'],
                                progressIndicatorBuilder:
                                    (context, imageUrl, progress) {
                                  return const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10.0),
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
                                    videoController: snapshot.data[index]
                                        ['value']),
                              ),
                            );
                          },
                          child: Container(
                            alignment: Alignment.center,
                            child: snapshot
                                    .data[index]['value'].value.isInitialized
                                ? Chewie(controller: _chewieController)
                                : const Text('Not initialized'),
                          ),
                        );
                      }
                    },
                  ),
                );
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: _size.height - 200,
                  child: const Center(
                      child: LoadingAmination(
                    animationType: 'ThreeInOut',
                  )),
                );
              } else {
                return SizedBox(
                    height: _size.height - 200,
                    child: Center(
                        child: Text('No data was found', style: textStyle_5)));
              }
            } else {
              return SizedBox(
                height: _size.height - 200,
                child: const Center(
                    child: LoadingAmination(
                  animationType: 'ThreeInOut',
                )),
              );
            }
          }),
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
}
