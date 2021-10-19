import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rillliveapp/models/message_model.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/services/storage_data.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/full_page_file.dart';
import 'package:rillliveapp/shared/loading_animation.dart';
import 'package:rillliveapp/shared/message_service.dart';
import 'package:rillliveapp/shared/parameters.dart';
import 'package:rillliveapp/shared/video_viewer.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';

class ConversationScreen extends StatefulWidget {
  final String? chatRoomId;
  final UserModel? currentUser;
  final String? otherUser;
  const ConversationScreen(
      {Key? key, this.chatRoomId, this.currentUser, this.otherUser})
      : super(key: key);

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _inputMessageController = TextEditingController();
  final FocusNode _focus = FocusNode();
  ScrollController listScrollController = ScrollController();
  MessaginService ms = MessaginService();
  DatabaseService db = DatabaseService();
  StorageData sd = StorageData();
  MessageMap messageMap = MessageMap();
  late Stream<QuerySnapshot> chatStream;
  var _size;
  late double _listSize;
  late File imagePicked;
  //int variables
  int _limit = 20;
  int _limitIncrement = 20;

  //bool variable
  bool _isShowSticker = false;
  bool _isLoading = false;
  //Models
  UserModel? otherUser;
  @override
  Widget build(BuildContext context) {
    _size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Screen'),
        backgroundColor: color_4,
      ),
      resizeToAvoidBottomInset: true,
      body: WillPopScope(
        onWillPop: onBackPress,
        child: Container(child: _buildScreenBody()),
      ),
    );
  }

  Future<bool> onBackPress() {
    if (_isShowSticker) {
      setState(() {
        _isShowSticker = false;
      });
    } else {
      Navigator.pop(context);
    }

    return Future.value(false);
  }

  @override
  void initState() {
    super.initState();
    _getMessageStream();
    _getOtherUser();
    _focus.addListener(_onFocusChanged);
    listScrollController.addListener(_scrollListener);
  }

  //Future to get user details we are chatting with
  Future _getOtherUser() async {
    print('other user id: ${widget.otherUser} - ${widget.currentUser?.userId}');
    otherUser = await db.getUserByUserId(userId: widget.otherUser);
  }

  _scrollListener() {
    if (listScrollController.offset >=
            listScrollController.position.maxScrollExtent &&
        !listScrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  //Check for text field focus changes
  void _onFocusChanged() {
    if (_focus.hasFocus) {
      setState(() {
        _isShowSticker = false;
      });
    }
  }

  //get sticker keyboard
  void getSticker() {
    //hide keyboard if sticker is selected
    _focus.unfocus();
    setState(() {
      _isShowSticker = !_isShowSticker;
    });
  }

  @override
  void dispose() {
    super.dispose();
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
  }

  //will stream the messages list
  _getMessageStream() {
    chatStream = db.messagesCollection
        .doc(widget.chatRoomId)
        .collection('chats')
        .orderBy(ConversationRoomParam.time, descending: true)
        .snapshots();
  }

  chatMessageList() {
    return Flexible(
      child: widget.chatRoomId!.isNotEmpty
          ? StreamBuilder<QuerySnapshot>(
              stream: chatStream,
              builder: (context, AsyncSnapshot snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Something went wrong!'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    width: _size.width,
                    child: const Center(
                      child: LoadingAmination(
                        animationType: 'ThreeInOut',
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: snapshot.data?.docs.length,
                  reverse: true,
                  itemBuilder: (context, index) =>
                      _buildItem(index, snapshot.data?.docs[index]),
                  controller: listScrollController,
                );
              })
          : const Center(
              child: LoadingAmination(
                animationType: 'ThreeInOut',
              ),
            ),
    );
  }

  _sendMessage({String? messageString, String? messageType}) async {
    if (messageString!.trim().isNotEmpty) {
      messageMap.message = messageString;
      messageMap.type = messageType;
      messageMap.senderId = widget.currentUser?.userId;
      messageMap.time = DateTime.now().millisecondsSinceEpoch;
      print('chat room id: ${widget.chatRoomId}');
      db.addConversationMessage(
          chatRoomId: widget.chatRoomId, messageMap: messageMap);

      _inputMessageController.clear();
      //Move the message position
      listScrollController.animateTo(0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      //Notify the other user of the message being sent
      ms.token = otherUser?.fcmToken;
      ms.senderId = widget.currentUser?.userId;
      ms.senderName =
          '${widget.currentUser?.firstName} ${widget.currentUser?.lastName}';
      ms.receiverId = otherUser?.userId;
      ms.messageType = 'message';
      ms.messageTitle = 'New Message';
      ms.messageBody = messageString;
      ms.sendPushMessage();
    }
  }

  //Build the conversation screen body
  Widget _buildScreenBody() {
    return Stack(
      children: [
        Column(
          children: [
            chatMessageList(),
            //builder sticker
            _isShowSticker ? buildSticker() : SizedBox.shrink(),
            //Build a container for text input
            _buildInput(),
          ],
        ),
        _buildLoading(),
      ],
    );
  }

  _buildItem(int index, DocumentSnapshot? document) {
    if (document != null) {
      print('doc ${document.id}');
      return MessageTile(
        docId: document.id,
        message: document[ConversationRoomParam.message],
        currentUser: widget.currentUser?.userId,
        type: document[ConversationRoomParam.type],
        sentBy: document[ConversationRoomParam.senderId],
        read: document[ChatRoomParameters.read] ?? false,
        chatRoomId: widget.chatRoomId,
      );
    }
  }

  //show upload options
  _showUploadOptions() {
    showDialog(
        context: context,
        builder: (builder) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            content: SizedBox(
              height: _size.height / 6,
              width: _size.width / 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await getVideo();
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 60),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color_4),
                      ),
                      child: Text(
                        'Video',
                        style: textStyle_1,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await getImage();
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 60),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color_4),
                      ),
                      child: Text(
                        'Image',
                        style: textStyle_1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile;

    pickedFile = await imagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 25);
    if (pickedFile != null) {
      imagePicked = File(pickedFile.path);

      setState(() {
        _isLoading = true;
      });

      uploadFile(imageFile: pickedFile);
      Navigator.pop(context);
    }
  }

  Future getVideo() async {
    ImagePicker videPicker = ImagePicker();
    XFile? pickedFile;
    MediaInfo? mInfo;
    pickedFile = await videPicker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      imagePicked = File(pickedFile.path);
      await VideoCompress.setLogLevel(0);
      mInfo = await VideoCompress.compressVideo(File(pickedFile.path).path,
          quality: VideoQuality.LowQuality,
          deleteOrigin: true,
          includeAudio: true);
    }

    setState(() {
      _isLoading = true;
    });
    uploadFile(mfile: mInfo);
    Navigator.pop(context);
  }

  Future uploadFile({XFile? imageFile, MediaInfo? mfile}) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();

    if (imageFile != null) {
      var result =
          await sd.uploadFile(xfile: imageFile, folderName: 'chatImage');

      if (result['imageUrl'] != null) {
        _sendMessage(messageType: 'image', messageString: result['imageUrl']);

        setState(() {
          _isLoading = false;
        });
      }
    }
    if (mfile != null) {
      String fileUrl = '';
      String thumbnailUrl = '';
      var result = await sd.uploadFile(mfile: mfile, folderName: 'chatVideo');

      if (result['videoUrl'] != null) {
        _sendMessage(messageType: 'video', messageString: result['videoUrl']);

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  //build message input row
  _buildInput() {
    return Container(
      child: Row(
        children: [
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                  icon: Icon(Icons.image),
                  onPressed: () async {
                    //build image picker
                    _showUploadOptions();
                  },
                  color: color_7),
            ),
            color: Colors.white,
          ),
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                  icon: Icon(Icons.face),
                  onPressed: () {
                    getSticker();
                  },
                  color: color_7),
            ),
            color: Colors.white,
          ),
          Flexible(
            child: Container(
              child: TextField(
                onSubmitted: (val) async {
                  await _sendMessage(
                      messageString: _inputMessageController.text,
                      messageType: 'text');
                },
                focusNode: _focus,
                controller: _inputMessageController,
                style: textStyle_15,
                decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Say something...',
                    hintStyle: textStyle_12),
              ),
            ),
          ),
          //Send button
          Material(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 2),
                child: IconButton(
                  icon: IconButton(
                      icon: const ImageIcon(
                        AssetImage("assets/icons/send_rill.png"),
                      ),
                      onPressed: () {
                        _sendMessage(
                            messageString: _inputMessageController.text,
                            messageType: 'text');
                      },
                      color: color_7),
                  onPressed: () {},
                ),
              ),
              color: Colors.white)
        ],
      ),
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: color_10, width: 0.5)),
          color: Colors.white),
    );
  }

  Widget buildSticker() {
    return Expanded(
      child: Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                TextButton(
                  onPressed: () => _sendMessage(
                      messageString: 'mime1', messageType: 'sticker'),
                  child: Image.asset(
                    'assets/stickers/mime1.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                TextButton(
                  onPressed: () => _sendMessage(
                      messageString: 'mime2', messageType: 'sticker'),
                  child: Image.asset(
                    'assets/stickers/mime2.gif',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ),
          ],
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        ),
        decoration: BoxDecoration(
            border: Border(top: BorderSide(color: color_10, width: 0.5)),
            color: Colors.white),
        padding: EdgeInsets.all(5),
        height: 180,
      ),
    );
  }

  //build loading screen
  _buildLoading() {
    return Center(
      child: _isLoading
          ? const LoadingAmination(
              animationType: 'ThreeInOut',
            )
          : const SizedBox.shrink(),
    );
  }
}

class MessageTile extends StatelessWidget {
  const MessageTile(
      {Key? key,
      this.message,
      this.sentBy,
      this.currentUser,
      this.type,
      this.read,
      this.docId,
      this.chatRoomId})
      : super(key: key);
  final String? docId;
  final String? chatRoomId;
  final String? sentBy;
  final String? currentUser;
  final String? message;
  final String? type;
  final bool? read;

  @override
  Widget build(BuildContext context) {
    //mark messages as read
    _markAsRead();
    return Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.symmetric(vertical: 5),
        alignment: sentBy == currentUser
            ? Alignment.centerRight
            : Alignment.centerLeft,
        padding: EdgeInsets.only(
            left: sentBy == currentUser ? 0 : 15,
            right: sentBy == currentUser ? 15 : 0),
        child: _buildRow(context, message, type));
  }

  _buildRow(BuildContext context, var message, String? type) {
    switch (type) {
      case 'text':
        return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: sentBy == currentUser ? color_8 : color_10,
                borderRadius: sentBy == currentUser
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                        bottomLeft: Radius.circular(25))
                    : const BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                        bottomRight: Radius.circular(25))),
            child: Text(
              message.toString(),
            ));
      case 'image':
        return Material(
          child: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (builder) =>
                      FullPageFile(isImage: true, file: message),
                ),
              );
            },
            child: Image.network(
              message.toString(),
              loadingBuilder: (BuildContext context, Widget child,
                  ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  decoration: BoxDecoration(
                    color: color_10,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(8),
                    ),
                  ),
                  width: 200,
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: color_7,
                      value: loadingProgress.expectedTotalBytes != null &&
                              loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, object, stackTrace) {
                return Material(
                  child: Image.asset(
                    'images/img_not_available.jpeg',
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(8),
                  ),
                  clipBehavior: Clip.hardEdge,
                );
              },
              width: 200,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(10),
          ),
          clipBehavior: Clip.hardEdge,
        );
      case 'video':
        VideoPlayerController _videoController =
            VideoPlayerController.network(message);
        return Material(
          borderRadius: const BorderRadius.all(
            Radius.circular(8),
          ),
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: 200,
            height: 200,
            child: FutureBuilder(
                future: _initizalizeVideoPlayer(_videoController),
                builder: (context, AsyncSnapshot snapshot) {
                  print('the video snapshot: ${snapshot.data}');
                  if (snapshot.hasData) {
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (builder) =>
                                FullPageFile(isImage: false, file: message),
                          ),
                        );
                      },
                      child: AspectRatio(
                        aspectRatio: _videoController.value.aspectRatio,
                        child: VideoPlayer(
                          snapshot.data,
                        ),
                      ),
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                }),
          ),
        );
      case 'sticker':
        return Material(
          borderRadius: const BorderRadius.all(
            Radius.circular(8),
          ),
          clipBehavior: Clip.hardEdge,
          child: Image.asset(
            'assets/stickers/$message.gif',
            width: 200,
            height: 200,
          ),
        );

      default:
        return const Text('Error: check admin');
    }
  }

  //Initialize video player
  Future _initizalizeVideoPlayer(VideoPlayerController _controller) async {
    await _controller.initialize();
    return _controller;
  }

  //Mark as read
  _markAsRead() async {
    DatabaseService db = DatabaseService();
    if (currentUser != sentBy) {
      if (read! == false) {
        await db.updateConversationRead(
            docId: docId, chatRoomId: chatRoomId, read: true);
      }
    }
  }
}
