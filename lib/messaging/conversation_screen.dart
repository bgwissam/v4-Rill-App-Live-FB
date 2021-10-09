import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rillliveapp/models/message_model.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/loading_animation.dart';
import 'package:rillliveapp/shared/parameters.dart';

class ConversationScreen extends StatefulWidget {
  final String? chatRoomId;
  final UserModel? currentUser;
  const ConversationScreen({Key? key, this.chatRoomId, this.currentUser})
      : super(key: key);

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _inputMessageController = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController listScrollController = ScrollController();
  DatabaseService db = DatabaseService();
  MessageMap messageMap = MessageMap();
  late Stream<QuerySnapshot> chatStream;
  var _size;
  late double _listSize;
  //int variables
  int _limit = 20;
  int _limitIncrement = 20;

  //bool variable
  bool _isShowSticker = false;
  bool _isLoading = false;
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
    _focus.addListener(_onFocusChanged);
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
  @override
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
        .orderBy(ConversationRoomParam.time, descending: false)
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

  _sendMessage() async {
    if (_inputMessageController.text.isNotEmpty) {
      messageMap.message = _inputMessageController.text;
      messageMap.senderId = widget.currentUser?.userId;
      messageMap.time = DateTime.now().millisecondsSinceEpoch;
      db.addConversationMessage(
          chatRoomId: widget.chatRoomId, messageMap: messageMap);

      _inputMessageController.clear();
    }
  }

  //Build the conversation screen body
  Widget _buildScreenBody() {
    return Stack(
      children: [
        Column(
          children: [
            chatMessageList(),
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
      return MessageTile(
        message: document[ConversationRoomParam.message],
        currentUser: widget.currentUser?.userId,
        sentBy: document[ConversationRoomParam.senderId],
      );
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
                  icon: Icon(Icons.image), onPressed: () {}, color: color_7),
            ),
            color: Colors.white,
          ),
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1),
              child: IconButton(
                  icon: Icon(Icons.face), onPressed: () {}, color: color_7),
            ),
            color: Colors.white,
          ),
          Flexible(
            child: Container(
              child: TextField(
                onSubmitted: (val) async {
                  await _sendMessage();
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
                margin: EdgeInsets.symmetric(horizontal: 8),
                child: IconButton(
                  icon: IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        _sendMessage();
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

  //build loading screen
  _buildLoading() {
    return Positioned(
      child: _isLoading
          ? const LoadingAmination(
              animationType: 'ThreeInOut',
            )
          : const SizedBox.shrink(),
    );
  }
}

class MessageTile extends StatelessWidget {
  const MessageTile({Key? key, this.message, this.sentBy, this.currentUser})
      : super(key: key);
  final String? sentBy;
  final String? currentUser;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(vertical: 5),
      alignment:
          sentBy == currentUser ? Alignment.centerRight : Alignment.centerLeft,
      padding: EdgeInsets.only(
          left: sentBy == currentUser ? 0 : 15,
          right: sentBy == currentUser ? 15 : 0),
      child: Container(
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
          child: Text(message.toString())),
    );
  }
}
