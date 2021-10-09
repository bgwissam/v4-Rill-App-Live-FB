import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:rillliveapp/authentication/signin.dart';
import 'package:rillliveapp/messaging/conversation_screen.dart';
import 'package:rillliveapp/models/user_model.dart';
import 'package:rillliveapp/services/database.dart';
import 'package:rillliveapp/shared/color_styles.dart';
import 'package:rillliveapp/shared/parameters.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key, this.userId, this.userModel})
      : super(key: key);
  final String? userId;
  final UserModel? userModel;
  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late String _searchWord;
  late List<Map<String, dynamic>> messageList = [];
  //Controllers
  DatabaseService db = DatabaseService();
  //Streams
  late Stream<QuerySnapshot> messageStream;
  @override
  Widget build(BuildContext context) {
    var _size = MediaQuery.of(context).size;
    return widget.userId != null
        ? Container(
            height: _size.height - 100,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Build Search box
                    _searchBox(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 15),
                      child: Text('Messages',
                          style: Theme.of(context).textTheme.headline6),
                    ),
                    //Build messages List
                    _messageList(_size),
                  ]),
            ),
          )
        : SizedBox(
            height: _size.height - 100,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(primary: color_4),
                onPressed: () async {
                  Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (builder) {
                    return SignInSignUp();
                  }), (route) => false);
                },
                child: Text('Sign In', style: button_1),
              ),
            ),
          );
  }

  @override
  void initState() {
    super.initState();
    _getMessageStream();
  }

  //Search Box
  Widget _searchBox() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: color_7)),
      child: TextFormField(
        initialValue: '',
        decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search your message',
            focusColor: color_10),
        onChanged: (val) {
          setState(() {
            _searchWord = val;
          });
        },
      ),
    );
  }

  _getMessageStream() {
    messageStream = db.getChatRoomPerUser(userId: widget.userId);
  }

  //build messages list
  Widget _messageList(Size size) {
    return StreamBuilder<QuerySnapshot>(
      stream: messageStream,
      builder: (context, AsyncSnapshot snapshot) {
        return SizedBox(
          height: size.height - 260,
          child: snapshot.hasData
              ? ListView.builder(
                  itemCount: snapshot.data?.docs.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (builder) => ConversationScreen(
                                currentUser: widget.userModel,
                                chatRoomId: snapshot.data?.docs[index].id),
                          ),
                        );
                      },
                      child: ListTile(
                        leading: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(),
                          ),
                          height: 50,
                          width: 50,
                          child: FittedBox(
                            fit: BoxFit.fill,
                            child: Image.network(
                              snapshot.data?.docs[index][UserParams.AVATAR],
                            ),
                          ),
                        ),
                        title: Text(
                            '${snapshot.data?.docs[index][UserParams.FIRST_NAME]} ${snapshot.data?.docs[index][UserParams.LAST_NAME]}'),
                      ),
                    );
                  })
              : Center(
                  child: Text(
                    'No Messages were found',
                    style: textStyle_13,
                  ),
                ),
        );
      },
    );
  }
}
