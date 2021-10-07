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

  DatabaseService db = DatabaseService();
  MessageMap messageMap = MessageMap();
  late Stream<QuerySnapshot> chatStream;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Screen'),
        backgroundColor: color_4,
      ),
      body: _buildScreenBody(),
    );
  }

  @override
  void initState() {
    super.initState();

    _getMessageStream();
  }

  //will stream the messages list
  _getMessageStream() {
    chatStream = db.messagesCollection
        .doc(widget.chatRoomId)
        .collection('chats')
        .snapshots();
  }

  chatMessageList() {
    return Container(
      height: MediaQuery.of(context).size.height - 150,
      child: StreamBuilder<QuerySnapshot>(
          stream: chatStream,
          builder: (context, AsyncSnapshot snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Something went wrong!'),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: LoadingAmination(
                  animationType: 'ThreeInOut',
                ),
              );
            }

            return ListView(
              children: snapshot.data!.docs.map<Widget>((DocumentSnapshot doc) {
                Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;
                return ListTile(
                  title: Text(data[ConversationRoomParam.senderId]),
                  subtitle: Text(data[ConversationRoomParam.message]),
                );
              }).toList(),
            );
          }),
    );
  }

  _sendMessage() async {
    if (_inputMessageController.text.isNotEmpty) {
      messageMap.message = _inputMessageController.text;
      messageMap.senderId = widget.currentUser?.userId;

      db.addConversationMessage(
          chatRoomId: widget.chatRoomId, messageMap: messageMap);

      _inputMessageController.clear();
    }
  }

  //Build the conversation screen body
  Widget _buildScreenBody() {
    return Stack(
      children: [
        //Build a container for text input
        Container(
          decoration: BoxDecoration(
            color: color_6,
          ),
          padding: EdgeInsets.all(8),
          alignment: Alignment.bottomCenter,
          child: Row(
            children: [
              Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _inputMessageController,
                    style: textStyle_15,
                    decoration: InputDecoration(
                        hintText: 'Say something...', hintStyle: textStyle_12),
                  )),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () async {
                    print('tapping');
                    await _sendMessage();
                  },
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                        gradient: color_1,
                        borderRadius: BorderRadius.circular(25)),
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.send),
                  ),
                ),
              ),
            ],
          ),
        ),

        chatMessageList(),
      ],
    );
  }
}

class MessageTile extends StatelessWidget {
  const MessageTile({Key? key, this.message}) : super(key: key);

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
