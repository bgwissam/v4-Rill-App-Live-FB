import 'package:flutter/material.dart';
import 'package:rillliveapp/models/message_model.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';

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
  late MessageMap messageMap;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Screen'),
      ),
      body: _buildScreenBody(),
    );
  }

  Widget chatMessageList() {
    return Container();
  }

  _sendMessage() async {
    if (_inputMessageController.text.isNotEmpty) {
      messageMap.message = _inputMessageController.text;
      messageMap.senderId = widget.currentUser?.userId;

      db.getConversationMessage(
          chatRoomId: widget.chatRoomId, messageMap: messageMap);
    }
  }

  //Build the conversation screen body
  Widget _buildScreenBody() {
    return Container(
      child: Stack(
        children: [
          //Build a container for text input
          Container(
            padding: EdgeInsets.all(8),
            color: color_11,
            alignment: Alignment.bottomCenter,
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                  controller: _inputMessageController,
                  style: button_1,
                  decoration: InputDecoration(
                      hintText: 'Say something...', hintStyle: textStyle_11),
                )),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                        gradient: color_1,
                        borderRadius: BorderRadius.circular(25)),
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.send),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
